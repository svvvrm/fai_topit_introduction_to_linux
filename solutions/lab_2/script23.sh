#!/bin/bash

calculate_float_numbers() {
    local calculations="$1"

    for ((i = 1; i <= calculations; i++)); do
        echo "scale=10; 123456.789123 * 123456.789123" | bc > /dev/null
    done
}


calculations=100


start=$(date +%s%N)

calculate_float_numbers "$calculations"

end=$(date +%s%N)

difference_sec=$(bc <<< "scale=10; ($end - $start) / 1000000000")
result=$(bc <<< "$calculations / $difference_sec")

echo "Result: $result FLOPS"