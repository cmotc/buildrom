#!/bin/sh

tmp=`tempfile`
cat $1 | sed -e "s:%DESTFILE%:$2:" > $tmp
`dirname $0`/../scripts/kconfig/lxdialog/lxdialog --textbox $tmp 20 75
rm -rf $tmp

