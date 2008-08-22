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
