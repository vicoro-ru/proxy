# Envoy - L4 (tcp) балансировщик

Работает в режиме tcp, что видно по конфигу ниже, используемая библиотека - tcp_listener, далее блок address - прослушивает на всех адресах сервера (в данном случае контейнера) и на 15001 порту (перенаправлять трафик сюда)
```
  listeners:
  - name: tcp_listener
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 15001
```

Фильтр анализа первых байтов соединения TLS, анализируя заголовок направления, используя модуль envoy.filters.listener.tls_inspector. Указывается конфигурация фильтра typed_config, с параметрами по умолчанию {}. По умолчанию смотрит что внутри HTTP/1.2, 2, или что-то другое и берёт заголовок Server Name Indication
```
    listener_filters:
    - name: envoy.filters.listener.tls_inspector
      typed_config: {}
```

Самый главный блок конфигурации - политика, что делать:
```
    filter_chains:
    - filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: tcp_out
          cluster: direct_egress

          # retries если зависло
          retry_policy:
            retry_on: connect-failure,refused-stream,reset
            num_retries: 1

          # fallback → Tor
          weighted_clusters:
            clusters:
            - name: direct_egress
              weight: 80
            - name: tor_egress
              weight: 20
```
Где `filter_chains` - это список цепочек, тут лишь одна цепочка `filters`, может быть и другая для примера для БД. Блок `filters` - конфигурация данной цепочки (работает последовательно).
`Envoy.filters.network.tcp_proxy` - модуль который берёт данные из входящего и перенаправляет их. Далее идёт конфигурация этого модуля `typed_config`, где: `@type` указание типа расшифровки конфигурации ниже `type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy`, где `tcp_out` это приписка для логов статистики исходящего трафика.
`Cluster: direct_egress` - где cluster - указывает что используется кластер (шлюз) по умолчанию но будет перенаправлен в следующий (конфигурация ниже, в данном случае провайдеру `direct_egress`)

`Retry_policy` - политика повторов, если соединение сброщено `reset`, отказано `refused-stream`, или отсутствие ответа от сервера `connect-failure` то сделать еще одну попытку `num_retries: 1`

`weighted_clusters` - переопределение параметра `cluster: direct_egress`, говорящий следующее использовать два шлюза `clusters`: `direct_egress`, `tor_egress`, перераспределять между ними трафик в процентном соотношении 80% в один и 20% в другой. Тут и получается что почти всё идёт в основной и в случае если не выйдет то будет повторная попытка `retry_policy` (1 раз)


Далее идёт перечисление тех кого использовать с текущей политикой `filter_chains`, в данном случае перечисляются 2 шлюза `clusters`: `direct_egress`, `tor_egress`
```
  clusters:

  # ====== DIRECT / ISP ======
  - name: direct_egress
    connect_timeout: 3s
    type: ORIGINAL_DST
    lb_policy: CLUSTER_PROVIDED
    upstream_connection_options:
      tcp_keepalive:
        keepalive_time: 10

  # ====== TOR via HAProxy ======
  - name: tor_egress
    connect_timeout: 5s
    type: LOGICAL_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: tor_egress
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: haproxy
                port_value: 8118
```
### Direct (провайдер)
`name: direct_egress` - имя кластера используемое выше, `connect_timeout: 3s` - то что на попытку TCP соединения 3 секунды, `type: ORIGINAL_DST` - использовать ip адресс назначения указанный в пакете, не пытаться самому разрешить доменное имя. `lb_policy: CLUSTER_PROVIDED` - load balancing policy, балансировка разгрузки, обычно указываются сервера назначения (обязательный пункт так как балансировщик, но тут выбирается `ORIGINAL_DST` тобишь тот адресс который запросил клиент, почему так, а очень просто это балансировщик изначально для серверов и распределения между внутренних, а тут используется как для исходящих.
`upstream_connection_options:` - настройки соединения, в данном случае только одна `tcp_keepalive` которая говорит переодически напоминать о себе, в данном случае каждые 10 секунд `keepalive_time: 10`

### Tor
В данном случае я использую балансировщик haproxy, чтобы трафик направляемый уже на него балансировался им, тобишь для сотни участников сети не использовался один тор шлюз а там 4-5, но это уже его конфиг. Первые два пунка описаны выше, только время на попытку соединения больше так как Tor.
`lb_policy: ROUND_ROBIN` - обязательная балансировка, эта опция говорит ходить по кругу указанных, в данном случае только один сервер который у меня haproxy
`load_assignment` - накладная на назначение где указал что отправитель `cluster_name` это `tor_egress` и далее уже параметры конечной точки балансировки `lb_endpoints`: адресс назчания `address: haproxy` и порт `port_value: 8118`
