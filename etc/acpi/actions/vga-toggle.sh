#!/bin/sh

# do nothing if package is removed
PKG=eeepc-acpi-scripts
FUNC_LIB=/usr/share/$PKG/functions.sh
DEFAULT=/etc/default/$PKG
[ -e "$FUNC_LIB" ] || exit 0

if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB

# return: 0 on disconnect, 1 on connected vga, 2 else
# set VGA (and LVDS) to the output name, VGA or VGA1 (LVDS or LVDS1)
getvga_status(){
    STATUSLINE=$( xrandr -q | grep VGA)
    STATUS=$( echo $STATUSLINE | cut -d ' ' -f 2,3 )
    VGA=$( echo $STATUSLINE | cut -d ' ' -f 1 )
    # To not call xrandr again
    NUM=${VGA##VGA}
    LVDS=LVDS$NUM
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
    1)
        xrandr --output $VGA ${VGA_ON:---auto} --output $LVDS ${LVDS_OFF:---off}
        ;;
    *)
        xrandr --output $VGA --off --output $LVDS --auto
esac

