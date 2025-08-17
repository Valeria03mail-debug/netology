#!/bin/bash

# Функция для проверки прав root
check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "Скрипт должен быть запущен с правами root. Используйте sudo."
        exit 1
    fi
}

# Функция для проверки, что часть IP-адреса является числом от 1 до 255
validate_ip_part() {
    local part="$1"
    if ! [[ "$part" =~ ^(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]]; then
        echo "Ошибка: Некорректный формат IP-адреса. Все части должны быть от 1 до 255."
        exit 1
    fi
}

# Универсальная функция для сканирования, обрабатывающая все режимы.
perform_scan() {
    local prefix="$1"
    local interface="$2"
    local subnets="$3"
    local hosts="$4"

    # Используем eval для итерации по диапазонам, переданным как строки
    for subnet in $(eval echo "$subnets")
    do
        for host in $(eval echo "$hosts")
        do
            echo "[*] IP : ${prefix}.${subnet}.${host}"
            arping -c 3 -i "$interface" "${prefix}.${subnet}.${host}" 2> /dev/null
        done
    done
}

check_root

# Проверка количества аргументов и их валидация
if [[ "$#" -lt 2 || "$#" -gt 4 ]]; then
    echo "Использование: $0 <PREFIX> <INTERFACE> [SUBNET] [HOST]"
    exit 1
fi

PREFIX="$1"
INTERFACE="$2"
SUBNET="$3"
HOST="$4"

# Валидация PREFIX
if ! [[ "$PREFIX" =~ ^(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]]; then
    echo "Ошибка: Некорректный формат PREFIX. Ожидается формат 'xxx.xxx'."
    exit 1
fi

# Валидация интерфейса
if [[ -z "$INTERFACE" ]]; then
    echo "\$INTERFACE должен быть передан вторым аргументом."
    exit 1
fi

# В зависимости от количества аргументов запускаем универсальную функцию
case "$#" in
    2)
        echo "Сканирование всей подсети ${PREFIX}.ххх.ххх..."
        perform_scan "$PREFIX" "$INTERFACE" "{1..255}" "{1..255}"
        ;;
    3)
        validate_ip_part "$SUBNET"
        echo "Сканирование хостов в подсети ${PREFIX}.${SUBNET}.ххх..."
        perform_scan "$PREFIX" "$INTERFACE" "$SUBNET" "{1..255}"
        ;;
    4)
        validate_ip_part "$SUBNET"
        validate_ip_part "$HOST"
        echo "Сканирование одного IP-адреса: ${PREFIX}.${SUBNET}.${HOST}..."
        perform_scan "$PREFIX" "$INTERFACE" "$SUBNET" "$HOST"
        ;;
esac

exit 0
