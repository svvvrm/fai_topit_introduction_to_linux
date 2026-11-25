#!/bin/bash

result=''

while true; do
    read -p "Enter your text: " line

    if [[ $line == 'q' ]]; then
        break
    fi

    result+=" $line"
done

if [[ "$result" != "" ]]; then
    echo "${result:1}"
fi