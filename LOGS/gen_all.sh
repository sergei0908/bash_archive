#!/bin/bash

for dir in auth_service data_process_service system_event_handler_service;
do
NAME=$dir

for i in 1 2 3; do
file_name="${NAME}_$(date +%Y_%m_%d)_$(( $(date +%s) - i )).log"
truncate -s 1M "${dir}/$file_name"
done

du -sh "$dir"
done
