#!/bin/bash

name="auth_service"
file_name="${name}_$(date +%Y_%m_%d)_$(date +%s).log"
touch "$file_name"
echo "Создан файл: ${file_name}" > "$file_name"
