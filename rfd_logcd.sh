#!/sbin/busybox sh

while ! busybox grep "/mnt/external_sd" /proc/mounts > /dev/null
do
	busybox sleep 1
done

# copy log files(/mnt/ram/log/*) to SD(/retrofd/log) if new ones exist
srcd=/mnt/ram/log   
dstd=/mnt/external_sd/retrofd/log   
while : ;
do
	busybox find $srcd -maxdepth 1 -type f | busybox sed -e 's/.*\///' | while read logfile
	do
		[ -f "$dstd/$logfile" ] || busybox cp "$srcd/$logfile" $dstd/
	done
	busybox sleep 1
done
