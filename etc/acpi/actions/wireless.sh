#!/bin/sh

. /usr/share/eeepc-acpi-scripts/functions.sh

detect_rfkill eeepc-wlan wlan
wlan_control="$RFKILL"

if ! have_dev_rfkill; then
  [ -n "$wlan_control" -a -e $wlan_control ] \
    || wlan_control=/sys/devices/platform/eeepc/wlan # pre-2.6.28
  [ -e "$wlan_control" ] || wlan_control=/proc/acpi/asus/wlan # pre-2.6.26
fi

STATE="$(get_rfkill "$wlan_control")"

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
	    set_rfkill "$wlan_control" 1
            detect_wlan
	    if [ "$WLAN_MOD" = 'ath_pci' ] || [ "$WLAN_MOD" = 'ath5k' ]; then
		# Atheros needs some handholding
		modprobe $WLAN_MOD
		# adding a sleep here, due to some bug the driver loading is not atomic here
		# and could cause ifconfig to fail (at least madwifi, untested with ath5k)
		sleep 1
		if ! ifconfig $WLAN_IF up; then exec $0 off; fi
	    fi
	fi
	;;
    off|disable|0)
	if [ "$STATE" = 1 ]; then
            detect_wlan
	    if [ "$WLAN_MOD" = 'ath_pci' ] || [ "$WLAN_MOD" = 'ath5k' ]; then
		ifdown --force $WLAN_IF
		modprobe -r $WLAN_MOD
	    fi
	    set_rfkill "$wlan_control" 0
	fi
	;;
    *)
	echo "Usage: $0 [on|off|detect]"
	exit 1
	;;
esac
