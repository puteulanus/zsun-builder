#!/bin/sh
# Copyright (C) 2009-2013 OpenWrt.org

. /lib/functions/leds.sh
. /lib/ar71xx.sh

get_status_led() {
	case $(ar71xx_board_name) in
	zsun-sdreader)
		status_led="zsunsdreader:green:system"
		;;
	esac
}

set_state() {
	get_status_led

	case "$1" in
	preinit)
		status_led_blink_preinit
		;;
	failsafe)
		status_led_blink_failsafe
		;;
	preinit_regular)
		status_led_blink_preinit_regular
		;;
	done)
		status_led_on
		case $(ar71xx_board_name) in
		qihoo-c301)
			local n=$(fw_printenv activeregion | cut -d = -f 2)
			fw_setenv "image${n}trynum" 0
			;;
		esac
		;;
	esac
}
