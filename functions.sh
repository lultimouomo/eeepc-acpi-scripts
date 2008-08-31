# common eeepc-acpi-scripts functions

# detect the name of the WLAN interface and kernel module
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

detect_x_display()
{
    local user
    local home
    user=$(who | sed -n '/ (:0[\.0]*)$\| :0 /{s/ .*//p;q}')
    if [ "$user" = "" ]; then
        # no users seem to be logged on a X display?
        # try the first logged user without any filters
        # useful for users starting X via 'startx' after logging
        # on the console
        user=$( who | head -n 1 | cut -d' ' -f1 )
    fi
    home=$(getent passwd $user | cut -d: -f6)
    XAUTHORITY=$home/.Xauthority
    if [ -f $XAUTHORITY ]; then
        export XAUTHORITY
        export DISPLAY=:0
    fi
}

BT_CTL=/sys/devices/platform/eeepc/bluetooth
# check if bluetooth is switched on and return success (exit code 0 if it is
# return failure (exit code 1) if it is not
#
# uses the acpi platform driver interface if that is available
# if not, uses hcitool to see if there is a hci0 device
bluetooth_is_on()
{
    if [ -e $BT_CTL ]; then
        [ $( cat $BT_CTL ) = "1" ]
    else
        hcitool dev | grep -q hci0
    fi
}

toggle_bluetooth()
{
    if bluetooth_is_on; then
        if [ -e $BT_CTL ]; then
            echo 0 > $BT_CTL
            # udev should unload the module now
        else
            hciconfig hci0 down
            rmmod hci_usb
        fi
    else
        if [ -e $BT_CTL ]; then
            echo 1 > $BT_CTL
            # udev should load the module now
        else
            modprobe hci_usb
        fi
    fi
}
