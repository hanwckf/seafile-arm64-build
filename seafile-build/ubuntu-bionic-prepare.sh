#!/bin/sh

if [ -z "$TRAVIS" ]; then
	sed -i 's#ports.ubuntu.com#mirrors.tuna.tsinghua.edu.cn#' /etc/apt/sources.list
fi

export DEBIAN_FRONTEND=noninteractive
apt_arg='-y -o Dpkg::Progress-Fancy="0"'

cat <<EOF > ./usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF

chmod +x ./usr/sbin/policy-rc.d

apt $apt_arg update && apt $apt_arg upgrade -y
apt $apt_arg install -y \
	build-essential \
	cmake \
	git \
	sudo \
	intltool \
	libarchive-dev \
	libcurl4-openssl-dev \
	libevent-dev \
	libfuse-dev \
	libglib2.0-dev \
	libjansson-dev \
	libldap2-dev \
	libonig-dev \
	libpq-dev \
	libsqlite3-dev \
	libmariadbclient-dev \
	libssl-dev \
	libtool \
	libxml2-dev \
	libxslt-dev \
	python3-lxml \
	python3-setuptools \
	uuid-dev \
	valac \
	python3-pip

