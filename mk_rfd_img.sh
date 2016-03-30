#!/bin/sh

case "$1" in
  8GB)
	ddcnt=7800
	p2s=6000
	p3s=7500
	;;
  16GB)
	ddcnt=15800
	p2s=14000
	p3s=15500
	;;
  32GB)
	ddcnt=31800
	p2s=30000
	p3s=31500
	;;
  *)
	echo "Usage: sudo ./mk_rfd_img.sh {8GB|16GB|32GB}"
	exit 1
esac

dd if=/dev/zero of=rfd.img bs=1MB count=${ddcnt}
parted -s rfd.img mklabel msdos
parted -s rfd.img mkpart primary fat32 0 ${p2s}M
parted -s rfd.img mkpart primary ext4 ${p2s}M ${p3s}M
parted -s rfd.img mkpart primary ext4 ${p3s}M ${ddcnt}M

echo -n 'RETRON5___BOOTSD' | dd of=rfd.img conv=notrunc

for pn in 1 2 3
do
	sec=`LANG=C file -k rfd.img | sed 's/.*partition '${pn}': ID=0x[0-9a-f]*, starthead [0-9]*, startsector \([0-9]*\), \([0-9]*\) sectors.*/\1,\2/'`
	ss=`echo $sec | cut -d',' -f1,1` # start sector
	sl=`echo $sec | cut -d',' -f2,2` # sector length

	echo $ss
	echo $sl
	losetup /dev/loop${pn} rfd.img -o $(($ss*512)) --sizelimit $(($sl*512))

	[ $pn = "1" ] && fs=vfat || fs=ext4
	mkfs -t ${fs} /dev/loop${pn}
	mkdir /mnt/rfd_tmp
	mount /dev/loop${pn} /mnt/rfd_tmp

	case "$pn" in
	  1)
		mkdir /mnt/rfd_tmp/retrofd
		mkdir /mnt/rfd_tmp/retrofd/log
		mkdir /mnt/rfd_tmp/retrofd/install_apk
		mkdir /mnt/rfd_tmp/retrofd/install_done
		cp -p *.sh retrofd.cfg local.prop* rfgui_no_ftm /mnt/rfd_tmp/retrofd
		;;
	  2)
		cp -p bootscript.sh retrofd.sh local.prop /mnt/rfd_tmp
		chmod 777 /mnt/rfd_tmp/*.sh
		chmod 644 /mnt/rfd_tmp/local.prop
		;;
	  3)
		;;
	  *)
		exit 1
	esac

	umount /mnt/rfd_tmp
	losetup -d /dev/loop${pn}
done
