#!/bin/bash

PWD=$(pwd)
BUILD_DIR=$PWD/build
SRC_DIR=$PWD/src
OUTPUT_DIR=$PWD/output

THIRDPARTY_DIR=$BUILD_DIR/seahub_thirdparty
PKG_SRC_DIR=$BUILD_DIR/seafile-src

SEAFILE_VERSION=7.1.5
SEAFILE_SRC="libsearpc libevhtp ccnet-server seafdav seafile-server seafobj seahub"

MYSQL_CONFIG_PATH=/usr/bin/mysql_config

libsearpc_version=3.1.0
seahub_version=6.0.1
seafile_server_version=6.0.1
ccnet_server_version=6.0.1

extract_src()
{
	mkdir -p $BUILD_DIR
	for src in $SEAFILE_SRC; do
		if [ ! -d $BUILD_DIR/$src ] && [ -f $SRC_DIR/$SEAFILE_VERSION/$src.tar.gz ]; then
			tar -xf $SRC_DIR/$SEAFILE_VERSION/$src.tar.gz -C $BUILD_DIR
		fi
	done

	if [ -d $SRC_DIR/$SEAFILE_VERSION/patches ]; then
		for p in $(ls "$SRC_DIR"/$SEAFILE_VERSION/patches/*.patch); do
			patch -r - -N -p1 -d $BUILD_DIR < $p
		done
	fi
}

build_and_install_libevhtp()
{
	echo -e "\e[93mBuild libevhtp\e[39m\n"
	( set -x
		cd $BUILD_DIR/libevhtp;
		cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=OFF . ;
		make -j`nproc`;
		sudo make install;
	)

	sudo ldconfig
}

export_pkg_config()
{
	echo -e "\e[93mExport PKG_CONFIG_PATH for seafile-server, libsearpc and ccnet-server\e[39m\n"

	export PKG_CONFIG_PATH=$BUILD_DIR/ccnet-server:$PKG_CONFIG_PATH
	export PKG_CONFIG_PATH=$BUILD_DIR/libsearpc:$PKG_CONFIG_PATH
	export PKG_CONFIG_PATH=$BUILD_DIR/seafile-server/lib:$PKG_CONFIG_PATH
}


build_libsearpc()
{
	echo -e "\e[93mBuild libsearpc\e[39m\n"

	( set -x
		cd $BUILD_DIR/libsearpc
		./autogen.sh
		./configure
		make dist
	)
}

build_ccnet()
{
	echo -e "\e[93mBuild ccnet-server\e[39m\n"

	( set -x
		cd $BUILD_DIR/ccnet-server
		./autogen.sh
		./configure --with-mysql=$MYSQL_CONFIG_PATH
		make dist
	)
}

build_seafile_server()
{
	echo -e "\e[93mBuild seafile-server\e[39m\n"

	( set -x
		cd $BUILD_DIR/seafile-server
		./autogen.sh
		./configure --with-mysql=$MYSQL_CONFIG_PATH
		make dist
	)
}

build_seafobj()
{
	echo -e "\e[93mBuild seafobj\e[39m\n"

	( set -x
		cd $BUILD_DIR/seafobj
		make dist
	)
}

build_seafdav()
{
	echo -e "\e[93mBuild seafdav\e[39m\n"

	( set -x
		cd $BUILD_DIR/seafdav
		make
	)
}

install_thirdparty()
{
	echo -e "\e[93mInstall Seafile thirdparty requirements\e[39m\n"

	if [ -z "$TRAVIS" ]; then
		python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
		python3 -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
	fi

	python3 -m pip install --user --upgrade pip setuptools wheel
	mkdir -p $THIRDPARTY_DIR

	cp -f $BUILD_DIR/seahub/requirements.txt $THIRDPARTY_DIR
	cat $BUILD_DIR/seafdav/requirements.txt >> $THIRDPARTY_DIR/requirements.txt

	if [ -n "$SEAFILE_IGNORE_PIP" ]; then
		for n in $SEAFILE_IGNORE_PIP; do
			sed -i "/\<${n}\>/d" $THIRDPARTY_DIR/requirements.txt
		done
	fi

	python3 -m pip install -r $THIRDPARTY_DIR/requirements.txt --target $THIRDPARTY_DIR --no-cache --upgrade

	rm -rf $(find $THIRDPARTY_DIR -name "__pycache__")
}


build_seahub()
{
	echo -e "\e[93mBuild seahub\e[39m\n"

	export PATH=$THIRDPARTY_DIR:$PATH
	export PATH=$THIRDPARTY_DIR/django/bin:$PATH
	export PYTHONPATH=$THIRDPARTY_DIR

	( set -x
		cd $BUILD_DIR/seahub
		python3 tools/gen-tarball.py --version=$seahub_version --branch=HEAD
	)
}

copy_pkg_source()
{
	echo -e "\e[93mCopy sources to $PKG_SRC_DIR/R$SEAFILE_VERSION \e[39m\n"

	mkdir -p $PKG_SRC_DIR/R$SEAFILE_VERSION

	cp $BUILD_DIR/libsearpc/libsearpc-$libsearpc_version.tar.gz $PKG_SRC_DIR/R$SEAFILE_VERSION
	cp $BUILD_DIR/ccnet-server/ccnet-$ccnet_server_version.tar.gz $PKG_SRC_DIR/R$SEAFILE_VERSION
	cp $BUILD_DIR/seafile-server/seafile-$seafile_server_version.tar.gz $PKG_SRC_DIR/R$SEAFILE_VERSION
	cp $BUILD_DIR/seahub/seahub-$seahub_version.tar.gz $PKG_SRC_DIR/R$SEAFILE_VERSION
	cp $BUILD_DIR/seafobj/seafobj.tar.gz $PKG_SRC_DIR/R$SEAFILE_VERSION
	cp $BUILD_DIR/seafdav/seafdav.tar.gz $PKG_SRC_DIR/R$SEAFILE_VERSION
}

run_fixup()
{
	if [ -d $SRC_DIR/$SEAFILE_VERSION/fixup ]; then
		for p in $(ls "$SRC_DIR"/$SEAFILE_VERSION/fixup/*.patch); do
			patch -r - -N -p1 -d $BUILD_DIR < $p
		done
	fi
}

build_seafile()
{
  echo -e "\e[93mBuild Seafile server\e[39m\n"

  mkdir -p $OUTPUT_DIR
  ( set -x
	cd $BUILD_DIR/seafile-server
	python3 scripts/build/build-server.py \
		--libsearpc_version=$libsearpc_version \
		--ccnet_version=$ccnet_server_version \
		--seafile_version=$seahub_version \
		--version=$SEAFILE_VERSION \
		--thirdpartdir=$THIRDPARTY_DIR \
		--srcdir=$PKG_SRC_DIR/R$SEAFILE_VERSION \
		--mysql_config=$MYSQL_CONFIG_PATH \
		--outputdir=$OUTPUT_DIR \
		--yes \
		--jobs `nproc`)
}

export_pkg_config
extract_src
build_and_install_libevhtp
build_libsearpc
build_ccnet
build_seafile_server
build_seafobj
build_seafdav
install_thirdparty
build_seahub
run_fixup
copy_pkg_source
build_seafile
