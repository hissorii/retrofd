#!/sbin/busybox sh

#mkdir /mnt/ram/log
#echo "log start" > /mnt/ram/log/rfd_log.txt

# if new file exists, use it
if [ -f /data/retrofd.sh.new ]; then
	busybox rm -f /data/retrofd.sh
	busybox mv /data/retrofd.sh.new /data/retrofd.sh
fi
if [ -f /data/local.prop.new ]; then
	busybox rm -f /data/local.prop
	busybox mv /data/local.prop.new /data/local.prop
fi

busybox sh /data/retrofd.sh
