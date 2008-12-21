#!/bin/sh

# do nothing if package is removed
PKG=eeepc-acpi-scripts
FUNC_LIB=/usr/share/$PKG/functions.sh
DEFAULT=/etc/default/$PKG
[ -e $FUNC_LIB ] || exit 0

if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB

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
        xrandr --output VGA --off --output LVDS --auto
        ;;
    *)
        xrandr --output VGA $VGA_ON --output LVDS $LVDS_OFF
esac

