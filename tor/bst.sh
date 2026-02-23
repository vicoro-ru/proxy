#!/bin/sh
#set -e
COUNT="${BRIDGES_COUNT:-3}"

# 1. Восстанавливаем базу конфига из шаблона
cp /etc/tor/torrc.example /etc/tor/torrc

echo "" >> /etc/tor/torrc
echo "# --- Динамически добавленные мосты ---" >> /etc/tor/torrc

# 2. Выбираем obfs4 мосты
if [ -f /etc/tor/obfs4.list ]; then
    shuf -n "$COUNT" /etc/tor/obfs4.list | sed 's/^/Bridge /' >> /etc/tor/torrc
    echo "[$(date)] Добавлено $COUNT мостов obfs4"
fi

# 3. Выбираем WebTunnel мосты
if [ -f /etc/tor/webtunnel.list ]; then
    shuf -n "$COUNT" /etc/tor/webtunnel.list | sed 's/^/Bridge /' >> /etc/tor/torrc
    echo "[$(date)] Добавлено $COUNT мостов webtunnel"
fi

# 4. Устанавливаем права
chown tor:tor /etc/tor/torrc
