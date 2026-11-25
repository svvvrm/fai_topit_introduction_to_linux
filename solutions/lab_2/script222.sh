#!/bin/bash

# input validation
if [[ "$#" != 3 ]]; then
    echo "usage: $0 <number1> <number2> <number>"
    exit 1
fi

# finding maximum value
if (( $1 <= $3 && $2 <= $3 )); then
    echo "maximum number: $3"

elif  (( $3 <= $2 && $3 <= $2 )); then
    echo "maximum number: $2"

elif (( $2 <= $1 && $3 <= $1 )); then
    echo "maximum number: $1"

fi