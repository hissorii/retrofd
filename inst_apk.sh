#!/system/bin/sh

export PATH=/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
export ANDROID_ROOT=/system
export BOOTCLASSPATH=/system/framework/core.jar:/system/framework/core-junit.jar:/system/framework/bouncycastle.jar:/system/framework/ext.jar:/system/framework/framework.jar:/system/framework/framework2.jar:/system/framework/android.policy.jar:/system/framework/services.jar:/system/framework/apache-xml.jar:/system/framework/filterfw.jar

# wait system_server process
while ! busybox ps | busybox grep system_server | busybox grep -v grep > /dev/null
do
	busybox sleep 1
done

busybox sleep 3

# wait until pm command never fail
while /system/bin/pm list 2>&1 | busybox grep "Could not access" > /dev/null
do
	busybox sleep 1
done

do_reboot=0
for apk in `busybox ls /mnt/rfd_sd/retrofd/install_apk`
do
	/system/bin/pm install /mnt/rfd_sd/retrofd/install_apk/${apk} 2>> /mnt/rfd_sd/retrofd/install_done/inst_err.txt
	busybox mv /mnt/rfd_sd/retrofd/install_apk/${apk} /mnt/rfd_sd/retrofd/install_done/
	do_reboot=1
done

[ "$do_reboot" = "1" ] && /system/bin/reboot

busybox umount /mnt/rfd_sd
