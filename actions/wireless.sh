#!/bin/sh

wlan_control=/sys/devices/platform/eeepc/wlan
[ -e $wlan_control ] || wlan_control=/proc/acpi/asus/wlan # pre-2.6.26

detect_wlan()
{
    if lspci|grep -i 'network controller'|grep -q 'RaLink'; then
        WLAN_IF=ra0
        WLAN_MOD=rt2860sta
    elif lspci|grep -i 'atheros'|grep -q -i 'wireless'; then
        WLAN_IF=ath0
        WLAN_MOD=ath_pci
    fi

    echo "Detected WLAN module $WLAN_MOD on $WLAN_IF" >&2
}

case $1 in
    on|enable)
	if [ $(cat $wlan_control) = 0 ]; then
	    modprobe -r pciehp
	    modprobe pciehp pciehp_force=1
	    echo 1 > $wlan_control
            detect_wlan
	    modprobe $WLAN_MOD
	    # adding a sleep here, due to some bug the driver loading is not atomic here
	    # and could cause ifconfig to fail
	    sleep 1
	    if ! ifconfig $WLAN_IF up; then exec $0 off; fi
	fi
	;;
    off|disable)
	if [ $(cat $wlan_control) = 1 ]; then
            detect_wlan
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
