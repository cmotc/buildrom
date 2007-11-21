#!/bin/sh

size=`du -b $1 | cut -f1`
echo "******************"
echo "Payload takes $size Bytes (`expr $size / 1024` KBytes) in ROM:"
echo "******************"

exit 0
