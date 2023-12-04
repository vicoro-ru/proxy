#!/bin/bash


help () {
	printf "Avalible key:
	crc - Create a new root certificate
	help - Print this manual
	\n"
}
crc () {
	#
	# Create Root CA
	#
	mkdir RCA 
	openssl req -new \
	-newkey rsa:2048 -sha256 -days 1095 -nodes -x509 -extensions v3_ca \
	-subj "/C=RU/ST=Vologda/L=Vologda/O=VIRO/OU=IT/CN=viro.edu.ru" \
	-keyout RCA/myCA.pem  -out RCA/myCA.pe
}

case $key in
	crc)
		crc
		;;
	*)
		help
		;;
esac