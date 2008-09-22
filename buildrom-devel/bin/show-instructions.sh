#!/bin/sh

tmp=`tempfile`
cat $1 | sed -e "s:%DESTFILE%:$2:" > $tmp

if [ -x `dirname $0`/../scripts/kconfig/lxdialog/lxdialog ]; then
`dirname $0`/../scripts/kconfig/lxdialog/lxdialog --textbox $tmp 20 75
else
cat $tmp
fi
rm -rf $tmp

