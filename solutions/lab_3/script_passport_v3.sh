#!/usr/bin/env bash

set -euo pipefail
trap cleanup EXIT



cleanup() {
    find -name "*.tmp" -delete
}

die() {
    local error="$1"

    echo "$error" >&2
    exit 1
}

check_privileges() {
    if [[ $(id -u) == 0 ]]; then
        return 0
    fi

    if sudo -l &> /dev/null; then
        return 0
    fi

    die "${0}: root or sudo required: permission denied"
}

log_run() {
    local start_time="$1"
    local version="v3"

    echo "${start_time}: script_passport_${version}.sh started" >> PASSPORT/log/report.log
}

usage() {
    local script="$0"

    cat <<EOF
Usage: $script [OPTIONS] [FILE]

Description:
  This script creates system report

Options:
  -h, --help      show this page
EOF
}

run_privileged() {
    local command="$@"

    # root user
    if [[ $(id -u) == 0 ]]; then
        $command

    elif sudo -l &> /dev/null; then
        sudo $command
    
    else
        die "unable to run '${command}' in privileged mode"

    fi
}

check_tool() {
    local tool_name="$1"

    if [[ "$(run_privileged "which $tool_name")" == "" ]]; then
        die "${0}: ${tool_name}: dependency not installed, run 'apt install ${tool_name}' to install it"
    fi
}

write_tmp() {
    local name=$2
    local data=$4

    echo "$data" >> "${TMP_PATH}/${name}.tmp"
}

write_section() {
    local name="$2"
    local data="$(cat "${TMP_PATH}/${4}.tmp")"

    echo "${name}: ${data}" >> $REPORT_PATH
}

write_list() {
    local name="$2"
    local data="$4"

    echo "${name}:" >> $REPORT_PATH

    while IFS= read -r line; do
        echo "  - $line" >> $REPORT_PATH
    done < "$TMP_PATH/${data}.tmp"
}

write_header() {
    local header="$1"

    echo >> $REPORT_PATH
    echo "$header" >> $REPORT_PATH
    echo >> $REPORT_PATH
}

write_without_header() {
    local data="$(cat "${TMP_PATH}/${2}.tmp")"

    echo $data >> $REPORT_PATH
}


# 1. Checking if user needs help
if [[ "${1:-default}" == "-h" ]]; then
    usage
    exit 0
fi


# 2. Checking privileges
check_privileges


# 3. Preparing environment

# creating required directories
mkdir -p PASSPORT/log
mkdir -p PASSPORT/tmp

# defining constants
readonly CURRENT_TIME="$(date)"
readonly DEPENDENCIES='lslogins dmidecode lscpu lspci nproc'
readonly TMP_PATH='PASSPORT/tmp'
readonly REPORT_PATH="PASSPORT/${1:-inventory.txt}"

# checking DEPENDENCIES
for dependency in $DEPENDENCIES; do
    check_tool $dependency
done

# remove old report
rm -f $REPORT_PATH


# 4. Collecting system information
write_tmp --name date --data "$CURRENT_TIME"
write_tmp --name hostname --data "$(hostname)"
write_tmp --name user --data "$(whoami)"
write_tmp --name wd --data "$(pwd)"
write_tmp --name files --data "$(ls -a)"

write_tmp --name kernel-name --data "$(uname --kernel-name)"
write_tmp --name kernel-version --data "$(uname --kernel-version)"
write_tmp --name cpu-bitness --data "$(uname --machine)"
write_tmp --name os-version --data "$(. /etc/os-release && echo $PRETTY_NAME)"
write_tmp --name cpu-model --data "$(grep -m 1 "model name" /proc/cpuinfo | sed 's/.*: //')"
write_tmp --name cpu-mhz --data "$(lscpu | grep -m 1 "CPU max MHz" | sed 's/^[^0-9]*//')"
write_tmp --name cpu-cores --data "$(nproc)"
write_tmp --name memory --data "$(grep "MemTotal" /proc/meminfo | sed 's/MemTotal:[ \t]*//')"
write_tmp --name pci --data "$(lspci)"
write_tmp --name motherboard --data "$(run_privileged dmidecode -s baseboard-product-name)"
write_tmp --name bios-version --data "$(run_privileged dmidecode -s bios-version)"
write_tmp --name bios-release-date --data "$(run_privileged dmidecode -s bios-release-date)"

