#!/bin/bash

if [ "$EUID" -ne 0 ]
then
    echo "This script must be run as root"
    exit 1
fi

if [[ -z $1 ]]
then
	echo "Simulator path for /usr/lib is required"
	exit 1
fi

SIM_USR_LIB=$1
LIBAPT_PKG_PATH=/opt/procursus/lib/libapt-pkg.6.0.0.dylib

rm -rf /opt/procursus/lib-sim/
cp -R /opt/procursus/lib/ /opt/procursus/lib-sim/

for f in $(find /opt/procursus/lib-sim -type f -name '*.dylib')
do
    vtool -remove-build-version 1 $f -o $f &> /dev/null
    vtool -set-version-min 2 8.0 14.5 $f -o $f &> /dev/null
    install_name_tool -change /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation /System/Library/Frameworks/Foundation.framework/Foundation $f &> /dev/null
    install_name_tool -change /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation $f &> /dev/null
    ldid -S $f
    rm -f $SIM_USR_LIB/$(basename $f)
    ln -s $f $SIM_USR_LIB/$(basename $f)
done

xdelta3 -f -d -s $LIBAPT_PKG_PATH $(basename LIBAPT_PKG_PATH).patch $LIBAPT_PKG_PATH
ldid -S ${LIBAPT_PKG_PATH/\/lib\//\/lib-sim\/}
