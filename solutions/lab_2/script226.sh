#!/bin/bash

# input validation
if [[ "$#" == 0 ]]; then
    echo "3 positional parameters required, $# passed instead"
    echo "usage: $0 <file name> < t | h > <number>"
    exit 1
fi

if [[ "$2" != 't' && "$2" != 'h' ]]; then
    echo "usage: $0 <file name> < t | h > <number>"
    exit 1
fi

if [[ ! "$3" =~ ^[0-9]+$ ]]; then
    echo "usage: $0 <file name> < t | h > <number>"
    exit 1
fi

# main logic
if [[ "$2" == 't' ]]; then
    tail -n $3 $1 2> /dev/null
else
    head -n $3 $1 2> /dev/null
fi