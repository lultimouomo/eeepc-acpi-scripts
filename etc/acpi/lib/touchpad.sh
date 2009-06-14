# a shell library for handling touchpad toggling
#
# to be sourced

detect_x_display

toggle_touchpad()
{
    local STATE
    STATE="$(synclient -sl | sed -e '/TouchpadOff/! d; s/[^0-9]\+//g')"
    synclient -s TouchpadOff=$((1-STATE))
    return $((1-STATE))
}
