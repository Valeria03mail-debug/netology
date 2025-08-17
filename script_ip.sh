#!/bin/bash

# Функция для проверки прав root.
check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "Скрипт должен быть запущен с правами root, повысьте права."
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

# Функция для сканирования одного хоста
scan_host() {
    local prefix="$1"
    local interface="$2"
    local subnet="$3"
    local host="$4"
    echo "[*] IP : ${prefix}.${subnet}.${host}"
    arping -c 3 -i "$interface" "${prefix}.${subnet}.${host}" 2> /dev/null
}

# Функция для сканирования всех хостов в одной подсети
scan_subnet() {
    local prefix="$1"
    local interface="$2"
    local subnet="$3"
    for host in {1..255}
    do
       scan_host "$prefix" "$interface" "$subnet" "$host"
    done
}

# Функция для сканирования всех подсетей и хостов
scan_all_subnets() {
    local prefix="$1"
    local interface="$2"
    for subnet in {1..255}
    do
        scan_subnet "$prefix" "$interface" "$subnet"
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

# В зависимости от количества аргументов запускаем нужную функцию
case "$#" in
    2)
        echo "Сканирование всей подсети ${PREFIX}.ххх.ххх..."
        scan_all_subnets "$PREFIX" "$INTERFACE"
        ;;
    3)
        validate_ip_part "$SUBNET"
        echo "Сканирование хостов в подсети ${PREFIX}.${SUBNET}.ххх..."
        scan_subnet "$PREFIX" "$INTERFACE" "$SUBNET"
        ;;
    4)
        validate_ip_part "$SUBNET"
        validate_ip_part "$HOST"
        echo "Сканирование одного IP-адреса: ${PREFIX}.${SUBNET}.${HOST}..."
        scan_host "$PREFIX" "$INTERFACE" "$SUBNET" "$HOST"
        ;;
esac

exit 0
