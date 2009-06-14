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

handle_shengine() {
    . /etc/acpi/lib/shengine.sh
    if [ -e "$SHENGINE_CTL" ]; then
	if [ "$1" = '' ]; then
	    cycle_shengine
	else
	    set_shengine "$1"
	fi
	if [ "$2" != '' ]; then return; fi
	case $(get_shengine) in
	    0) notify super_hybrid_engine 'S. H. Engine: Performance'; ;;
	    1) notify super_hybrid_engine 'S. H. Engine: Standard'; ;;
	    2) notify super_hybrid_engine 'S. H. Engine: Power-saving'; ;;
	    255) notify super_hybrid_engine 'S. H. Engine: Automatic'; ;;
	    *) notify error 'S. H. Engine unavailable'
	esac
    else
	notify error 'S. H. Engine unavailable'
    fi
}

case "$code" in
    # AC adapter present
    0000008[01]\ 00000001)
	. /etc/acpi/lib/shengine.sh
	if [ "$SHENGINE_SETTING" = auto ]; then
	    if [ "$PWR_CLOCK_AC" -a $(get_shengine -) -gt "$PWR_CLOCK_AC" ]; then
		handle_shengine "$PWR_CLOCK_AC" -
	    fi
	fi
	;;

    # AC adapter not present
    0000008[01]\ 00000000)
	. /etc/acpi/lib/shengine.sh
	if [ "$SHENGINE_SETTING" = auto ]; then
	    if [ "$PWR_CLOCK_BATTERY" -a $(get_shengine -) -lt "$PWR_CLOCK_BATTERY" ]; then
		handle_shengine "$PWR_CLOCK_BATTERY" -
	    fi
	fi
	;;

esac
