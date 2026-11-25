#!/bin/bash

# preparing environment
mkdir -p PASSPORT/log
mkdir -p PASSPORT/tmp

tmp_path=PASSPORT/tmp
report_path=PASSPORT/inventory.txt
current_time=$(date)


# collecting system information
echo $current_time > $tmp_path/date.tmp
hostname > $tmp_path/hostname.tmp
whoami > $tmp_path/user.tmp
pwd > $tmp_path/wd.tmp
ls -a > $tmp_path/files.tmp

uname --kernel-name > $tmp_path/kernel-name.tmp
uname --kernel-version > $tmp_path/kernel-version.tmp
uname --machine > $tmp_path/cpu-bitness.tmp
. /etc/os-release && echo $PRETTY_NAME > $tmp_path/os-version.tmp
grep -m 1 "model name" /proc/cpuinfo | sed 's/.*: //' > $tmp_path/cpu-model.tmp
cat /proc/cpuinfo | grep "model name" | head -n 1 > $tmp_path/cpu-model.tmp
lscpu | grep -m 1 "CPU max MHz" | sed 's/^[^0-9]*//' > $tmp_path/cpu-mhz.tmp
nproc > $tmp_path/cpu-cores.tmp
lscpu | grep "L.*cache" > $tmp_path/cpu-caches.tmp
grep "MemTotal" /proc/meminfo | sed 's/MemTotal:[ \t]*//' > $tmp_path/memory.tmp
dmidecode -s baseboard-product-name > $tmp_path/motherboard.tmp
dmidecode -s bios-version > $tmp_path/bios-version.tmp
dmidecode -s bios-release-date > $tmp_path/bios-release-date.tmp
lspci > $tmp_path/pci.tmp


# creating report
echo "====== System Information ======" > $report_path
echo "" >> $report_path
echo "current time: $(cat $tmp_path/date.tmp)" >> $report_path
echo "host name: $(cat $tmp_path/hostname.tmp)" >> $report_path
echo "user: $(cat $tmp_path/user.tmp)" >> $report_path
echo "working directory: $(cat $tmp_path/wd.tmp)" >> $report_path
echo "working directory containment:" >> $report_path
echo $(cat $tmp_path/files.tmp) >> $report_path

echo >> $report_path
echo "kernel: $(cat $tmp_path/kernel-name.tmp)" >> $report_path
echo "kernel version: $(cat $tmp_path/kernel-version.tmp)" >> $report_path
echo "cpu bitness: $(cat $tmp_path/cpu-bitness.tmp)" >> $report_path
echo "os version: $(cat $tmp_path/os-version.tmp)" >> $report_path
echo "CPU: $(cat $tmp_path/cpu-model.tmp)" >> $report_path
echo "CPU max MHz: $(cat $tmp_path/cpu-mhz.tmp)" >> $report_path
echo "CPU cores: $(cat $tmp_path/cpu-cores.tmp)" >> $report_path
echo "motherboard model: $(cat $tmp_path/motherboard.tmp)" >> $report_path
echo "bios version: $(cat $tmp_path/bios-version.tmp)" >> $report_path
echo "bios release date: $(cat $tmp_path/bios-release-date.tmp)" >> $report_path
echo "devices connected to pci:" >> $report_path
echo >> $report_path

while IFS= read -r line; do
    echo "$line" >> $report_path
done < $tmp_path/pci.tmp


# deleting temp files
find -name "*.tmp" -delete


# logging
echo "$current_time: script started" >> PASSPORT/log/report.log