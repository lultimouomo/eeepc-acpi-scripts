#!/bin/sh

# do nothing if package is removed
[ -d /usr/share/doc/eeepc-acpi-scripts ] || exit 0

if (runlevel | grep -q [06]) || (pidof '/sbin/shutdown' > /dev/null); then
    exit 0
fi

[ -r /etc/default/eeepc-acpi-scripts ] && . /etc/default/eeepc-acpi-scripts

if [ "$LOCK_SCREEN_ON_SUSPEND" = "yes" ]; then
    # activate screensaver if available
    if [ -S /tmp/.X11-unix/X0 ]; then
        export DISPLAY=:0
        user=$(who | sed -n '/ (:0[\.0]*)$\| :0 /{s/ .*//p;q}')
        home=$(getent passwd $user | cut -d: -f6)
        XAUTHORITY=$home/.Xauthority
        if [ -f $XAUTHORITY ]; then
            export XAUTHORITY
            for ss in xscreensaver gnome-screensaver; do
                [ -x /usr/bin/$ss-command ] \
                    && pidof /usr/bin/$ss > /dev/null \
                    && $ss-command --lock
            done
        fi
    fi
fi

brn_control=/sys/class/backlight/eeepc/brightness
[ -e $brn_control ] || brn_control=/proc/acpi/asus/brn # pre-2.6.26

brightness=$(cat $brn_control)
pm-suspend --quirk-s3-bios
echo $brightness > $brn_control
