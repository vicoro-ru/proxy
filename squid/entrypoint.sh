#!/bin/sh

# Точка входа прокси сервера Squid

# Сдесь выводятся логи прокси сервера в стандатный поток
# ввода вывода для доступа к ним при вызове `docker logs -f container_name`

# Помимо этого предоставляет возможность контейнеру принимать ключи
# вызванные при его создании. По умолчанию они `-NYC`

# самоподписанный серстификат для MitM
#if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
#    /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite > /dev/null 2>&1
#fi
# Следим за логами
tail -F /var/log/squid/access.log 2>/dev/null &
tail -F /var/log/squid/error.log 2>/dev/null &
tail -F /var/log/squid/store.log 2>/dev/null &
tail -F /var/log/squid/cache.log 2>/dev/null &
# Создаём директории кэша
/usr/sbin/squid -Nz
# Запускаем демона с ключами контейнера
/usr/sbin/squid "$@"