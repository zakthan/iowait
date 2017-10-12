#!/bin/bash
##Author Thanassis Zakopoulos
##Usage  ./iowait.sh host_list "seconds to iterate" "iowait threshold"  &
##host_list file has to be of format "ip fqdn_hostname"

##if seconds period is not defined default will be 30
SECONDS=$2
if [ -z "$2" ]
	then SECONDS=30
fi
IOWAIT_THRESHOLD_PERCENTANCE=$3
if [ -z "$3" ]
then IOWAIT_THRESHOLD_PERCENTANCE=1
fi
SCRIPT_HOME=/root/scripts/iowait
YEAR=`date '+%Y'`
MONTH=`date '+%m'`
DAY=`date '+%d'`
HOUR=`date '+%H'`
MINUTE=`date '+%M'`
SECOND=`date '+%S'`
DATE=$YEAR.$MONTH.$DAY.$HOUR.$MINUTE.$SECOND
TMP_LOG1=$SCRIPT_HOME/aaa.$DATE
TMP_LOG2=$SCRIPT_HOME/bbb.$DATE
TMP_LOG3=$SCRIPT_HOME/ccc.$DATE
LOG=$SCRIPT_HOME/log."$(echo $1)"

cat /dev/null > $TMP_LOG1
cat /dev/null > $TMP_LOG2
cat /dev/null > $TMP_LOG3
mv $LOG $LOG."$DATE"
cat /dev/null > $LOG

function iowait () {
	IP_LIST=$(awk '{ print $1}' $1)
	HOST_LIST=$(awk '{ print $2}' $1)

#debug#echo $IP_LIST
##echo ---------
#debug#echo $HOST_LIST

##for all the servers of HOST_LIST take a sar sample
for HOST in $HOST_LIST
                do
			ssh $HOST "hostname;sar 1 1" 2>/dev/null|egrep -v "Linux|Average|Warning|CPU" |tr "\n" " " >> $TMP_LOG1
			echo "  "  >> $TMP_LOG1 
                done 

##if iowait for a server is more than IOWAIT_THRESHOLD_PERCENTANCE keep all these values for ALL servers in  TMP_LOG3
awk -v var="$IOWAIT_THRESHOLD_PERCENTANCE" '{ print ($8 > var ) ? $0 : "false" }' $TMP_LOG1  > $TMP_LOG2
egrep -v false $TMP_LOG2 > $TMP_LOG3 
cat $TMP_LOG3 >> $LOG
}

while (true)
do
	iowait $1
	clear
	awk '{print $1}' $LOG |sort | uniq -c
	sleep $SECONDS
done
