#function debugging by setting  FUNCDEBUG=y

# add static binaries if needed
declare mfsmode="" #are we running in a MFS (ie busybox) mode
if [ -f /etc/emulab/ismfs ] ; then
    meos=$(uname -s)
    mfsmode=1
    mfs_base="/proj/emulab-ops/nodecheck"
    mfs_osdir="${mfs_base}/${meos}"
    mfs_bin="${mfs_osdir}/bin"
    mfs_lib="${mfs_osdir}/lib"
    if [ $PATH == ${PATH/${mfs_bin}} ] ; then
	if [ -d ${mfs_osdir} ] ; then
	    export PATH=/proj/emulab-ops/nodecheck/${meos}/bin:$PATH
	fi
    fi
else
    mfsmode=0
fi

#exit on unbound var
set -u
#exit on any error
set -e
declare errext_val

# Gobal Vars
declare NOSM="echo" #do nothing command
declare host       #emulab hostname
declare failed=""  #major falure to be commicated to user
declare os=""      #[Linux|FreeBSD] for now
declare -a todo_exit

declare -A hwinv  # hwinv from tmcc.bin
#declare -A tcm_out # hwinv for output
#declare -A tcm_inv # what we have discovered

# any command causes exit if -e option set
# including a grep just used so see if some sting is in a file
save_e() {
    x=$-
    [[ "${x/e}" == "${x}" ]] &&	errexit_val=off || errexit_val=on
}
restore_e() {
    [[ $errexit_val == "on" ]] && set -e || set +e
}
# give some indication of exit on ERR trap
err_report() {
    echo "TRAP ERR at $1"
}
trap 'err_report $FUNCNAME:$LINENO' ERR


# read info from tmcc no args uses the globel array hwinv
# if $1 then use that for a input file else use tmcc.bin
readtmcinfo() {
    local -A ina
    local keyword
    local -i dcnt=0
    local -i ncnt=0
    local ifile 
    local itmp

    ifile=${1+$1}
    if [ -z "$ifile" ] ; then
	itmp="y"
	ifile=/tmp/.$$tmcchwinv
	$(/usr/local/etc/emulab/tmcc.bin hwinfo > $ifile)
    else
	itmp=""
    fi

    hwinv["hwinvidx"]="" #rest the array, or at least the index of array
#    tcm_in_hwinvidx="" #rest the array, or at least the index of array

    # handle mult-line 
    while read -r in ; do
	keyword=${in%% *}
	case $keyword in
	    DISKUNIT ) 
		keyword+="$dcnt"
		((++dcnt))
		;;
	    NETUNIT ) 
		keyword+="$ncnt"
		((++ncnt))
		;;
	esac
	hwinv["hwinvidx"]+="$keyword " # keeping the keyword list preserves order
	hwinv[$keyword]=$in
    done < $ifile
    [ -n "$itmp" ] && rm $ifile || : # the colon just stops a error being caught by -e
}

# no args uses the globel arrays hwinvv, tcm_in, tcm_out
mergetmcinfo() {
    for i in ${hwinv["hwinvidx"]} ; do
	hwinv[$i]+=" ADD"
    done
}

# arg $1 is the file to write uses the globel tcm_out array
writetmcinfo() {
:
}


