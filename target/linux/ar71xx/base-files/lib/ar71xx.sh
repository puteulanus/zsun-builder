#
# Copyright (C) 2009-2011 OpenWrt.org
#

AR71XX_BOARD_NAME=
AR71XX_MODEL=

ar71xx_get_mtd_offset_size_format() {
	local mtd="$1"
	local offset="$2"
	local size="$3"
	local format="$4"
	local dev

	dev=$(find_mtd_part $mtd)
	[ -z "$dev" ] && return

	dd if=$dev bs=1 skip=$offset count=$size 2>/dev/null | hexdump -v -e "1/1 \"$format\""
}

ar71xx_get_mtd_part_magic() {
	local mtd="$1"
	ar71xx_get_mtd_offset_size_format "$mtd" 0 4 %02x
}

wndr3700_board_detect() {
	local machine="$1"
	local magic
	local name

	name="wndr3700"

	magic="$(ar71xx_get_mtd_part_magic firmware)"
	case $magic in
	"33373030")
		machine="NETGEAR WNDR3700"
		;;
	"33373031")
		# Use awk to remove everything after the first zero byte
		model="$(ar71xx_get_mtd_offset_size_format art 41 32 %c | awk 'BEGIN{FS="[[:cntrl:]]"} {print $1; exit}')"
		case $model in
		$'\xff'*)
			if [ "${model:24:1}" = 'N' ]; then
				machine="NETGEAR WNDRMAC"
			else
				machine="NETGEAR WNDR3700v2"
			fi
			;;
		'29763654+16+64'*)
			machine="NETGEAR ${model:14}"
			;;
		'29763654+16+128'*)
			machine="NETGEAR ${model:15}"
			;;
		*)
			# Unknown ID
			machine="NETGEAR $model"
		esac
	esac

	AR71XX_BOARD_NAME="$name"
	AR71XX_MODEL="$machine"
}

cybertan_get_hw_magic() {
	local part

	part=$(find_mtd_part firmware)
	[ -z "$part" ] && return 1

	dd bs=8 count=1 skip=0 if=$part 2>/dev/null | hexdump -v -n 8 -e '1/1 "%02x"'
}

tplink_get_hwid() {
	local part

	part=$(find_mtd_part firmware)
	[ -z "$part" ] && return 1

	dd if=$part bs=4 count=1 skip=16 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

tplink_get_mid() {
	local part

	part=$(find_mtd_part firmware)
	[ -z "$part" ] && return 1

	dd if=$part bs=4 count=1 skip=17 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

tplink_board_detect() {
	local model="$1"
	local hwid
	local hwver

	hwid=$(tplink_get_hwid)
	mid=$(tplink_get_mid)
	hwver=${hwid:6:2}
	hwver="v${hwver#0}"

	case "$hwid" in
	"015000"*)
		model="EasyLink EL-M150"
		;;
	*)
		hwver=""
		;;
	esac

	AR71XX_MODEL="$model $hwver"
}

tplink_pharos_get_model_string() {
	local part
	part=$(find_mtd_part 'product-info')
	[ -z "$part" ] && return 1

	# The returned string will end with \r\n, but we don't remove it here
	# to simplify matching against it in the sysupgrade image check
	dd if=$part bs=1 skip=4360 2>/dev/null | head -n 1
}

tplink_pharos_board_detect() {
	local model_string="$(tplink_pharos_get_model_string | tr -d '\r')"
	local oIFS="$IFS"; IFS=":"; set -- $model_string; IFS="$oIFS"
	local model

	case "$1" in
	'CPE210(TP-LINK|UN|N300-2)')
		model='TP-Link CPE210'
		;;
	'CPE220(TP-LINK|UN|N300-2)')
		model='TP-Link CPE220'
		;;
	'CPE510(TP-LINK|UN|N300-5)')
		model='TP-Link CPE510'
		;;
	'CPE520(TP-LINK|UN|N300-5)')
		model='TP-Link CPE520'
		;;
	esac

	[ -n "$model" ] && AR71XX_MODEL="$model v$2"
}

gl_inet_board_detect() {
	local size="$(mtd_get_part_size 'firmware')"

	case "$size" in
	8192000)
		AR71XX_MODEL='GL-iNet 6408A v1'
		;;
	16580608)
		AR71XX_MODEL='GL-iNet 6416A v1'
		;;
	esac
}

ar71xx_board_detect() {
	local machine
	local name

	machine=$(awk 'BEGIN{FS="[ \t]+:[ \t]"} /machine/ {print $2}' /proc/cpuinfo)

	case "$machine" in
	*"ZSUN WiFi SD Card Reader")
		name="zsun-sdreader"
		;;
	esac

	[ -z "$AR71XX_MODEL" ] && [ "${machine:0:8}" = 'TP-LINK ' ] && \
		tplink_board_detect "$machine"

	[ -z "$name" ] && name="unknown"

	[ -z "$AR71XX_BOARD_NAME" ] && AR71XX_BOARD_NAME="$name"
	[ -z "$AR71XX_MODEL" ] && AR71XX_MODEL="$machine"

	[ -e "/tmp/sysinfo/" ] || mkdir -p "/tmp/sysinfo/"

	echo "$AR71XX_BOARD_NAME" > /tmp/sysinfo/board_name
	echo "$AR71XX_MODEL" > /tmp/sysinfo/model
}

ar71xx_board_name() {
	local name

	[ -f /tmp/sysinfo/board_name ] && name=$(cat /tmp/sysinfo/board_name)
	[ -z "$name" ] && name="unknown"

	echo "$name"
}
