#!/bin/sh

brn_control=/proc/acpi/asus/brn

brightness=$(cat $brn_control)
pm-suspend --quirk-s3-bios
echo $brightness > $brn_control
