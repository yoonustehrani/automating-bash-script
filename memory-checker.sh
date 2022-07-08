#!/bin/bash

# @arg $1 amont in kB
kB_to_mB() {
    amount_in_mB=$(bc -l <<< "($1 / 1000)")
    amount=$(printf %.2f $amount_in_mB)
    echo $amount
}

# @arg $1 amont in kB
kB_to_gB() {
    amount_in_gB=$(bc -l <<< "($1 / 1000000)")
    amount=$(printf %.2f $amount_in_gB)
    echo $amount
}

# @arg $1 Total memory integer 
# @arg $2 Free memory integer
# @arg $3 memory_usage_percent
# @arg $4 Expected memory to be used at max
# @returns void
log_memory_info() {
    message="\n<===============================>\n"
    message+="$(date)\n\n"
    message+="Memory exceeded the expected $4% by $3%\n"
    message+="Available memory: $(kB_to_mB $2)mB ($2kB)\n"
    message+="Total memory: $(kB_to_gB $1)gB ($1kB)\n"
    message+="<===============================>\n"
    echo -e $message >> /var/log/memchecker/usage.log
}

# @arg $1 Total memory integer
# @arg $2 Free memory integer
# @returns Used memory in decimal (e.g. 64.12)
memory_usage_percent() {
    usage=$(bc -l <<< "100-(($2/$1)*100)")
    usage_rounded=`printf %.2f $usage`
    echo $usage_rounded
}

# @arg $1 Used memory percent 
# @arg $2 Expected memory to be used at max
# @returns bool wheter the memory usage exceeded or not
memory_exceeds_the_maximum() {
    condition=$(bc -l <<< "$1>$2.00")
    echo $condition
}

info=$(cat /proc/meminfo)
total=$(echo "$info" | sed -n '1p' | sed 's_MemTotal:__' | sed 's_kB__')
free=$(echo "$info" | sed -n '3p' | sed 's_MemAvailable:__' | sed 's_kB__')
usage=$(memory_usage_percent $total $free)

if [ -z $mem_exceed_limit ]
then
    max_mem=80
else
    max_mem=$mem_exceed_limit
fi

# check if 0 < $max_mem < 100
if [[ ( $max_mem -gt 100 || $max_mem -lt 1) ]]
then
    echo "Please consider that the mem_exceed_limit should be a number between 1 and 100"
    exit 2
fi

# Hereby we check if the usage percentage is above
# the expected percentage mentioned by $max_mem
if [ $(memory_exceeds_the_maximum $usage $max_mem) -eq 1 ]
then
    log_memory_info $total $free $usage $max_mem
fi