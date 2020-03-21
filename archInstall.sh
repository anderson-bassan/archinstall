#! /bin/bash

todo() {
	echo "                              "
	echo "         ##  TODO  ##         "
	echo "                              "
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

listDisks () {
	disks=($(lsblk | grep -oP '(sd[a-zA-Z]+)'))
	echo ${disks[*]}
}

deleteDisk () {
	echo "cleaning the disk..."

	disk=$1
	partitionsNumbers=$(echo "p" | fdisk $(echo "/dev/${disk}") | grep -oP '(/dev/sd[a-z]+[0-9]+)' | grep -oP '[0-9]+')
	for partition in $partitionsNumbers
	do
		(echo "d"; echo $partition; echo "w";) |  fdisk $(echo "/dev/$(echo $disk)") >& /dev/null

	done

	echo "disk: ok            "
	echo "                    "
}

makeSwap () {
	disk=$1
	read -p "swap size [GB]: " swap_size

	echo "                          "
	echo "creating swap partition..."

	(echo "n"; echo "e"; echo " "; echo " "; echo "+${swap_size}G"; echo "t"; echo "82"; echo "w") | fdisk $(echo "/dev/${disk}") >& /dev/null
	swap_partition=$((echo "p") | fdisk $(echo "/dev/${disk}") | grep swap | grep -oP '(/dev/sd[a-z]+[0-9]+)')	
	mkswap $(echo $swap_partition) >& /dev/null
	swapon $(echo $swap_partition) >& /dev/null

	echo "swap: ok                   "
	echo "                           "
}

makeExt4 () {
	disk=$1

	echo "                          "
	echo "creating arch partition..."

	(echo "n"; echo "p"; echo " "; echo " "; echo " "; echo "w") | fdisk $(echo "/dev/${disk}") >& /dev/null
	mkfs.ext4 $((echo "p") | fdisk $(echo "/dev/${disk}") | grep "83 Linux" | grep -oP '(/dev/sd[a-z]+[0-9]+)') >& /dev/null

	echo "arch partition: ok        "
	echo "                          "
}

formatDisk () {
	disks=$(listDisks)
	if [ ${#disks[@]} -eq 1 ]
	then
		disk=${disks[0]}
	else
		echo "chose the disk:"
		for i in ${!disks[@]};do
			echo "    [${i}] ${disks[i]}"
		done

		echo " "
		read -p "disk[0|1|n]: " diskNumber
		disk=$(echo "${disks[$diskNumber]}")
	
	fi

	deleteDisk $disk

	read -p "make swap on the hd?[y/n] " make_swap
	if [ "$make_swap" == "y" ]
	then
		makeSwap $disk

	fi

	makeExt4 $disk
	
}

installArch () {	
	echo "installing software..."
	echo "                      "
	archPartition=$((echo "p") | fdisk $(echo "/dev/${disk}") | grep "83 Linux" | grep -oP '(/dev/sd[a-z]+[0-9]+)')
	mount $(echo $archPartition) /mnt
	pacstrap /mnt base linux linux-firmware nano vi vim iputils dhcpcd sudo
	echo "software: ok          "
	echo "                      "
}
 
postConfig () {
	echo "configurating the system..."
	echo "                           "
	genfstab -U /mnt >> /mnt/etc/fstab
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
	arch-chroot /mnt hwclock --systohc
	echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	arch-chroot /mnt locale-gen
	echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
	echo "KEYMAP=de-latin1" > /mnt/etc/vconsole.conf
	echo "k-arla" > /mnt/etc/hostname
	echo "127.0.0.1		localhost" > /mnt/etc/hosts
	echo "::1			localhost" >> /mnt/etc/hosts
	echo "127.0.1.1		k-arla.com k-arla" >> /mnt/etc/hosts

	echo "configuration: ok          "
	echo "                           "

}

grubInstall () {
	echo "installing grub..."
	echo "                  "

	arch-chroot /mnt grub-install --target=i386-pc $(echo "/dev/${disk}")
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

	echo "grub: ok          "
	echo "                  "
}

addUser () {
	read -p "your username: " username
	
	arch-chroot /mnt groupadd sudo
	arch-chroot /mnt useradd -m -G sudo $username
	echo "%sudo ALL=(ALL) ALL" >> /mnt/etc/sudoers
}

rootPass () {
	chroot /mnt passwd
}

main () {
	#testInternet
	#updateSystemClock
	#formatDisk
	#installArch
	#postConfig
	#grubInstall
	#addUser
	rootPass

	todo
}

main
