#!/bin/sh

# do nothing if package is removed
[ -d /usr/share/doc/eeepc-acpi-scripts ] || exit 0

if (runlevel | grep -q [06]) || (pidof '/sbin/shutdown' > /dev/null); then
    exit 0
fi

brn_control=/sys/class/backlight/eeepc/brightness
[ -e $brn_control ] || brn_control=/proc/acpi/asus/brn # pre-2.6.26

brightness=$(cat $brn_control)
pm-suspend --quirk-s3-bios
echo $brightness > $brn_control
