#!/bin/bash

# Problems
# 1. Simulator path of /usr/lib and /usr/bin don't have Procursus bootstrap
# 2. Procursus bootstrap are for macOS, not iOS-sim
# 3. libapt-pkg.6.0.0.dylib links to not simulator-friendly symbols: e.g. (f)opendir$INODE64

# TODO: See if we need to clone /usr/bin

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
LIBAPT_PKG_SIM_PATH=/opt/procursus/lib-sim/libapt-pkg.6.0.0.dylib

rm -rf /opt/procursus/lib-sim/
cp -R /opt/procursus/lib/ /opt/procursus/lib-sim/

for f in $(find /opt/procursus/lib-sim -type f -name '*.dylib')
do
    xcrun vtool -remove-build-version 1 $f -o $f &> /dev/null
    xcrun vtool -set-build-version 7 13.0 13.0 $f -o $f &> /dev/null
    install_name_tool -change /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation /System/Library/Frameworks/Foundation.framework/Foundation $f &> /dev/null
    install_name_tool -change /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation $f &> /dev/null
    install_name_tool -add_rpath "/opt/procursus/lib-sim" $f &> /dev/null
    ldid -S $f
    rm -f "$SIM_USR_LIB/$(basename $f)"
    ln -s $f "$SIM_USR_LIB/$(basename $f)"
done

rm -f "$SIM_USR_LIB/libapt-pkg.6.0.dylib"
ln -s $LIBAPT_PKG_SIM_PATH "$SIM_USR_LIB/libapt-pkg.6.0.dylib"

# fix symbols in libapt
perl -pi -e 's/opendir\$INODE64/opendir\x00\x00\x00\x00\x00\x00\x00\x00/g' $LIBAPT_PKG_SIM_PATH
perl -pi -e 's/readdir\$INODE64/readdir\x00\x00\x00\x00\x00\x00\x00\x00/g' $LIBAPT_PKG_SIM_PATH
ldid -S $LIBAPT_PKG_SIM_PATH
