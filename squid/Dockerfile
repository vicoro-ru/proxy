FROM alpine:edge
MAINTAINER "Mikhail Ivanov <alisterosenheim@gmail.com>"
RUN apk add --no-cache squid openssl tzdata
RUN squid -z && \
	/usr/lib/squid/security_file_certgen -c -s /var/lib/ssl_db -M 32MB && \
	chown squid:squid -R /var/lib/ssl_db
# Add langpack
RUN \
	rm -R /usr/share/squid/errors/* & \
	wget -P /home http://www.squid-cache.org/Versions/langpack/squid-langpack-20231227.tar.gz && \
	tar -xzf /home/squid-langpack-20231227.tar.gz -C /usr/share/squid/errors && \
	/usr/share/squid/errors/alias-link.sh "/bin/ln" "/bin/rm -f"  "/usr/share/squid/errors" "/usr/share/squid/errors/aliases"
# Build and install OpenSSL GOST Engine
RUN \
	export ossldir=`openssl version -d | grep -o '\/.*[^"]'` && \
	export osslengine=`openssl version -e | grep -o '\/.*[^"]'` && \
	export ossllib=`openssl version -m | grep -o '\/.*[^"]'` && \
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