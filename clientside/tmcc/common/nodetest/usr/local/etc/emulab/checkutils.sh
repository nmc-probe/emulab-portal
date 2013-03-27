
# set -u should done before calling 

# return a list of the drives on the system
# use smartctl, /dev, df, fstab, dmesg etc.

# arg1 - filename to hold logging info
# arg2 - filename to hold runtime output
# returns space sperated list of drive names IN "smartctl --scan" format


NOSM="echo"
SMARTCTL=$(which smartctl)
if [ -z "${SMARTCTL}" ] ; then
    if [ -x "/usr/sbin/smartctl" ]; then
	SMARTCTL="/usr/sbin/smartctl"
    else
	SMARTCTL=$NOSM
    fi
fi

getdriveinfo () {
#need to make sure smartcrl is installed
{
#    echo -n "${FUNCNAME[0]}:${LINENO} " ; echo "args::$@::"
    declare buildscan=""
    logout="$1"
    tmpout="$2"

    if [ "${SMARTCTL}" != "$NOSM" ] ; then
	rtn=$($SMARTCTL --scan)
	# unrecongnized
	if [ -n "$(echo $rtn | grep 'UNRECOGNIZED OPTION')" ] ; then
	    error="(smartctl option '--scan' not supported. Attempt alternet method) "
	    err=scan
	elif [ -n "$(echo $rtn | grep -v 'device')" ] ; then
            # output in unexpected format - missing deliminator "device"
	    error="(smartctl option '--scan' strange ouput. Attempt alternet method) "
	    err=scan
	# empty
	elif [ -z "$rtn" ] ; then
	    dt=$(df / | grep /dev)
	    dt=${dt:5}
	    dt=${dt%% *}
	    error="(smartctl device_type '$dt' not supported"
	    err=device
	fi
	[[ $error ]] && echo "$error"
    else
	error="smartmontools missing."
	err="missing"
	echo "$error. FAIL "
    fi
} > ${logout} 2>&1

# put smartctl --scan into driveinv array
# a better control flow control could be used 

placeholder=" . . . . . device"
case $err in
    scan | missing | device )
	case $os in
	    Linux )
		list="a b c d e f g h i j k l m n o p"
		for i in $list
		do
		    if [ -b /dev/sd${i} ] ; then
			buildscan+="/dev/sd${i} $placeholder"
		    fi
		done
		;;
	    FreeBSD )
		list="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"
		for i in $list
		do
		    [[ -b /dev/da${i} ]] && buildscan+="/dev/da${i} $placeholder " 
		    [[ -c /dev/ad${i} ]] && buildscan+="/dev/ad${i} $placeholder " 
		    [[ -c /dev/amrd${i} ]] && buildscan+="/dev/amrd${i} $placeholder " 
		done
		;;
	    * )
		echo "${FUNCNAME[0]}:${LINENO} Internal error"
		exit
		;;
	esac
	unset -v scan
	[[ $buildscan ]] && declare -a scan=($buildscan) || declare -a scan=("")
#	echo -n "${FUNCNAME[0]}:${LINENO} " ; echo "buildscan::${buildscan}::"
	;;
    root )
	echo -n "$error. FAIL " >> ${tmpout}
	echo "Last attempt return roots mount point" >> ${tmpout}
	x=$(df / | grep /dev)
	lastattempt="${x%% *} $placeholder "
	unset -v scan ; declare -a scan=($lastattempt)
	;;
    * )
        # get the output of --scan into array scan
	 unset -v scan ; declare -a scan=($rtn)
#	 echo -n "${FUNCNAME[0]}:${LINENO} " ; echo "rtn::${rtn}::"
	;;
esac

# the result
echo -n "${scan[@]}"

}
