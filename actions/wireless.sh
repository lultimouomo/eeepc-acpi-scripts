#!/bin/sh

WLAN_IF=ath0
WLAN_MOD=ath_pci

DEFAULT=/etc/default/eee-acpi-scripts
if [ -r $DEFAULT ]; then
    . $DEFAULT
fi

wlan_control=/sys/devices/platform/eeepc/wlan
[ -e $wlan_control ] || wlan_control=/proc/acpi/asus/wlan # pre-2.6.26

case $1 in
    on|enable)
	if [ $(cat $wlan_control) = 0 ]; then
	    modprobe -r pciehp
	    modprobe pciehp pciehp_force=1
	    echo 1 > $wlan_control
	    modprobe $WLAN_MOD
	    # adding a sleep here, due to some bug the driver loading is not atomic here
	    # and could cause ifconfig to fail
	    sleep 1
	    if ! ifconfig $WLAN_IF up; then exec $0 off; fi
	fi
	;;
    off|disable)
	if [ $(cat $wlan_control) = 1 ]; then
	    ifdown --force $WLAN_IF
	    modprobe -r $WLAN_MOD
	    echo 0 > $wlan_control
	fi
	;;
    *)
	echo "Usage: $0 [on|off]"
	exit 1
	;;
esac
