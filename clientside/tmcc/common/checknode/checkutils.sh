#
# Copyright (c) 2013 University of Utah and the Flux Group.
# 
# {{{EMULAB-LICENSE
# 
# This file is part of the Emulab network testbed software.
# 
# This file is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# This file is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.
# 
# }}}
#

#function debugging by setting  FUNCDEBUG=y

#exit on unbound var
set -u
#exit on any error
set -e

#only source this file once
if [ "${checkutils+"beenhere"}" == "beenhere" ] ; then
    return 0
else
    checkutils="sourced"
fi

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


declare errext_val # used?

# Gobal Vars
declare NOSM="echo" #do nothing command
declare host       #emulab hostname
declare failed=""  #major falure to be commicated to user
declare os=""      #[Linux|FreeBSD] for now
declare -a todo_exit
declare -A hwinv  # hwinv from tmcc.bin
declare -A hwinvcopy  # a copy of hwinv from tmcc.bin


#declare -A tcm_out # hwinv for output
#declare -A tcm_inv # what we have discovered
# declare -p todo_exit

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
#trap 'err_report $FUNCNAME:$LINENO' ERR
trap 'err_report $LINENO' ERR


# read info from tmcc no args uses the globel array hwinv
# if $1 then use that for a input file else use tmcc.bin
readtmcinfo() {
    local -A ina
    local keyword
    local -i dcnt=0
    local -i ncnt=0
    local ifile 
    local itmp

    ifile=${1+$1} # use $1 if set otherwise use nothing
    if [ -z "$ifile" ] ; then
	# noinput file then use a tmp file to hold data from tmcc.bin
	itmp="y"
	ifile=/tmp/.$$tmcchwinv
	$(/usr/local/etc/emulab/tmcc.bin hwinfo > $ifile)
    else
	itmp=""
    fi

    # initalize array
    if [ -z "${hwinv["hwinvidx"]+${hwinv["hwinvidx"]}}" ] ; then
	hwinv["hwinvidx"]="" #start the array
    else	
	for i in ${hwinv["hwinvidx"]} ; do
	    unset hwinv[$i]
	done
	hwinv["hwinvidx"]="" #restart the array
    fi

    # handle mult-line  input for disks and nets
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

# copy assoctive array hwinv into hwinvcopy
# this is a little stupid but since I can't pass array I use globals
copytmcinfo () {
    # initalize array
    if [ -z "${hwinvcopy["hwinvidx"]+${hwinvcopy["hwinvidx"]}}" ] ; then
	hwinvcopy["hwinvidx"]="" #start the array
    else	
	for i in ${hwinvcopy["hwinvidx"]} ; do
	    unset hwinvcopy[$i]
	done
	hwinvcopy["hwinvidx"]="" #restart the array
    fi
    # copy index from old array
    hwinvcopy["hwinvidx"]=${hwinv["hwinvidx"]} 
    for i in ${hwinv["hwinvidx"]} ; do
	hwinvcopy[$i]=${hwinv[$i]}
    done
}

# compare arrays hwinv and copyhwinv arg1=outputfile
comparetmcinfo() {
    local fileout=$1
    # need to handle differing order with disks and nic addresses
    local localidx="${hwinv["hwinvidx"]}"
    local tbdbidx="${hwinvcopy["hwinvidx"]}"
    local localnics="" tbdbnics="" netunit=""
    local -i a b
    local x addr

    rm -f ${fileout} ${fileout}_local ${fileout}_tbdb
    retval=$(compareunits NET ${fileout}_local ${fileout}_tbdb)
    retval2=$(compareunits DISK ${fileout}_local ${fileout}_tbdb)

    # take NETUNIT out
    localidx=${localidx//NETUNIT[[:digit:]][[:digit:]]/}
    localidx=${localidx//NETUNIT[[:digit:]]/}
    tbdbidx=${tbdbidx//NETUNIT[[:digit:]][[:digit:]]/}
    tbdbidx=${tbdbidx//NETUNIT[[:digit:]]/}

    # take DISKUNIT out
    localidx=${localidx//DISKUNIT[[:digit:]][[:digit:]]/}
    localidx=${localidx//DISKUNIT[[:digit:]]/}
    tbdbidx=${tbdbidx//DISKUNIT[[:digit:]][[:digit:]]/}
    tbdbidx=${tbdbidx//DISKUNIT[[:digit:]]/}

    arrayidx="$localidx $tbdbidx"
    arrayidx=$(uniqstr $arrayidx)

    # step through the local index, looking only for one copy
    for i in ${localidx} ; do
	# following bash syntax: "${a+$a}" says use $a if exists else use nothing
	if [ -z "${hwinvcopy[$i]+${hwinvcopy[$i]}}" ] ; then
	    # localidx has it - hwinvcopy does not
	    printf "\n%s\n" "Local only ${hwinv[$i]}" >> ${fileout}
	    arrayidx=${arrayidx/$i} # nothing to compare with
	fi
    done
    # step through the testbed index, looking only for one copy
    for i in ${tbdbidx} ; do
	# followin bash syntax: "${a+$a}" says use $a if exists else use nothing
	if [ -z "${hwinv[$i]+${hwinv[$i]}}" ] ; then
	    printf "\n%s\n" "Testbest db only"  >> ${fileout}
	    arrayidx=${arrayidx/$i} 
	fi
    done
    
    #compare what is left
    for i in $arrayidx ; do
	if [ "${hwinv[$i]}" != "${hwinvcopy[$i]}" ] ; then
	    echo "" >> $fileout
	    echo "$i does not match" >> $fileout
	    echo "local ${hwinv[$i]}" >> $fileout
	    echo "tbdb ${hwinvcopy[$i]}" >> $fileout
	fi
    done

    [[ -f ${fileout}_local ]] && cat ${fileout}_local >> ${fileout}
    [[ -f ${fileout}_tbdb ]] && cat ${fileout}_tbdb >> ${fileout}
    rm -f ${fileout}_local ${fileout}_tbdb

    return 0
}

# multi-line units arg1=unittype arg2=localonlyfile arg3=tbdbonlyfile
compareunits() {
    local unittype=$1
    local localonly=$2
    local tbdbonly=$3
    # need to handle differing order with disks and nic addresses
    local localidx="${hwinv["hwinvidx"]}"
    local tbdbidx="${hwinvcopy["hwinvidx"]}"
    local localunits="" tbdbunits="" devunit=""
    local -i a b
    local x addr

    # How are things different between unit types
    case $unittype in
	NET )
	    unitinfoidx_str="NETINFO"
	    unitinfo_strip="NETINFO UNITS="
	    unit_str="NETUNIT"
	    unit_pre_strip="*ID=\""
	    unit_post_strip="\"*"
	    unit_human_output="NIC"
	    ;;
	DISK )
	    unitinfoidx_str="DISKINFO"
	    unitinfo_strip="DISKINFO UNITS="
	    unit_str="DISKUNIT"
	    unit_pre_strip="*SN=\""
	    unit_post_strip="\"*"
	    unit_human_output="DISK"
	    ;;
	* )
	    echo "Error in compareunits don't now type $unittype. Giving up."
	    exit 1
	    ;;
    esac


    # Pull the units out and checkthem
    # 
    # if any UNITs test - note at this point the same # of UNITS are on both lists
    if [ -n "${hwinv["${unitinfoidx_str}"]+${hwinv["${unitinfoidx_str}"]}}" ] ; then
	    x=${hwinv["${unitinfoidx_str}"]}
	    a=${x/${unitinfo_strip}}
    else
	a=0
    fi
    if [ -n "${hwinvcopy["${unitinfoidx_str}"]+${hwinvcopy["${unitinfoidx_str}"]}}" ] ; then
	x=${hwinvcopy["${unitinfoidx_str}"]}
	b=${x/${unitinfo_strip}}
    else
	b=0
    fi
    [[ $a > $b ]] && maxunits=$a || maxunits=$b 
    for ((i=0; i<$maxunits; i++)) ; do
	# gather just the units addresses 
	devunit="${unit_str}${i}"
        # following bash syntax: "${a+$a}" says use $a if exists else use nothing
	if [ -n "${hwinv[$devunit]+${hwinv[$devunit]}}" ] ; then
	    # add just the address
	    addr=${hwinv[$devunit]}
	    addr=${addr#${unit_pre_strip}}
	    addr=${addr%${unit_post_strip}}
	    localunits+="$addr "
	    localidx=${localidx/$devunit}
	fi
	if [ -n "${hwinvcopy[$devunit]+${hwinvcopy[$devunit]}}" ] ; then
	    addr=${hwinvcopy[$devunit]}
	    addr=${addr#${unit_pre_strip}}
	    addr=${addr%${unit_post_strip}}
	    tbdbunits+="$addr "
	    tbdbidx=${tbdbidx/$devunit}
	fi
    done

    # remove from the lists all matching 
    # lower case all
    localunits=${localunits,,}
    tbdbunits=${tbdbunits,,}
    for i in $localunits ; do
	if [ "${tbdbunits/$i}" != "${tbdbunits}" ]; then
	    tbdbunits=${tbdbunits/$i}
	    localunits=${localunits/$i}
	fi
    done
    # same other swap arrays
    for i in $tbdbunits ; do
	if [ "${localunits/$i}" != "${localunits}" ]; then
	    localunits=${localunits/$i}
	    tbdbunits=${tbdbunits/$i}
	fi
    done
    #remove extra spaces
    read -rd '' localunits <<< "$localunits"
    read -rd '' tbdbunits <<< "$tbdbunits"

    # any mismatches would be in localunits and tbdbunits
    if [ -n "${localunits}" ]; then
	if [ ! -f $localonly ] ; then
	    printf "\n%s\n" "Found only locally" > $localonly
	fi
	printf "%s%s %s\n" "${unit_human_output}" "s:" "$localunits"  >> $localonly
    fi
    if [ -n "${tbdbunits}" ]; then
	if [ ! -f $tbdbonly ] ; then
	    printf "\n%s\n" "In testbed db but not found" > $tbdbonly
	fi
	printf "%s%s %s\n" "${unit_human_output}" "s:" "$tbdbunits" >> $tbdbonly
    fi

    echo "$localidx $tbdbidx"
}


# take a string make the words in it uniq
uniqstr() {
    local instr="$@"
    local outstr=""
    for i in $instr ; do
	if [ "${outstr/$i}" ==  "$outstr" ] ; then
	    # $i not in outstr, add it
	    outstr+="$i "
	fi
    done
    echo $outstr
}

# no args uses the globel arrays hwinvv, tcm_in, tcm_out
#mergetmcinfo() {
#    for i in ${hwinv["hwinvidx"]} ; do
#	hwinv[$i]+=" ADD"
#    done
#}

# arg $1 is the file to write uses the globel tcm_out array
#writetmcinfo() {
#:
#}


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
    os=$(uname -s)
    if [ -z $os ] ; then
	echo "ERROR uname messed up"
	exit 1
    fi
    if [ -e "/usr/local/etc/emulab/tmcc.bin" ] ; then
	host=$(/usr/local/etc/emulab/tmcc.bin nodeid)
    else
	echo "ERROR no tmcc.bin command"
	exit 1
    fi
    if [ -z "$host" ] ; then 
	if [ -e "/var/emulab/boot/realname" ] ; then
	    host=$(cat /var/emulab/boot/realname)
	elif [ -e "/var/emulab/boot/nodeid" ] ; then
	    host=$(cat /var/emulab/boot/nodeid)
	else
	    host=$(hostname)
	fi
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
#echo "EXIT TODO doing: $i"
        $($i)
    done
    return 0
}

function add_on_exit()
{
    local nex=${#todo_exit[*]}
#echo "add on exit called B4n=${#todo_exit[*]} SHELL=$$ |$@|++++++++++++++++++++"
    todo_exit[$nex]="$@"
    if [[ $nex -eq 0 ]]; then
        trap on_exit EXIT
    fi
    return 0
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
    tmplog=/tmp/.$$tmp.log ; cat /dev/null > ${tmplog} # create and truncate
    add_on_exit "rm -f $tmplog"

    logout=/tmp/.$$logout.log ; touch ${logout} # make it exist
    add_on_exit "rm -f $logout"
    tmpout=/tmp/.$$tmpout.log ; touch ${tmpout}
    add_on_exit "rm -f $tmpout"
#    tmpfunctionout=/tmp/.$$tmpfunctionout.log 

    funcdebug $FUNCNAME:$LINENO leave
    return 0
}

#cleanup() {
#    rm -f $tmplog $logout $tmpout 
#}

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

#TOUPPER() { $(echo $@ |tr 'a-z' 'A-Z') } also ${par^^}
#TOLOWER() { $(echo ${@,,}) }             also #{par,,}

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

