#!/bin/sh

. /usr/share/eeepc-acpi-scripts/functions.sh

detect_rfkill eeepc-wlan
wlan_control="$RFKILL"

[ -n "$wlan_control" -a -e $wlan_control ] \
    || wlan_control=/sys/devices/platform/eeepc/wlan # pre-2.6.28
[ -e "$wlan_control" ] || wlan_control=/proc/acpi/asus/wlan # pre-2.6.26

STATE="$(cat $wlan_control)"

cmd="$1"
if [ "$cmd" = toggle ]; then
    cmd=$((1-STATE))
fi

case "$cmd" in
    detect)
	exit "$STATE"
	;;
    on|enable|1)
	if [ "$STATE" = 0 ]; then
	    echo 1 > $wlan_control
            wakeup_wicd
	fi
	;;
    off|disable|0)
	if [ "$STATE" = 1 ]; then
	    echo 0 > $wlan_control
	fi
	;;
    *)
	echo "Usage: $0 [on|off|detect]"
	exit 1
	;;
esac
