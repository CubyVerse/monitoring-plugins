#!/bin/sh

# Source: https://exchange.nagios.org/directory/Plugins/System-Metrics/Uptime/check_uptime3/details

#######################################################################
# Dmitry Vayntrub 03/11/2009
#
# The plugin shows the uptime and optionally
# compares it against MIN and MAX uptime thresholds
#
# Revision History:
#	v 1.06 - Performance Data added by Tony Yarusso on Jan 27, 2011.
#	v 1.05 - Bugfix added by Peter Lecki on July 28, 2010.
#	v 1.04 - posted by Dmitry Vayntrub Mar 11, 2009 on Nagios Exchange.
#
#######################################################################
VERSION="check_uptime v1.06"

# Exit-Codes:
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage()
{
cat << EOF
usage: $0 [-c OPTION]|[-w OPTION] [-C OPTION]|[-W OPTION] [ -V ]

This script checks uptime and optionally verifies if the uptime
is below MINIMUM or above MAXIMUM uptime treshholds

OPTIONS:
   -h   Help
   -c   CRITICAL MIN uptime (minutes)
   -w   WARNING  MIN uptime (minutes)
   -C   CRITICAL MAX uptime (minutes)
   -W   WARNING  MAX uptime (minutes)
   -V   Version
EOF
}

while getopts c:w:C:W:Vv OPTION
do
     case $OPTION in
	c)
	   MIN_CRITICAL=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	   ;;
	w)
	   MIN_WARNING=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	   ;;
	C)
	   MAX_CRITICAL=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	   ;;
	W)
	   MAX_WARNING=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	  ;;
	V)
	   echo $VERSION
	   exit $STATE_OK
	   ;;
	v)
	   VERBOSE=1
	   ;;
	?)
	   usage
	   exit $STATE_UNKNOWN
	   ;;
     esac
done


UPTIME_REPORT=`uptime | tr -d ","`

if	echo $UPTIME_REPORT | grep -i day > /dev/null ; then

	if	echo $UPTIME_REPORT | grep -i "min" > /dev/null ; then

		DAYS=`echo $UPTIME_REPORT | awk '{ print $3 }'`
		MINUTES=`echo $UPTIME_REPORT | awk '{ print $5}'`

	else
		DAYS=`echo $UPTIME_REPORT | awk '{ print $3 }'`
		HOURS=`echo $UPTIME_REPORT | awk '{ print $5}' | cut -f1 -d":"`
		MINUTES=`echo $UPTIME_REPORT | awk '{ print $5}' | cut -f2 -d":"`
	fi

elif	#in AIX 5:00 will show up as 5 hours, and in Solaris 2.6 as 5 hr(s)
	echo $UPTIME_REPORT | egrep -e "hour|hr\(s\)" > /dev/null ; then
	HOURS=`echo $UPTIME_REPORT | awk '{ print $3}'`
else
	echo $UPTIME_REPORT | awk '{ print $3}' | grep ":" > /dev/null && \
	HOURS=`echo $UPTIME_REPORT | awk '{ print $3}' | cut -f1 -d":"`
	MINUTES=`echo $UPTIME_REPORT | awk '{ print $3}' | cut -f2 -d":"`
fi

UPTIME_MINUTES=`expr 0$DAYS \* 1440 + 0$HOURS \* 60 + 0$MINUTES`
if [ -x /usr/bin/bc ]; then
	RAW_DAYS=`echo "$UPTIME_MINUTES / 1440" | /usr/bin/bc -l`
else
	RAW_DAYS=`expr 0$UPTIME_MINUTES \/ 1440`
fi
UPTIME_DAYS=`printf "%3.4f\n" $RAW_DAYS`
UPTIME_MSG="${DAYS:+$DAYS Days,} ${HOURS:+$HOURS Hours,} $MINUTES Minutes"
PERFDATA="|Uptime=$UPTIME_DAYS;$MIN_WARNING:$MAX_WARNING;$MIN_CRITICAL:$MAX_CRITICAL;0;"
if [ $MIN_CRITICAL ] && [ $UPTIME_MINUTES -lt $MIN_CRITICAL ] ; then
	echo "CRITICAL - system rebooted $UPTIME_MSG ago$PERFDATA"
	exit $STATE_CRITICAL

  elif [ $MIN_WARNING ] && [ $UPTIME_MINUTES -lt $MIN_WARNING ] ; then
	echo "WARNING - system rebooted $UPTIME_MSG ago$PERFDATA"
	exit $STATE_WARNING

  elif [ $MAX_CRITICAL ] && [ $UPTIME_MINUTES -gt $MAX_CRITICAL ] ; then
	echo "CRITICAL - system has not rebooted for $UPTIME_MSG$PERFDATA"
	exit $STATE_CRITICAL

  elif [ $MAX_WARNING ] && [ $UPTIME_MINUTES -gt $MAX_WARNING ] ; then
	echo "WARNING - system has not rebooted for $UPTIME_MSG$PERFDATA"
	exit $STATE_WARNING

  else
	echo "OK - uptime is $UPTIME_MSG$PERFDATA"
	exit $STATE_OK
fi
