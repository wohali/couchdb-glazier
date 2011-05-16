#!/bin/sh
COUCH_TOP=`pwd`
export COUCH_TOP

./configure \
--prefix=$ERL_TOP/release/win32 \
--with-erlang=$ERL_TOP/release/win32/usr/include \
--with-win32-icu-binaries=/relax/icu \
--with-win32-curl=/relax/curl-7.21.5 \
--with-openssl-bin-dir=/relax/openssl/bin \
--with-msvc-redist-dir=/relax \
--with-js-lib=/relax/tracemonkey-57a6ad20eae9/js/src/dist/lib \
--with-js-include=/relax/tracemonkey-57a6ad20eae9/js/src/dist/include \
2>&1 | tee $COUCH_TOP/build_configure.txt

echo DONE. | tee -a $COUCH_TOP/build_configure.txt
