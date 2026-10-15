#!/bin/bash
if [ ! -f "/var/logs_disk.img" ]; then
echo "Ошибка: Файл образа /var/logs_disk.img не найден!" >&2
exit 1
fi
mkdir -p "/LOGS"
if mountpoint -q "/LOGS"; then
echo "Раздел /LOGS уже смонтирован.
"
else
mount -o loop "/var/logs_disk.img" "/LOGS"
echo "Раздел успешно смонтирован в /LOGS.
"
fi
mkdir -p "/LOGS/auth_service"
mkdir -p "/LOGS/data_process_service"
3. Автозапуск через systemd
mkdir -p "/LOGS/system_event_handler_service"
chmod -R 777 "/LOGS"