write_tmp --name sshd-permitrootlogin --data "$(run_privileged sshd -T | grep permitrootlogin | cut -d ' ' -f 2)"
write_tmp --name sshd-port --data "$(run_privileged sshd -T | grep -w port | cut -d ' ' -f 2)"
write_tmp --name sshd-logingracetime --data "$(run_privileged sshd -T | grep logingracetime | cut -d ' ' -f 2)"
write_tmp --name sshd-maxauthtries --data "$(run_privileged sshd -T | grep maxauthtries | cut -d ' ' -f 2)"
write_tmp --name sshd-passwordauth --data "$(run_privileged sshd -T | grep passwordauthentication | cut -d ' ' -f 2)"
write_tmp --name sshd-pubkeyauth --data "$(run_privileged sshd -T | grep pubkeyauthentication | cut -d ' ' -f 2)"
write_tmp --name top-5-processes --data "$(ps -eo pid,ppid,user,%mem,cmd --sort=-%mem | head -n 6)"
write_tmp --name suid-files --data "$(run_privileged find /usr/bin -type f -perm -4000)"
write_tmp --name suid-files --data "$(run_privileged find /usr/sbin -type f -perm -4000)"


# getting users information
usernames="$(getent passwd | cut -d ':' -f 1)"

# searching non system users
for username in $usernames; do
    uid="$(id -u "$username")"

    if (( uid < 1000 && uid != 0 )); then
        continue
    fi

    if (( uid == 65534 )); then
        continue
    fi

    groups="$(id -nG "$uid")"
    lastlog="$(lslogins -u "$uid" -o LAST-LOGIN --noheadings | head -n 1 | sed -E 's/^[^:]+:[[:space:]]+//')"
    lastchg="$(run_privileged passwd -S $username | cut -d " " -f 3)"

    write_tmp --name users --data "Name ${username:-''}; \
UID ${uid}; \
Groups ${groups:-''}; \
last log-in ${lastlog-''}; \
last password change ${lastchg-''}"

done

# searching users with no password
for username in $usernames; do
    uid="$(id -u "$username")"
    password_hash="$(run_privileged grep -E ^$username: /etc/shadow | cut -d : -f 2)"

    if [[ "$password_hash" == "" ]]; then
        write_tmp --name nopass-users --data "Username: $username; UID $uid"    
    fi
done
write_tmp --name nopass-users --data ""

# non root users with UID 0
for username in $usernames; do
    uid="$(id -u "$username")"

    if [[ "$uid" == "0" && "$username" != "root" ]]; then
        write_tmp --name pseudo-root-users --data "Username: $username; UID $uid"
    fi
done
write_tmp --name pseudo-root-users --data ""


# 5. Building report
write_header "======== System Information ========"

write_section --header "current time" --data date
write_section --header "host name" --data hostname
write_section --header "user" --data user
write_section --header "working directory" --data wd

write_list --header "working directory containment" --data files

write_section --header "Kernel" --data kernel-name
write_section --header "Kernel version" --data kernel-version
write_section --header "Cpu bitness" --data cpu-bitness
write_section --header "OS version" --data os-version
write_section --header "CPU" --data cpu-model
write_section --header "CPU max MHz" --data cpu-mhz
write_section --header "CPU cores" --data cpu-cores
write_section --header "Motherboard model" --data motherboard
write_section --header "BIOS version" --data bios-version
write_section --header "BIOS release date" --data bios-release-date

write_list --header "Devices connected to pci" --data pci

write_header "============== Users ==============="

write_list --header "Non system users" --data users

write_header "======== sshd configuration ========"

write_section --header "PermitRootLogin" --data sshd-permitrootlogin
write_section --header "Port" --data sshd-port
write_section --header "LoginGraceTime" --data sshd-logingracetime
write_section --header "MaxAuthTries" --data sshd-maxauthtries
write_section --header "PasswordAuthentication" --data sshd-passwordauth
write_section --header "PubkeyAuthentication" --data sshd-pubkeyauth

write_header "========= Top 5 processes =========="

write_list --header "Top 5 processes by memory usage" --data top-5-processes

write_header "========= Suspicious users ========="

write_list --header "Users with empty passwords" --data nopass-users
write_list --header "Non root users with UID 0" --data pseudo-root-users

write_header "=========== SUID files ============="

write_list --header "Suid files" --data suid-files

# 6. Deleting temporary files
cleanup

# 7. Logging
log_run "$CURRENT_TIME"