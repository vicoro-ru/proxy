1. Суть проблемы («Лицо» блокировки)

    Симптом: TCP-Handshake (SYN) проходит, но сессия виснет на первом пакете с данными (TLS Client Hello).
    Причина: DPI провайдера видит SNI в пакете стандартного размера (близкого к MSS/MTU) и молча дропает ответные пакеты сервера.
    Маркер: Наличие Retransmissions (повторов) одного и того же пакета данных со стороны клиента при 0 байт ответа от сервера.

2. Цепочка шлюзов (Cluster Chain)
Нужно настроить иерархию выходов в интернет:

    Direct (L4): Прямой выход. Максимальная скорость, не ломает «нежные» мелкие сайты.
    ByeDPI (SOCKS5): Шлюз с агрессивной нарезкой (-d1 -s1 и т.д.). Для обхода блокировок крупных ресурсов.
    Tor/External: Последний рубеж для самых сложных случаев.

3. Метод идентификации и переключения
Поскольку сессия «зависает» в ядре, её нужно убить и перенаправить:

    Вариант А (Envoy + Lua):
        Скрипт засекает время после отправки первого байта данных (Payload > 0).
        Если за 300–500 мс не пришло ни одного байта ответа (upstream_data_size == 0), скрипт отправляет TCP RST клиенту.
        IP-адрес заносится в динамический «черный список» (Redis/Runtime Discovery Service).
        При повторном запросе (Retry) Envoy сразу отправляет трафик на кластер ByeDPI.
    Вариант Б (eBPF + ipset — Самый точный):
        Скрипт в ядре Linux ловит Retransmits пакетов размером ~MSS.
        При обнаружении зависания IP сервера добавляется в ipset.
        Envoy или системный роутинг (через fwmark) направляет трафик из этого ipset в ByeDPI.

4. Настройка ByeDPI
Для «пробива» использовать твою проверенную стратегию:
ciadpi -i 0.0.0.0 -p 1080 -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As
Что гуглить при возвращении к задаче:

    Envoy Lua filter tcp timeout first byte
    Envoy Aggregate Cluster retry policy
    eBPF tcp retransmission detection ipset
    ByeDPI ciadpi auto-strategy linux

    PS C:\Users\alist\Documents\proxy\byedpi> docker run -it --rm --name my-byedpi --dns 172.16.10.2 --dns 172.16.10.3 -p 1080:1080 byedpi /usr/local/bin/ciadpi -I 0.0.0.0 -p 1080 -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As

    curl -vkI --socks5-hostname 127.0.0.1:1080 https://googlevideo.com
curl -vkI --socks5 127.0.0.1:1080 --dns-servers 172.16.10.2 https://googlevideo.com