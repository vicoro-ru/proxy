# Squid & Openssl + Gost Engine
## О репозитории
Сборка построена в контейнере на основе Alpine Edge, из-за меньших размеров в сравнении с Debian/Ubuntu, а также удобства чистки библиотек и программ необходимых для компиляции.
Состоит из:
* Squid 6.6 с опциями 
    - --enable-ssl-crtd,
    - --enable-openssl
    - ...
* Openssl 3.14
* Gost Engine 3.0.3 с алогоритмами: GOST2012-MAGMA-MAGMAOMAC, GOST2012-KUZNYECHIK-KUZNYECHIKOMAC, LEGACY-GOST2012-GOST8912-GOST8912, IANA-GOST2012-GOST8912-GOST8912, GOST2001-GOST89-GOST89

Образ доступен на [dockerhub](https://hub.docker.com/repository/docker/glogol/squid)
## Настройка и компиляция Gost Engine
### Сборка
Устанавливаю необходимые программы для сборки Gost Engine без сохранения кэша и группируя их в виртуальный пакет:

    # apk add --no-cache --virtual build cmake make gcc g++ openssl-dev git

Для оптимизации создаю переменные окружения с директориями где распологается конфиг, ядро и библиотеки. Так как эти директории можно узнать при помощи команды `openssl version -a` то парсю их сначала находя нужную строку путём удаления всех остальных не попадающих под шаблон, затем удаляю из неё всё лишнее. На выходе получаю 3 переменные окружения `ossldir`, `osslengine`, `ossllib`.

    # export ossldir=`openssl version -a | sed -e '/^OPENSSLDIR:/!d;s/^.*: //;s/\"//g'`
    # export osslengine=`openssl version -a | sed -e '/^ENGINESDIR:/!d;s/^.*: //;s/\"//g'`
    # export ossllib=`openssl version -a | sed -e '/^MODULESDIR:/!d;s/^.*: //;s/\"//g'`

Инициализирую репозиторий Gost Engine получаю последний коммит создаю директорию для сборки и перехожу в неё согласно [документации](https://github.com/gost-engine/engine/blob/master/INSTALL.md)

    # apk add --no-cache --virtual build cmake make gcc g++ openssl-dev git
    # git clone https://github.com/gost-engine/engine
    # cd engine
    # git submodule update --init
    # mkdir build
    # cd build

Задаю значение переменных cmake, указав тип сборки и директории найденные ранее.

    # make -DCMAKE_BUILD_TYPE=Release \
           -DOPENSSL_ROOT_DIR= ${ossldir}\
           -DOPENSSL_ENGINES_DIR= ${osslengine} \
           -DOPENSSL_LIBRARIES= ${ossllib} ..

Собираем и устанавливаем новое ядро

    cmake --build . --config Release
    make install
### Конфигурация
Редактируем конфиг Openssl указав раздел конфигурации дялее какое ядро хотим использовать и ссылаемся на него задав id и путь полученный из переменной окружения `osslengine`. Найдя строку `openssl_conf` задав параметр и добавля строки сразу после неё при помощи потокового редактора sed.

    # sed -i -e 's/^openssl_conf = .*$/openssl_conf = openssl_def/; \
        /^openssl_conf = openssl_def$/ a \
        [openssl_def] \n \
        engines = engine_section \n \
        [engine_section] \n \
        gost = gost_section \n \
        [gost_section] \n \
        engine_id = gost \n \
        dynamic_path = '"${osslengine}"'/gost.so \n \
        default_algorithms = ALL \
        ' ${ossldir}/openssl.cnf 

Проверяю что всё работает

    # openssl ciphers|tr ':' '\n'|grep GOST

### Чистка
Удаляю все необходимые программы и библиотеки для сборки и скачанные файлы репозитория Gost-Engine, а также переменные окружения.

    # apk del build
    # unset ossldir osslengine ossllib
    # rm -R /home/*