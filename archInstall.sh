#! /bin/bash

todo() {
	echo "                              "
	echo "         ##  TODO  ##         "
	echo "                              "
	echo "  * partitionate disks        "
	echo "  * format                    "
	echo "  * install                   "
	echo "  * configurate               "
	echo "  * install grub              "
	echo "                              "
}

testInternet() {
	echo "testing internet..."
	ping -c 4 8.8.8.8 &> /dev/null 

	if [ "$?" == "0" ]
	then
		echo "internet: ok     "
		echo "                 "
	else
		echo "internet: not working"
		echo "                     "
		echo "Error: You must fist connect to internet..."	
		exit 1
	fi
}

updateSystemClock() {
	echo "updating system clock..."
	timedatectl set-ntp true

	echo "clock: ok               "
	echo "                        "
}
 
main () {
	testInternet
	updateSystemClock

	todo
}

main
