# common eeepc-acpi-scripts functions

# detect which rfkill has name=$1
have_dev_rfkill()
{
  [ -c /dev/rfkill ]
}

if have_dev_rfkill; then
    # detect which rfkill has name=$1
    detect_rfkill()
    {
	# expecting something like
	#   0: eeepc-wlan: Wireless LAN
	RFKILL=''
	if test "$(rfkill list "$1")" != ''; then
	    RFKILL="$1"
	fi
    }

    get_rfkill()
    {
	# simple yes/no, so...
	expr 4 - length "$(rfkill list "$1" | sed -e '/^\tSoft blocked:/! d; s/.*://; q')"
    }

    set_rfkill()
    {
	if [ "$2" = 0 ]; then
	    rfkill block "$1"
	else
	    rfkill unblock "$1"
	fi
    }
else # we have no /dev/rfkill

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

    get_rfkill()
    {
	cat "$1"
    }

    set_rfkill()
    {
	echo "$2" > "$1"
    }
fi

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
    if [ -f "$XAUTHORITY" ]; then
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
        if [ -f "$XAUTHORITY" ]; then
            for ss in xscreensaver gnome-screensaver; do
                [ -x /usr/bin/$ss-command ] \
                    && pidof /usr/bin/$ss > /dev/null \
                    && su - "$user" -c "DISPLAY=$(shell_quote "$DISPLAY") XAUTHORITY=$(shell_quote "$XAUTHORITY") $ss-command --lock"
            done
            # try locking KDE
            if [ -x /usr/bin/dcop ]; then
                dcop --user $user kdesktop KScreensaverIface lock
            fi
            [ -x /usr/bin/xtrlock ] && su - "$user" -c "DISPLAY=$(shell_quote "$DISPLAY") XAUTHORITY=$(shell_quote "$XAUTHORITY") /usr/bin/xtrlock" &
        fi
    fi
}
