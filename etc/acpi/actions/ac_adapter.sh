#!/bin/sh

# do nothing if package is removed
PKG=eeepc-acpi-scripts
FUNC_LIB=/usr/share/$PKG/functions.sh
DEFAULT=/etc/default/$PKG
[ -e $FUNC_LIB ] || exit 0

case $(runlevel) in
    *0|*6)
	exit 0
	;;
esac

if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB

. /etc/acpi/lib/notify.sh
code="$3 $4"

case "$code" in
    # AC adapter present
    0000008[01]\ 00000001)
	. /etc/acpi/lib/shengine.sh
	if [ "$SHENGINE_SETTING" = auto ]; then
	    PWR_CLOCK_AC="${PWR_CLOCK_AC:-0}"
	    if [ $(get_shengine -) -gt "$PWR_CLOCK_AC" ]; then
		handle_shengine "$PWR_CLOCK_AC" -
	    fi
	fi
	;;

    # AC adapter not present
    0000008[01]\ 00000000)
	. /etc/acpi/lib/shengine.sh
	if [ "$SHENGINE_SETTING" = auto ]; then
	    PWR_CLOCK_BATTERY="${PWR_CLOCK_BATTERY:-$(($SHENGINE_LIMIT - 1))}"
	    if [ $(get_shengine -) -lt "$PWR_CLOCK_BATTERY" ]; then
		handle_shengine "$PWR_CLOCK_BATTERY" -
	    fi
	fi
	;;

esac
