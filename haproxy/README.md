## Пояснения по конфигурации HAProxy

Ниже приведён разбор ключевых параметров `haproxy.cfg`, используемого в этом проекте.

### Блок `global`

```sh
global
    log stdout format raw local0
    maxconn 4096

    log stdout format raw local0 — вывод логов сразу в stdout (удобно для Docker, можно смотреть через docker logs haproxy).

    maxconn 4096 — максимальное количество одновременных соединений, которые может принять процесс HAProxy.
```
### Блок defaults
```sh
defaults
    log     global
    option  httplog
    option  dontlognull
    timeout connect 5s
    timeout client  50s
    timeout server  50s
```
Где:
log global — наследует параметры логирования из блока global.
option httplog — включает логирование HTTP-запросов в стандартном формате.
option dontlognull — отключает логирование пустых соединений (например, проверок на «живость»).
timeout connect 5s — максимальное время попытки подключения к backend (узлу tor+privoxy).
timeout client 50s — время ожидания активности от клиента.
timeout server 50s — время ожидания активности от backend'а.

### Блок frontend
```sh
frontend privoxy_in
    bind *:8118
    default_backend tor_privoxy_pool

    frontend privoxy_in — объявляем точку входа для клиентов.

    bind *:8118 — HAProxy слушает порт 8118 на всех интерфейсах контейнера.

    default_backend tor_privoxy_pool — весь трафик уходит в backend-пул, где крутятся tor+privoxy.
```
### Блок backend
```sh
backend tor_privoxy_pool
    balance roundrobin
    option httpchk GET /
    server-template proxy 10 proxy-node:8118 check resolvers docker init-addr none
    resolvers docker
        parse-resolv-conf
        hold valid 10s
```
    balance roundrobin — распределение запросов равномерно между всеми доступными узлами.

    option httpchk GET / — активная проверка доступности backend'а простым HTTP-запросом.

    server-template proxy 10 proxy-node:8118 ...

        proxy — базовое имя серверов (HAProxy сам создаст proxy1, proxy2 и т.д.).

        10 — максимальное количество ожидаемых контейнеров (можно увеличить при росте пула).

        proxy-node:8118 — имя сервиса в Docker (Docker DNS отдаст IP всех контейнеров этого сервиса).

        check — включает мониторинг доступности.

        resolvers docker — используем кастомный резолвер для динамического поиска IP.

        init-addr none — говорит не пытаться резолвить имя сразу при запуске (ждём появления контейнеров).

    resolvers docker

        parse-resolv-conf — использует настройки DNS внутри контейнера (обычно это Docker DNS).

        hold valid 10s — кэшировать DNS-записи 10 секунд.

### Итог
Эта конфигурация позволяет:
Балансировать между любым числом контейнеров tor+privoxy без ручного указания их IP.
Автоматически добавлять новые контейнеры, если их поднять через docker compose scale.
Исключать «падающие» узлы из пула без ручного вмешательства.