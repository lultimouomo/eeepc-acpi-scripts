# common eeepc-acpi-scripts functions

# detect the name of the WLAN interface and kernel module
detect_wlan()
{
    if lspci|grep -i 'network controller'|grep -q 'RaLink'; then
        WLAN_IF=ra0
        WLAN_MOD=rt2860sta
    elif lspci|grep -i 'atheros'|grep -q -i 'wireless'; then
        if lspci -v|grep -q -i 'ath_pci'; then
            WLAN_IF=ath0
            WLAN_MOD=ath_pci
        else
            WLAN_IF=wlan0
            WLAN_MOD=ath5k
        fi
    fi

    echo "Detected WLAN module $WLAN_MOD on $WLAN_IF" >&2
}

# detect which rfkill has name=$1
detect_rfkill()
{
    local _rfkill
    for _rfkill in /sys/class/rfkill/*; do
        if [ -f "$_rfkill/name" ] && [ "$(cat "$_rfkill/name")" = "$1" ]; then
            echo "Detected $1 as rfkill $_rfkill" >&2
            RFKILL="$_rfkill/state"
            return
        fi
    done
    RFKILL=''
}

detect_x_display()
{
    local _user
    local _home
    _user=$(who | sed -n '/ (:0[\.0]*)$\| :0 /{s/ .*//p;q}')
    if [ "$_user" = "" ]; then
        # no users seem to be logged on a X display?
        # try the first logged user without any filters
        # useful for users starting X via 'startx' after logging
        # on the console
        #_user=$( who | head -n 1 | cut -d' ' -f1 )
        _user=$(ps -o pid= -t tty$(fgconsole) | sed -e 's/^\s\+//g' | cut -d' ' -f1)
        if [ "${_user}" != '' ]; then
            eval $(sed -e 's/\x00/\n/g' /proc/${_user}/environ | grep '^\(DISPLAY\|XAUTHORITY\)=' | sed -e "s/'/'\\\\''/g; s/=/='/; s/$/'/")
            DISPLAY="${DISPLAY:-:0}"
            export XAUTHORITY
            export DISPLAY
            user=root
            home=$(getent passwd $_user | cut -d: -f6)
        fi
        return
    fi
    _home=$(getent passwd $_user | cut -d: -f6)
    XAUTHORITY=$_home/.Xauthority
    if [ -f $XAUTHORITY ]; then
        export XAUTHORITY
        export DISPLAY=:0
        user=$_user
        home=$_home
    fi
}

shell_quote()
{
  echo "$1" | sed -e 's/'\''/'\''\\'\'''\''/g; s/^/'\''/; s/$/'\''/; $! s/$/\\/'
}

lock_x_screen()
{
    # activate screensaver if available
    if [ -S /tmp/.X11-unix/X0 ]; then
        detect_x_display
        if [ -f $XAUTHORITY ]; then
            for ss in xscreensaver gnome-screensaver; do
                [ -x /usr/bin/$ss-command ] \
                    && pidof /usr/bin/$ss > /dev/null \
                    && $ss-command --lock
            done
            # try locking KDE
            if [ -x /usr/bin/dcop ]; then
                dcop --user $user kdesktop KScreensaverIface lock
            fi
            [ -x /usr/bin/xtrlock ] && su - "$user" -c "DISPLAY=$(shell_quote "$DISPLAY") XAUTHORITY=$(shell_quote "$XAUTHORITY") /usr/bin/xtrlock" &
        fi
    fi
}
