Проверка конфигурации
named-checkconf /etc/bind/named.conf
Перезапуск сервера
rndc reload

rndc stats
grep "cache" /var/run/named/named.stats # Путь может зависеть от ОС