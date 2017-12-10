#!/bin/bash

mkdir -p prof-reports
for FILE in `find ./isolate-0x*-v8.log -type f`
do
    NOW=`date +%Y_%m_%d__%H_%M_%S`
    LOG_FILENAME="$NOW.txt"
    if [[ -e "./prof-reports/$LOG_FILENAME" ]] ; then
        i=1
        while [[ -e "./prof-reports/$NOW-$i.txt" ]] ; do
            let i++
        done
        LOG_FILENAME="$NOW-$i.txt"
    fi
    node --prof-process $FILE > "./prof-reports/$LOG_FILENAME"
    rm $FILE
    echo "Generated report: $LOG_FILENAME"
done

