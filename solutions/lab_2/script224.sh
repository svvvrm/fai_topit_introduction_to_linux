#!/bin/bash

counter=0

while true; do
    read -p 'Enter a number: ' current

    # input validation
    if [[ ! "$current" =~ ^[+-]?[0-9]+$ ]]; then
        echo "Not a valid number"
        continue
    fi

    if (( current % 2 == 0 )); then
        break
    fi

    (( counter+=1 ))
done

echo "Total: $counter"