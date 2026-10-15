#!/bin/bash
# log_manager.sh: ротация логов

LOGS_DIR="${LOGS_DIR:-/LOGS}"
THRESHOLD="${THRESHOLD:-90}"
SERVICES=(auth_service data_process_service system_event_handler_service)

echo "Скрипт запущен, папка: $LOGS_DIR, порог: $THRESHOLD%"

usage=$(df --output=pcent "$LOGS_DIR" | tail -n 1 | tr -dc '0-9')
echo "Занято: ${usage}%"

if(( usage < THRESHOLD )); then
	echo "Порог не превышен"
	exit 0
fi

echo "Порог превышен, переходим к очистке"

total=$(df -B1 --output=size "$LOGS_DIR" | tail -n 1 | tr -d ' ')
limit=$(( total / 3 ))
echo "Размер раздела: $total Б, лимит на папку: $limit Б"

shopt -s nullglob
for svc in "${SERVICES[@]}"; do
	dir="$LOGS_DIR/$svc"
	[[ -d "$dir" ]] || continue

	size=$(du -sb "$dir" | cut -f1)
	if (( size <= limit )); then
		echo "$svc: $size <= $limit, в пределах квоты"
		continue
	fi
	need=$(( size - limit ))
	echo "$svc: $size > $limit, НАРУШИТЕЛЬ, нужно освободить $need Б"

	mapfile -t sorted < <(
		for f in "$dir"/*.log; do
			base=${f##*/}
			ts=${base%.log}
			ts=${ts##*_}
			echo "$ts $f"
		done | sort -n
	)

	count=${#sorted[@]}
	echo "$svc: файлов .log: $count"
	printf '%s\n' "${sorted[@]}"

	if (( count < 2 )); then
		echo "$svc: нечего архивировать"
		continue
	fi

	to_pack=(); freed=0
	for (( i = 0; i < count - 1 && freed < need; i++ )); do
		f="${sorted[i]#* }"
		to_pack+=("$f")
		freed=$(( freed + $(stat -c %s "$f") ))
	done

	echo "$svc: будет упаковано ${#to_pack[@]} файлов, освободится $freed Б:"
	printf ' %s\n' "${to_pack[@]}"

	names=("${to_pack[@]##*/}")
	archive="$dir/${svc}_archive_$(date +%Y_%m_%d_%H%M%S).tar.gz"

	if tar -czf "$archive" -C "$dir" "${names[@]}"; then
		rm -f "${to_pack[@]}"
		echo "$svc: заархивировано ${#to_pack[@]} файлов -> $archive"
	else
		echo "$svc: ошибка tar, файлы не удалены" >&2
		rm -f "$archive"
	fi
done
