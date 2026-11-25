#!/bin/bash

#checking dependencies
not_installed=""

for dependency in vi nano links; do
    if ! which $dependency &> /dev/null; then
        not_installed+=", $dependency"
    fi
done

if [[ "$not_installed" != "" ]]; then
    echo "${not_installed:2} not installed"
    exit 1
fi

# print options menu
echo ' _________________'
echo '|     Options     |'
echo '|_________________|'
echo '|  1 -  open vi   |'
echo '|  2 -  open nano |'
echo '|  3 -  open links|'
echo '|  4 -  exit menu |'
echo '|_________________|'
echo

# retrieve user choice
read -p "Please, enter your choice: " choice

# handle user choice
case "$choice" in
    1)
        vi
        ;;
    2)
        nano
        ;;
    3)
        links
        ;;
    4)
        exit 0
        ;;
    *)
        echo 'invalid input'
        ;;
esac