#!/bin/sh

# return: 0 on disconnect, 1 on connected vga, 2 else
getvga_status(){
    STATUS=$( xrandr -q | grep VGA | cut -d ' ' -f 2,3 )
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

getvga_status
# handle return value

