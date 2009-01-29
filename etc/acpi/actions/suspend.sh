#!/bin/sh

# do nothing if package is removed
FUNC_LIB=/usr/share/eeepc-acpi-scripts/functions.sh
[ -e $FUNC_LIB ] || exit 0

. /etc/default/eeepc-acpi-scripts
. $FUNC_LIB

if (runlevel | grep -q [06]) || (pidof '/sbin/shutdown' > /dev/null); then
    exit 0
fi

if [ "$LOCK_SCREEN_ON_SUSPEND" = "yes" ]; then
    lock_x_screen
fi

brn_control=/sys/class/backlight/eeepc/brightness
[ -e $brn_control ] || brn_control=/proc/acpi/asus/brn # pre-2.6.26

brightness=$(cat $brn_control)

# Setting defaults in case /etc/default/eeepc-acpi-scripts was not updated
if [ -z "$SUSPEND_METHOD" ]; then
    SUSPEND_OPTIONS=--quirk-s3-bios
fi
if [ -z "$(which "$SUSPEND_METHOD")" ]; then
    SUSPEND_METHOD=pm-suspend
fi

$SUSPEND_METHOD $SUSPEND_OPTIONS

echo $brightness > $brn_control
