# included function for nodecheck

getfromtb() {
    unset -v d ; declare -a d=($@)
    
#echo "${FUNCNAME[0]}:${LINENO} request:||${d[0]}||"
    case ${d[0]} in
	meminfo )
#	echo "asked for meminfo node:${d[1]}:"
        #freeBSD - grep memory /var/run/dmesg.boot
	#linux - cat /proc/meminfo | grep MemTotal
	# see also http://en.wikipedia.org/wiki/Gigabyte
	# GiB = 1073741824 (2**30) bytes, MiB = 1048576 (2**20) bytes 
	    case ${d[1]} in
		pc4 | pc7 ) echo "256MiB" ;;
		pc126 | pc121 | pc137 | pc133) echo "512MiB" ;;
		pc207 | pc208| pc286 | pc219 ) echo "2GiB" ;;
		ibapah ) echo "8GiB" ;;
		boss.emulab.net ) echo "4GiB" ;;
		pc472 | pc446 | pc406 ) echo "12GiB" ;;
		pc607 ) echo "128GiB" ;;
		* ) echo "tb ${d[1]} unknown_host" ;;
	    esac
	    ;;
	cpuinfo )
#	echo "asked for cpuinfo node:${d[0]}:"
	#Architecture  Sockets Cores_socket Threads_core MHz {HT}{x64}{VIRT}
	    case ${d[1]} in
		pc4 | pc7 ) echo "i686 1 1 1 600 000" ;;
		pc126 | pc121 | pc137 | pc133 ) echo "i686 1 1 1 850 000" ;;
		pc207 | pc208 | pc286 | pc219 ) echo "x86_64 1 1 2 3000 110" ;;
		ibapah ) echo "x86_64 1 2 2400 110" ;;
		boss.emulab.net ) echo "x86_64 2 1 1 3000 110" ;;
		pc472 | pc406 | pc446 ) echo "x86_64 1 4 2 2400 111" ;;
		pc607 ) echo "x86_64 4 8 2 2200 111" ;;
		* ) 
		    echo "tb ${d[1]} unknown_host"
	            return 1
		    ;;
	    esac
	    ;;
	diskinfo )
#	echo "asked for diskinfo node:${d[0]}:"
	    case ${d[1]} in
		pc4 | pc7 ) echo "13GB" ;;
		pc126 | pc121 | pc137 | pc136 ) echo "41GB" ;;
		pc207 | pc208 | pc286 | pc219 ) echo "146GB 146GB" ;;
		ibapah ) echo "160GB 500GB 500GB" ;;
#	    boss.emulab.net ) echo "" ;;
		pc472 | pc406 | pc446 ) echo "500GB 250GB" ;;
		* ) 
		    echo "unknown_host"
	            return 1
		    ;;
	    esac
	    ;;
	* )
	    echo "unknown_request"
	    return 1
	    ;;
    esac
    
    return 0
    
}


# smallest chunk to count with, in MiB
SmallestCNT=256
KiB=1024
KiB256=$(($KiB*${SmallestCNT}))  #smallest chunk to count with
MiB=1048576
GiB=1073741824


#how big is this
hbis() {
    number=$1
#number="250260kB"
#number="443124kB"
#number="4000848kB"
#number="8110204kB"
#number="13,676,544,000 bytes"
#number="8388608"
#number="146,815,733,760 bytes [146 GB]"
#number="500,107,862,016 bytes [500 GB]"
#number="[500 GB]"
#number="131824428kB"
    base=""

    # little input checking - remove punction and spaces
    z=$(echo ${number} | tr -d [:punct:] | tr -d [:space:])
    y=$(echo ${z,,}) #lower case letters

    # what units is the number in
    # check for string 'bytes'
    if [ ${y%%bytes*} != ${y} ] ; then
	#remove the string 'ytes' and everthing after
	y=$(echo ${y/ytes*/})
    fi

    if [ ${y%%m*} != ${y} ] ; then
	# strip letters
	number=${y%%m*}
	bytes=$((${number}*$MiB))
    elif [ ${y%%g*} != ${y} ] ; then
	number=${y%%g*}
	bytes=$((${number}*$GiB))
    elif [ ${y%%k*} != ${y} ] ; then
	number=${y%%k*}
	bytes=$((${number}*$KiB))
    else
	z=${y%%[a-z]*}
	number=${z//,/}
	bytes=$number
    fi

    if (( $bytes >= $GiB)) ; then
	base="g"
    elif (( $bytes >= $MiB)) ; then
	base="m"
    elif (( $bytes >= $KiB)) ; then
	base="k"
    else
	base="b"
    fi

#echo -e "\n${FUNCNAME[0]}:${LINENO} base:$base number:$number bytes=$bytes"
#echo "$number"
#echo "$bytes"
#echo "137438953472"
    # return numbers in MiB
    case $base in
	g )
#echo "${FUNCNAME[0]}:${LINENO} -------- number:$number, bytes=$bytes"
	    c=0
	    for ((x=$GiB;;x+=$GiB)) ; do
		((++c))
		[[ $x -ge $bytes ]] && break
	    done
#echo ${FUNCNAME[0]}:${LINENO} base:$base number:$number bytes=$bytes c=$c
	    echo ${c}GiB
	    ;;
	m )
#echo "${FUNCNAME[0]}:${LINENO} -------- number:$number, bytes=$bytes"
	    c=0
	    for ((x=$MiB;;x+=$MiB)) ; do
		((++c))
		[[ $x -ge $bytes ]] && break
	    done
	    echo ${c}MiB
	    ;;

	k )
#echo "${FUNCNAME[0]}:${LINENO} -------- number:$number, bytes=$bytes"
	    c=0
	    for ((x=${KiB256};;x+=${KiB256})) ; do
		((++c))
		[[ $x -ge $number ]] && break
	    done
#echo "${FUNCNAME[0]}:${LINENO} ----- c:$c "
	    echo $((${c}*${SmallestCNT}))MiB
	    ;;
	
	b )
#echo "${FUNCNAME[0]}:${LINENO} -------- number:$number, bytes=$bytes"
	    if (( ${number} < $KiB )) ; then
		echo ${number}BiB
	    elif (( ${number} < $MiB )) ; then
		echo $(($number/$KiB))KiB
	    elif (( ${number} < $GiB )) ; then
		echo $(($number/$MiB))MiB
	    elif (( ${number} = $GiB )) ; then
		echo $(($number/$GiB))GiB
	    else
	    c=0
	    for ((x=$GiB;;x+=$GiB)) ; do
		((++c))
		[[ $x -ge $bytes ]] && break
	    done
	    echo ${c}GiB
	    fi
	    
	    ;;
    esac
}
