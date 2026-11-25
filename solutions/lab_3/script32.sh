#!/usr/bin/env bash

log_file=~/script32.log 

while true; do
    date >> $log_file
    echo "PID: $$" >> $log_file
    echo "PPID: ${PPID}" >> $log_file
    echo >> $log_file
    
    sleep 2
done