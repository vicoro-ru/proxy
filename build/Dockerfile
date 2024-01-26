FROM alpine:edge
MAINTAINER "Mikhail Ivanov <alisterosenheim@gmail.com>"
RUN apk add --no-cache squid openssl
RUN squid -z
# Build and install OpenSSL GOST Engine
RUN \
	export ossldir=`openssl version -a | sed -e '/^OPENSSLDIR:/!d;s/^.*: //;s/\"//g'` && \
	export osslengine=`openssl version -a | sed -e '/^ENGINESDIR:/!d;s/^.*: //;s/\"//g'` && \
	export ossllib=`openssl version -a | sed -e '/^MODULESDIR:/!d;s/^.*: //;s/\"//g'` && \
	cd /home && \
	apk add --no-cache --virtual build cmake make gcc g++ openssl-dev git && \
	git clone https://github.com/gost-engine/engine && \
	cd engine && \
	git submodule update --init && \
	mkdir build && \
	cd build && \
	cmake -DCMAKE_BUILD_TYPE=Release \
		-DOPENSSL_ROOT_DIR= ${ossldir}\
		-DOPENSSL_ENGINES_DIR= ${osslengine} \
		-DOPENSSL_LIBRARIES= ${ossllib} .. && \
	cmake --build . --config Release && \
	make install && \
	sed -i -e 's/^openssl_conf = .*$/openssl_conf = openssl_def/; \
		/^openssl_conf = openssl_def$/ a \
		[openssl_def] \n \
		engines = engine_section \n \
		[engine_section] \n \
		gost = gost_section \n \
		[gost_section] \n \
		engine_id = gost \n \
		dynamic_path = '"${osslengine}"'/gost.so \n \
		default_algorithms = ALL \
		' ${ossldir}/openssl.cnf && \
	apk del build && \
	unset ossldir osslengine ossllib && \
	rm -R /home/*
ENTRYPOINT ["squid"]
CMD ["-NCd1"]