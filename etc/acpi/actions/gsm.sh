#!/bin/sh

# do nothing if package is removed
PKG=eeepc-acpi-scripts
FUNC_LIB=/usr/share/$PKG/functions.sh
[ -e $FUNC_LIB ] || exit 0

. $FUNC_LIB

# first try kernel rfkill
detect_rfkill eeepc-wwan3g
if [ -n "$RFKILL" ]; then
    if echo `cat $RFKILL` > $RFKILL 2> /dev/null; then
        gsm_control="$RFKILL"
        gsm_on=1
        gsm_off=0
    fi
fi

# then try USB
if [ -z "$gsm_control" ]; then
    for f in /sys/bus/usb/devices/*; do
	if [ -f "$f/product" ] && grep -q '^HUAWEI Mobile' $f/product; then
            gsm_control="$f/power/level"
            gsm_on=auto
            gsm_off=suspend
            break
	fi
    done
fi

# give up if no method to toggle GSM was found
if [ -z "$gsm_control" ]; then
    echo "GSM control not found."
    exit 1
fi

case "$1" in
    detect)
        if [ `cat "$gsm_control"` != "$gsm_off" ]; then
            exit 1
        else
            exit 0
        fi
	;;
    toggle)
        if [ `cat "$gsm_control"` != "$gsm_off" ]; then
            echo "$gsm_off" > "$gsm_control"
        else
            echo "$gsm_on" > "$gsm_control"
        fi        
        ;;
    on|enable|1)
        echo "$gsm_on" > "$gsm_control"
	;;
    off|disable|0)
        echo "$gsm_off" > "$gsm_control"
	;;
    *)
	echo "Usage: $0 [on|off|detect|toggle]"
	exit 1
	;;
esac

