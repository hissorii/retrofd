#!/sbin/busybox sh

# copy /data and /cache from NAND to SD
if [ ! -f /data/rfd_copy_done ]; then

	# delete /data on SDp2
	for files in `busybox ls /data`
	do
		[ -d /data/${files} ] && busybox rm -rf /data/${files}
		[ ${files} = "bootscript.sh" -o ${files} = "retrofd.sh" -o ${files} = "local.prop" ] || busybox rm /data/${files}
	done

	# delete /cache on SDp3
	busybox rm -rf /cache

	busybox mkdir /mnt/tmp_data

	busybox mount /dev/block/mtdblock6 /mnt/tmp_data -t ext4 -o ro
	busybox sleep 1
	busybox cp -pr /mnt/tmp_data/* /data/
	busybox umount /mnt/tmp_data

	busybox mount /dev/block/mtdblock5 /mnt/tmp_data -t ext4 -o ro
	busybox sleep 1
	busybox cp -pr /mnt/tmp_data/* /cache/
	busybox umount /mnt/tmp_data

	busybox touch /data/rfd_copy_done
fi

#echo "log start" > /mnt/ram/log/rfd_log1.txt

# mount SDp1 (fat32)
busybox mkdir /mnt/rfd_sd
/sbin/busybox mount -t vfat /dev/block/mmcblk0p1 /mnt/rfd_sd -o rw 

while ! busybox grep "/mnt/rfd_sd" /proc/mounts > /dev/null
do
	busybox sleep 1
done

do_reboot=0

# copy new files from SDp1 to SDp2
if ! busybox diff /data/retrofd.sh /mnt/rfd_sd/retrofd/retrofd.sh > /dev/null; then
	busybox cp /mnt/rfd_sd/retrofd/retrofd.sh /data/retrofd.sh.new
	busybox chmod 777 /data/retrofd.sh.new
	do_reboot=1
fi
if ! busybox diff /data/local.prop /mnt/rfd_sd/retrofd/local.prop > /dev/null; then
	busybox cp /mnt/rfd_sd/retrofd/local.prop /data/local.prop.new
	busybox chmod 644 /data/local.prop.new
	do_reboot=1
fi

# reboot if replaced retrofd.sh/local.prop
[ "$do_reboot" = "1" ] && /system/bin/reboot

busybox mkdir /rfd_tmp
busybox cp /mnt/rfd_sd/retrofd/rfgui_no_ftm /rfd_tmp/
busybox chmod 777 /rfd_tmp/rfgui_no_ftm
busybox cp /mnt/rfd_sd/retrofd/inst_apk.sh /rfd_tmp/
busybox chmod 777 /rfd_tmp/inst_apk.sh
busybox cp /mnt/rfd_sd/retrofd/rfd_logcd.sh /rfd_tmp/
busybox chmod 777 /rfd_tmp/rfd_logcd.sh

# source config
. /mnt/rfd_sd/retrofd/retrofd.cfg

# delete all files except bootscript.sh/retrofd.sh/local.prop in SDp2/3
# at the next boot time.
if [ "$RF_CLR_SDP23" = "yes" -a ! -f /mnt/rfd_sd/retrofd/rfd_clr_done ]; then
	busybox rm /data/rfd_copy_done
	busybox touch /mnt/rfd_sd/retrofd/rfd_clr_done
	/system/bin/reboot
fi

# overwrite with unpatched(original) files
if [ "$RF_FTM" = "yes" ]; then
	for dex in `busybox find /data/dalvik-cache -name "*[rR]etro[fF]reak*" | busybox grep -iv updater`
	do
		/rfd_tmp/rfgui_no_ftm -r ${dex}
	done
	exit 0
fi

# patch RFGUI dex file to avoid FACTORY TEST MODE
for dex in `busybox find /data/dalvik-cache -name "*[rR]etro[fF]reak*" | busybox grep -iv updater`
do
	/rfd_tmp/rfgui_no_ftm ${dex}
done

# set cpu parameters
busybox echo 20000 > /sys/devices/system/cpu/cpufreq/interactive/timer_rate
busybox echo 20000 > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
busybox echo 1416000 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
busybox echo 70 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
busybox echo 504000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
busybox echo 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
busybox echo interactive > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# fork by nohup (doesn't receive SIGHUP when parent process is dead)
busybox nohup /rfd_tmp/inst_apk.sh &
[ "$RF_LOGCD" = "yes" ] && busybox nohup /rfd_tmp/rfd_logcd.sh &
