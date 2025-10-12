#!/bin/sh
set -e

# Сколько мостов нужно выбрать
COUNT="${BRIDGES_COUNT:-3}"

# Чистим рабочий конфиг и копируем пример
cp /etc/tor/torrc.example /etc/tor/torrc

# Выбираем случайные строки из torList и дописываем в torrc
shuf -n "$COUNT" /etc/tor/torList | sed 's/^/Bridge /' >> /etc/tor/torrc
chown tor:tor /etc/tor/torrc
echo "[$(date)] Добавлено $COUNT мост(ов) в /etc/tor/torrc"
