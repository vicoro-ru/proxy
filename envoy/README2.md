# Реверс прокси
## Базовые настройки
Работает в режиме tcp основной сервер `main_listener`. Слушает на всех адресах и 15001 порту использует библиотеку `tls_inspector`, для извлечения домена из запроса пользователя.
```
static_resources:
  listeners:
    - name: main_listener
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 15001
      listener_filters:
        - name: "envoy.filters.listener.tls_inspector"
          typed_config:
            "@type": ://type.googleapis.com
```
## Блок правил обработки запроса
Основной блок фильтрации запросов с правилами, кому дальше передавать
### Ru зона
Основное это правило совпадения, если по регулярному выражение адрес назначения `server_name`, так как это реверс прокси, совпадает с ru или рф то. То применяется фильтрация `filters` для этого используется `Envoy.filters.network.tcp_proxy` - модуль который берёт данные из входящего и перенаправляет их. Далее идёт 
```
     filter_chains:
        - filter_chain_match:
            server_names: ["*.ru", "*.рф"]
          filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": ://type.googleapis.com
                stat_prefix: direct_ru
                cluster: direct_rostelecom

```

### Все остальные
```
        # ПРАВИЛО 2: Все остальное (Умный Fallback)
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": ://type.googleapis.com
                stat_prefix: smart_fallback
                cluster: aggregate_cluster
                # ПОЛИТИКА ПОВТОРОВ:
                # Если первый кластер в агрегаторе вернул ошибку или тайм-аут,
                # Envoy пробует следующий.
                max_connect_attempts: 3 
                idle_timeout: 30s
```