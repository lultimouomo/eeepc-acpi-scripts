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
    local _user
    local _home
    _user=$(who | sed -n '/ (:0[\.0]*)$\| :0 /{s/ .*//p;q}')
    if [ "$_user" = "" ]; then
        # no users seem to be logged on a X display?
        # try the first logged user without any filters
        # useful for users starting X via 'startx' after logging
        # on the console
        _user=$( who | head -n 1 | cut -d' ' -f1 )
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
