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

CAM_CTL=/sys/devices/platform/eeepc/camera
[ -e $CAM_CTL ] || CAM_CTL=/proc/acpi/asus/camera #pre-2.6.26
# check if camera is enabled and return success (exit code 0 if it is
# return failure (exit code 1) if it is not
#
# uses the acpi platform driver interface if that is available
# if not, assume there is not camera and return false
camera_is_on()
{
    if [ -e $CAM_CTL ]; then
        [ $( cat $CAM_CTL ) = "1" ]
    else
        false
    fi
}

toggle_camera()
{
    if camera_is_on; then
        echo 0 > $CAM_CTL
    else
        if [ -e $CAM_CTL ]; then
            echo 1 > $CAM_CTL
        fi
    fi
}
