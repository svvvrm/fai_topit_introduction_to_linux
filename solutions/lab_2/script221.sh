#!/bin/bash

# input validation
if [[ "$#" != 2 ]]; then
    echo "usage: $0 <string1> <string2>"
    exit 1
fi

# comparing strings
if [[ "$1" == "$2" ]]; then
    echo 'equal'
else 
    echo 'not equal'
fi
