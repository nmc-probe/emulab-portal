#function debugging by setting  FUNCDEBUG=y

#exit on unbound var
set -u
#exit on any error
set -e

# Gobal Vars
declare NOSM="echo" #do nothing command
declare host       #emulab hostname
declare failed=""  #major falure to be commicated to user
declare os=""      #[Linux|FreeBSD] for now

inithostname() {
    os=`uname -s`
    host=`hostname`
    if [ -e "/var/emulab/boot/realname" ]; then
        host=`cat /var/emulab/boot/realname`
    fi
    return 0
}

findSmartctl() {
    local findit=$(which smartctl)
    if [ -z "${findit}" ] ; then
	if [ -x "/usr/sbin/smartctl" ]; then
	    findit="/usr/sbin/smartctl"
	else
	    findit=$NOSM
	fi
    fi
    echo $findit
    return 0
}

# setup logging
initlogs () {
    funcdebug $FUNCNAME:$LINENO enter $@

    logfile=${1-"/tmp/nodecheck.log"}
    logfile4tb=${2-""}
    tmplog=/tmp/.$$.log ; cat /dev/null > ${tmplog} # create and truncate

    logout=/tmp/.$$logout.log ; touch ${logout} # make it exist
    tmpout=/tmp/.$$tmpout.log ; touch ${tmpout}
#    tmpfunctionout=/tmp/.$$tmpfunctionout.log 

    funcdebug $FUNCNAME:$LINENO leave
    return 0
}

cleanup() {
    rm -f $tmplog $logout $tmpout 
}

getdrivenames() {
    # use smartctl if exits
    # use scan of disk devices
    # use / 
    # truncate all together and then make uniq

    local os=$(uname -s)
    local sm=$(findSmartctl)
    local drivelist=""
    local drives="" 
    local x elm

#    if [ "$sm" != "${sm/smartctl}" ] ; then
#	x=$($sm --scan-open | awk '{print $1}')
#	if [ "$x" != "${x/dev}" ] ; then
#	    for elm in $x ; do
#		x=${x/"/dev/pass2"/} # FreeBSD not a HD, Tape?
#		drivelist+="$x "
#	    done
#	fi
#    fi


    case $os in
	Linux )
	    list="a b c d e f g h i j k l m n o p"
	    for i in $list
	    do
		if [ -b /dev/sd${i} ] ; then
		    drivelist+="/dev/sd${i} "
		fi
	    done
	    ;;
	FreeBSD )
	    list="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"
	    for i in $list
	    do
		[[ -b /dev/da${i} ]] && drivelist+="/dev/da${i} " 
		[[ -c /dev/ad${i} ]] && drivelist+="/dev/ad${i} " 
		[[ -c /dev/amrd${i} ]] && drivelist+="/dev/amrd${i} " 
	    done
	    ;;
	* )
	    echo "${FUNCNAME[0]}:${LINENO} Internal error"
	    exit
	    ;;
    esac
    
#echo "drivelist||$drivelist||" >&2
#
#    while (( ${#drivelist} ))  ; do
#	elm=${drivelist%% *}
#	drives+="$elm"
#	drivelist=${drivelist//$elm/}
#echo "drivelist||$drivelist|| drives||$drives||" >&2
#    done
#    echo $drives
    echo $drivelist
#echo "checkutils drives:||$drives||"
    return 0
}


# The timesys function terminates its script unless it terminates earlier on its own
# args: max_time output_file command command_args
timesys() {
    maxtime="$1"; shift;
    out="$1" ; shift;
    command="$1"; shift;
    args="$*"
    me_pid=$$;
    sleep $maxtime &
    timer_pid=$!
{
    $command $args &
    command_pid=$!
    wait ${timer_pid}
    kill -2 ${command_pid}
} > $out 2>&1
}

# Internally used
declare FUNCDEBUG=n
declare ECHOCMDS=n

#TOUPPER() { $(echo $@ |tr 'a-z' 'A-Z') }
#TOLOWER() { $(echo ${@,,}) }

# Function Tracing
funcdebug ()
{
    [[ $FUNCDEBUG = y ]] && echo -e "    ====> $(/bin/date +%k:%M:%S) $@" >&2
    return 0
}

# command debugging
runCmd ()
{
    if [[ $ECHOCMDS = y ]] ; then
        echo "    =CMD> $@" >&2
    fi
    eval $@
    return $?
}

# skeleton function
functionSkel ()
{
    funcdebug $FUNCNAME:$LINENO enter $@

printf "PROGRAMMING ERROR $FUNCNAME $LINENO \n" && exit 1

    funcdebug $FUNCNAME:$LINENO leave
    return 0
}

