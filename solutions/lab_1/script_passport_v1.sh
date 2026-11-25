#!/bin/bash

# preparing environment
mkdir -p PASSPORT/log
mkdir -p PASSPORT/tmp

tmp_path=PASSPORT/tmp
report_path=PASSPORT/passport.txt
current_time=$(date)

# logging
echo "$current_time: script started" >> PASSPORT/log/report.log

# collecting system information
echo $current_time > $tmp_path/date.tmp
hostname > $tmp_path/hostname.tmp
whoami > $tmp_path/user.tmp
pwd > $tmp_path/wd.tmp
ls -a> $tmp_path/files.tmp

# creating report
echo "====== System Information ======" > $report_path
echo "" >> $report_path
echo "current time: $(cat $tmp_path/date.tmp)" >> $report_path
echo "host name: $(cat $tmp_path/hostname.tmp)" >> $report_path
echo "user: $(cat $tmp_path/user.tmp)" >> $report_path
echo "working directory: $(cat $tmp_path/wd.tmp)" >> $report_path
echo "working directory containment:" >> $report_path
echo $(cat $tmp_path/files.tmp) >> $report_path

# deleting temp files
find -name "*.tmp" -delete