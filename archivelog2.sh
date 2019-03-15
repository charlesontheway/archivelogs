#!/bin/bash
#Flush container's logs when the logs dir size larger than 3GB and archive logs to a backup dir
# Author:Neo
# Email:474183554@qq.com
# Updated:2019-03-15

# LOGSPATH=("/home/docker_data/gmxx/.pm2/logs" "/home/docker_data/gmxx/kafka2es/.pm2/logs" "/var/node/apps/gmxx/logs" "/var/node/apps/mobile/logs" "/var/node/apps/gmxxApi/logs" "/home/docker_data/gmxx/mobile/.pm2/logs")
LOGSPATH=("/var/lib/docker/containers" "/home/docker_data/csgaServer/.pm2/logs" "/var/log/docker")
LOGS_BAK="/home/logsbak"

[ ! -d $LOGS_BAK ] && mkdir -p $LOGS_BAK

for f in ${LOGSPATH[@]}; do
    LOGS="$f"
    LOGSIZE=`du -shm $LOGS | awk '{print $1}'`
    [ ! -e $LOGS ] && continue

    if [ $LOGSIZE -ge 3072 ]; then
        cd `dirname $LOGS`
        if [[ -d $LOGS ]]; then
            BAKNAME="bak`basename $(pwd)`_`date  +%Y%m%d%H%M%S`_logs.tar.gz"
            cd $LOGS
            tar -czf "${LOGS_BAK}/${BAKNAME}" .
        else
            BAKNAME="bak`basename ${LOGS}`_`date  +%Y%m%d%H%M%S`_logs.tar.gz"
            tar -czf "${LOGS_BAK}/${BAKNAME}" $LOGS
        fi
#If the logs dir is .pm2 logs dir, then run "pm2 flush" to flush logs
#        echo $LOGS | grep -q "\.pm2" && pm2 flush
#        rm -Rf $LOGS/*
        if [ -f $LOGS ]; then 
            truncate -s 0 $LOGS
        else
		    echo $LOGS | grep -q -i freeswitch
			if [ $? == 0 ]; then
			    find $LOGS -maxdepth 1 -type f -iname "freeswitch.log*" -exec cp -f /dev/null '{}' \;
			else
                find $LOGS -maxdepth 2 -type f -iname "*log" -exec cp -f /dev/null '{}' \;
			fi
        fi
    fi
done
find -L ${LOGS_BAK} -mtime +6 -type f -name "*_logs.tar.gz" -exec rm -f '{}' \;
