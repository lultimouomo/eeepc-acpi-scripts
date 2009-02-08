# eeepc-acpi-scripts notification library
#
# this file is to be sourced

notify() {
    CATEGORY=$1
    MSG=$2
    if [ -n "$4" -o \( -n "$3" -a "$3" != 'fast' \) ]; then
	echo "usage: notify 'category' 'message text' [fast]" > /dev/stderr
	return 1
    fi
    echo "$MSG"  # for /var/log/acpid
    if [ -S /tmp/.X11-unix/X0 ]; then
        detect_x_display

    if [ "x$ENABLE_OSD" = "xno" ]; then
        return
    fi

    OSD_SHOWN=

    # try to show a nice OSD notification via GNOME OSD service
    GOSDC=/usr/bin/gnome-osd-client
    if [ -z "$OSD_SHOWN" ] && [ -x $GOSDC ]; then
	if ps -u $user -o cmd= | grep -q '^/usr/bin/python /usr/bin/gnome-osd-event-bridge'; then
	    if echo "$MSG" | grep -q '[0-9]'; then
		animations='off'
	    else
		animations='on'
	    fi
	    if [ "$3" = 'fast' ]; then
		timeout=150
	    else
		timeout=1200
	    fi
	    echo "<message id='eee-$CATEGORY' osd_fake_translucent_bg='off' osd_vposition='bottom' animations='$animations' hide_timeout='$timeout' osd_halignment='center'>$MSG</message>" \
		| sudo -u $user $GOSDC -s --dbus
	    OSD_SHOWN=1
	fi
    fi

    if [ -z "$OSD_SHOWN" ] && [ -x /usr/bin/aosd_cat ]; then
	killall -q aosd_cat
	if [ "$3" = 'fast' ]; then
		echo "$MSG" | aosd_cat -n "$OSD_FONT" -f 0 -u 150 -o 0 &
	else
		echo "$MSG" | aosd_cat -n "$OSD_FONT" -f 100 -u 1000 -o 100 &
	fi
	OSD_SHOWN=1
    fi

    if [ -z "$OSD_SHOWN" ] && [ -x /usr/bin/dcop ]; then
	dcop --user "$user" knotify Notify notify "notification" "knotify" "$MSG" "" "" 16 2
    fi

    else
	echo "$MSG" > /dev/console
    fi
}

