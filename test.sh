#!/bin/bash

if ! mountpoint -q /LOGS; then
    echo "/LOGS не смонтирован, сначала смонтируйте раздел"
    exit 1
fi
 
SIZE=$(df -BM --output=size /LOGS | tail -n 1 | tr -dc '0-9')
 
make_logs() {
    mkdir -p /LOGS/$1
    for i in 1 2 3; do
        ts=$(( $(date +%s) - i * 100 ))
        day=$(date +%Y_%m_%d)
        fallocate -l $(( SIZE * $2 / 100 / 3 ))M /LOGS/$1/$1_${day}_$ts.log
    done
}
 
# Сколько .log и .tar.gz файлов в папке сервиса
logs_count() { ls /LOGS/$1/*.log 2>/dev/null | wc -l; }
tar_count()  { ls /LOGS/$1/*.tar.gz 2>/dev/null | wc -l; }
 
expect_untouched() {
    if [ "$(tar_count $1)" -eq 0 ] && [ "$(logs_count $1)" -eq 3 ]; then
        echo "  PASS  $1 не тронут"
    else
        echo "  FAIL  $1 должен остаться не тронутым"
    fi
}

expect_archived() {
    if [ "$(tar_count $1)" -ge 1 ] && [ "$(logs_count $1)" -lt 3 ]; then
        echo "  PASS  $1 заархивирован"
    else
        echo "  FAIL  $1 должен быть заархивирован"
    fi
}
 
# --- Тест 1: диск 45%, ничего не должно измениться ---
echo "Тест 1: диск ~50%, архивации быть не должно"
clear_logs
make_logs auth_service 15
make_logs data_process_service 15
make_logs system_event_handler_service 15
./log_manager.sh
expect_untouched auth_service
expect_untouched data_process_service
expect_untouched system_event_handler_service
 
# --- Тест 2: диск =90%, переполнен только auth_service ---
echo
echo "Тест 2: заполнен только auth_service"
clear_logs
make_logs auth_service 70
make_logs data_process_service 10
make_logs system_event_handler_service 10
./log_manager.sh
expect_archived auth_service
expect_untouched data_process_service
expect_untouched system_event_handler_service
 
# --- Тест 3: диск =90%, переполнены две службы ---
echo
echo "Тест 3: заполнены auth_service и data_process_service"
clear_logs
make_logs auth_service 40
make_logs data_process_service 40
make_logs system_event_handler_service 10
./log_manager.sh
expect_archived auth_service
expect_archived data_process_service
expect_untouched system_event_handler_service
 
rm -rf /LOGS/auth_service /LOGS/data_process_service /LOGS/system_event_handler_service
