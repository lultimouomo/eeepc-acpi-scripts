#!/bin/sh

# Handles EeePc Super Hybrid Engine
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

case "$1" in
    # AC adapter present
    false)
	. /etc/acpi/lib/shengine.sh
	if shengine_supported && [ "${SHENGINE_SETTING:-auto}" = auto ]; then
	    PWR_CLOCK_AC="${PWR_CLOCK_AC:-0}"
	    if [ $(get_shengine -) -gt "$PWR_CLOCK_AC" ]; then
		handle_shengine "$PWR_CLOCK_AC" -
	    fi
	fi
	;;

    # AC adapter not present
    true)
	. /etc/acpi/lib/shengine.sh
	if shengine_supported && [ "${SHENGINE_SETTING:-auto}" = auto ]; then
	    PWR_CLOCK_BATTERY="${PWR_CLOCK_BATTERY:-$(($SHENGINE_LIMIT - 1))}"
	    if [ $(get_shengine -) -lt "$PWR_CLOCK_BATTERY" ]; then
		handle_shengine "$PWR_CLOCK_BATTERY" -
	    fi
	fi
	;;

esac
