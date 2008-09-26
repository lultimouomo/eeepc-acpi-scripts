#!/bin/sh

# do nothing if package is removed
[ -d /usr/share/doc/eeepc-acpi-scripts ] || exit 0

. /etc/default/eeepc-acpi-scripts
. /usr/share/eeepc-acpi-scripts/functions.sh

# return: 0 on disconnect, 1 on connected vga, 2 else
getvga_status(){
    STATUS=$( xrandr -q | grep VGA | cut -d ' ' -f 2,3 )
    case "$STATUS" in
    disconnected*)
        return 0
        ;;
    connected\ \(*)
        return 1
        ;;
    *)
        return 2
        ;;
    esac
}

detect_x_display
getvga_status;
# handle return value
case $? in
    2)
        xrandr --output VGA --off
        ;;
    *)
        xrandr --output VGA $COMBINED_DISPLAY_SWITCHES
esac

