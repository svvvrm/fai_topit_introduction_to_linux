#!/usr/bin/env bash

if [[ $# != 2 ]]; then 
    echo "two arguments required"
    exit 1
fi

if [[ $(id --user) != 0 ]]; then
    echo "root privileges required"
    exit 1
fi


start=$2
final=$(( $start + $1 ))


for (( i = $start; i < $final; i++ )); do
    new_user="u${i}"
    password="DerParol${i}"

    # execute if new_user doesn't exist
    if ! id "$new_user" &> /dev/null; then
        useradd -m -s /bin/bash "$new_user"
        echo "${new_user}:${password}" | chpasswd
    fi
done