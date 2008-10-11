# a shell library for handling Bluetooth on Asus EeePC
#
# to be sourced

BT_CTL=/sys/devices/platform/eeepc/bluetooth
[ -e $BT_CTL ] || BT_CTL=/proc/acpi/asus/bluetooth # pre-2.6.26
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
        if [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
            hcitool dev | grep -q hci0
        else
            false
        fi
    fi
}

toggle_bluetooth()
{
    if bluetooth_is_on; then
        if [ -e $BT_CTL ]; then
            echo 0 > $BT_CTL
            # udev should unload the module now
        elif [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
            hciconfig hci0 down
            rmmod hci_usb
            # TODO: enable autosuspend of the USB device
            # that is, echo "auto" > /sys/bus/usb/devices/$DEV/power/level
            # the problem is determining what the right $DEV is
        fi
    else
        if [ -e $BT_CTL ]; then
            echo 1 > $BT_CTL
            # udev should load the module now
        elif [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
            modprobe hci_usb
        fi
    fi
}
