# eeepc-acpi-scripts notification library
#
# this file is to be sourced

notify() {
    CATEGORY=$1
    MSG=$2
    if [ -n "$3" ]; then
	echo "usage: notify 'catgory' 'message text'" > /dev/stderr
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
	    echo "<message id='eee-$CATEGORY' osd_fake_translucent_bg='off' osd_vposition='bottom' animations='$animations' hide_timeout='1200' osd_halignment='center'>$MSG</message>" \
		| sudo -u $user $GOSDC -s --dbus
	    OSD_SHOWN=1
	fi
    fi

    if [ -z "$OSD_SHOWN" ]; then
	killall -q aosd_cat
	if [ -n "$MSG" -a -z "$(echo $MSG | sed 's/.*[0-9]\+//g')" ]; then
		echo "$MSG%" | aosd_cat -f 0 -u 100 -o 0 -n "$OSD_FONT" &
	else
		echo "$MSG" | aosd_cat -n "$OSD_FONT" -f 100 -u 1000 -o 100 &
	fi
    fi
    else
	echo "$MSG" > /dev/console
    fi
}