# print only the testbed data table
printtmcinfo() {
    local -i hdunits=0 nicunits=0
    for i in ${hwinv["hwinvidx"]} ; do
	case $i in 
	    CPUINFO ) printf "%s\n" "${hwinv[$i]}" ;;
	    MEMINFO ) printf "%s\n" "${hwinv[$i]}" ;;
	    DISKINFO ) 
		printf "%s\n" "${hwinv[$i]}" 
		x=${hwinv[$i]}
		hdunits=${x/#DISKINFO UNITS=/}

		# for HD need also check that we have a valid value
		# we collect more info then the testbed data base wants
		for ((n=0; n<$hdunits; n++)) ; do
		    # grab diskunitline
                    s=${hwinv[DISKUNIT$n]}
		    # turn space seperated string into array
		    unset -v d ; declare -a d=(${s// / })
		    numelm=${#d[*]}
		    echo -n "${d[0]} " #that is the word DISKUNIT
		    
		    for ((elm=1; elm<$numelm; elm++)) ; do
		        # must have form obj=value (where val can be blank) to work
			objval=${d[$elm]}
			[[ -z $objval ]] && continue  # that's bad no tupil
			obj=${objval%%=*}
			val=${objval##*=}
			[[ -z $val ]] && continue # bad also no value (or empty string)
			u=${val,,} #lower case
			[[ $u == ${u/unk} ]] || continue # the value has the UNKNOWN value
			[[ $u == ${u/na} ]] || continue # the value has the NA
			[[ $u == ${u/not} ]] || continue # the value has the LinuxNot
			[[ $u == ${u/bad} ]] || continue # the value bad_dd
		        # out put the stuff the database wants
		        # skip the stuff the database does not want
			case $obj in
			    SN | TYPE | SECSIZE | SECTORS | WSPEED | RSPEED )
				echo -n "$objval " ;;
			esac
		    done
		    echo "" # end the line
		done
		;;
            NETINFO ) printf "%s\n" "${hwinv[$i]}" 
		x=${hwinv[$i]}
		nicunits=${x/#NETINFO UNITS=/}
		for ((i=0; i<$nicunits; i++)); do printf "%s\n" "${hwinv[NETUNIT$i]}"; done ;;
	esac
    done
}

# print all hwinv
printhwinv() {
    for i in ${hwinv["hwinvidx"]} ; do
	printf "%s\n" "${hwinv[$i]}"
    done
}

# which is not in busybox and not a bash builtin
which() {
    mypath=$(env | grep PATH)
    mypath=${mypath/PATH=/}
    mypath=${mypath//:/ }
    for i in $mypath ; do
	if [ -e $i/$1 ] ; then
	    echo $i/$1
	    return 0
	fi
    done
    return 1
}

inithostname() {
    os=`uname -s`
    host=`hostname`
    if [ -e "/var/emulab/boot/realname" ]; then
        host=`cat /var/emulab/boot/realname`
    elif
	[ -e "/var/emulab/boot/nodeid" ]; then
	host=$(cat /var/emulab/boot/nodeid)
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


function on_exit()
{
    for i in "${todo_exit[@]}" ; do
echo "EXIT TODO: $i"
        $($i)
    done
}

function add_on_exit()
{
    local n=${#todo_exit[*]}
    todo_exit[$n]="$@"
    if [[ $n -eq 0 ]]; then
        trap on_exit EXIT
    fi
}

# setup logging
initlogs () {
    funcdebug $FUNCNAME:$LINENO enter $@

    logfile=${1-"/tmp/nodecheck.log"}
# start XXX XXX should be "" when in production
#    logfile4tb=${2-""}
    logfile4tb=${2-"/tmp/nodecheck.log.tb"}
    touch ${logfile4tb}
# end XXX XXX 
    tmplog=/tmp/.$$.log ; cat /dev/null > ${tmplog} # create and truncate
    add_on_exit "rm -f $tmplog"

    logout=/tmp/.$$logout.log ; touch ${logout} # make it exist
    add_on_exit "rm -f $logout"
    tmpout=/tmp/.$$tmpout.log ; touch ${tmpout}
    add_on_exit "rm -f $tmpout"
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
		[[ -c /dev/da${i} ]] && drivelist+="/dev/da${i} " 
		[[ -c /dev/ad${i} ]] && drivelist+="/dev/ad${i} " 
		[[ -c /dev/amrd${i} ]] && drivelist+="/dev/amrd${i} " 
		[[ -c /dev/mfid${i} ]] && drivelist+="/dev/mfid${i} " 
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
    siglist="2 15 9"
    for i in $siglist ; do
	running=$(ps -a | grep $command_pid | grep dd)
	[[ "$running" ]] || break
	kill -${i} ${command_pid}
    done
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

#init_tcminfo()
#{
#    <<EOF
#
#EOF
#}
