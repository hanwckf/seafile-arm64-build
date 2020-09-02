#!/bin/sh

if [ -z "$TRAVIS" ]; then
	sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
fi

apk update

apk add --no-progress \
	gcc g++ make git cmake sudo intltool sqlite-dev py3-pip zlib-dev \
	libarchive-dev curl-dev glib libtool vala libxml2 libmemcached-dev \
	libevent-dev oniguruma-dev fuse-dev jansson-dev mariadb-dev \
	openssl-dev libxslt-dev util-linux-dev py3-setuptools \
	py3-lxml pkgconfig patch autoconf automake gzip \
	openldap-dev bsd-compat-headers

