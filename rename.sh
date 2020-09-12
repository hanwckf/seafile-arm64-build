#!/bin/bash

[ -z "$1" ] && exit 1

cd seafile-build/output || exit 1

for x in `ls`; do
	new_filename=`sed "s#.tar.gz#-$1.tar.gz#" <<< $x`
	mv $x $new_filename
done

