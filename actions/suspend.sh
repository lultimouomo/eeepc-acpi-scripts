#!/bin/sh

if (runlevel | grep -q [06]) || (ps x | grep -q '/sbin/shutdown'); then
    exit 0
fi

brn_control=/proc/acpi/asus/brn

brightness=$(cat $brn_control)
pm-suspend --quirk-s3-bios
echo $brightness > $brn_control
