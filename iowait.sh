#!/bin/bash
##Author Thanassis Zakopoulos
##Usage  ./iowait.sh host_list "seconds to iterate" "iowait threshold"  
##host_list file has to be of format "ip fqdn_hostname"

## if file list is not given echo usage and exit
if [ -z "$1" ]
	then
	echo 'Usage  ./iowait.sh host_list [seconds to iterate] [iowait threshold]'
	exit 1
fi
##if seconds period is not defined default will be 30
SECONDSTOSLEEP=$2
if [ -z "$2" ]
	then SECONDSTOSLEEP=30
fi
##if iowait threshold is not defined default will be 1
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
TMP_LOG1=$SCRIPT_HOME/tmp/aaa.$DATE
TMP_LOG2=$SCRIPT_HOME/tmp/bbb.$DATE
TMP_LOG3=$SCRIPT_HOME/tmp/ccc.$DATE
TMP_LOG4=$SCRIPT_HOME/tmp/last_time_iowait_happened.$DATE
LOG=$SCRIPT_HOME/log."$(echo $1)"
###time script started
start=`date +%s`

cat /dev/null > $TMP_LOG1
cat /dev/null > $TMP_LOG2
##TMP_LOG3 has the current entries of big iowaits
cat /dev/null > $TMP_LOG3
##TMP_LOG4 keeps when last big iowait happened
cat /dev/null > $TMP_LOG4
##before new execution if the script has been executed for a file list again backup old values of big iowaits
if [ -f $LOG ]; then
	mv $LOG $LOG."$DATE"
fi
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

##if file is not zero size that means that a big iowait happened print the time that it happened
if [ -s $TMP_LOG3 ]
	then
		end2=`date +%s`
        	runtime=$((end2-start)) 
		##keep timestamp of last big iowait in a file
		echo "Last big iowait happened $runtime seconds after start" > $TMP_LOG4
fi

##keep all big iowaits inside $LOG file
cat $TMP_LOG3 >> $LOG
##print when last big iowait happened
cat $TMP_LOG4
}

while (true)
do
	##calculate how many seconds script is running
	end=`date +%s`
	runtime=$((end-start))
        echo "Script is running for $runtime seconds"
	##run iowait function
	iowait $1
	##Print how many times since script started server from server list has iowait bigger than threshold (if any)
	if [ -s $LOG ]
        then
	echo "Since script started servers from $1 that had iowait bigger than $IOWAIT_THRESHOLD_PERCENTANCE% are (first collumn is the count):"
	awk '{print $1}' $LOG |sort | uniq -c
	fi
	echo -----------------------------------------
	sleep $SECONDSTOSLEEP
done
