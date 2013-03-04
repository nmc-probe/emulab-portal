# included function for nodecheck

getfromtb(){
unset -v d ; declare -a d=($@)

case ${d[0]} in
    meminfo )
#	echo "asked for meminfo node:${d[1]}:"
        #freeBSD - grep memory /var/run/dmesg.boot
	#linux - cat /proc/meminfo | grep MemTotal + 1048576 / 1048576
	# see also http://en.wikipedia.org/wiki/Gigabyte
	# GiB = 1073741824 (2**30) bytes, MiB = 1048576 (2**20) bytes 
	case ${d[1]} in
#	    pc286 ) echo "2048MB" ;;
#	    ibapah ) echo "8110204kB" ;;
#	    boss.emulab.net ) echo "4096MB" ;;
#	    pc472 ) echo "12163328kB" ;;
#	    pc219 ) echo "1990948kB" ;;

	    pc4 | pc7 ) echo "256MiB" ;;
	    pc126 | pc121 | pc137 | pc133) echo "512MiB" ;;
	    pc207 | pc208| pc286 | pc219 ) echo "2048MiB" ;;
	    ibapah ) echo "8096MiB" ;;
	    boss.emulab.net ) echo "4096MiB" ;;
	    pc472 ) echo "12288MiB" ;;
	    * ) echo "-1" ;;
	esac
	;;
    cpuinfo )
#	echo "asked for cpuinfo node:${d[0]}:"
        
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
    base=""

    # little input checking - remove punction and spaces
    z=$(echo ${number} | tr -d [:punct:] | tr -d [:space:])
    # what units is the number in
    y=$(echo ${z,,}) #lower case letters

    # check for string 'bytes'
    if [ ${y%%bytes*} != ${y} ] ; then
	#remove the string 'ytes' and everthing after
	y=$(echo ${y/ytes*/})
    fi

    if [ ${y%%m*} != ${y} ] ; then
	# its in megs
	base="m"
	# strip letters
	number=${y%%m*}
	bytes=$((${number}*$MiB))
    elif [ ${y%%g*} != ${y} ] ; then
	base="g"
	number=${y%%g*}
	bytes=$((${number}*$GiB))
    elif [ ${y%%k*} != ${y} ] ; then
	number=${y%%k*}
	base="k"
	bytes=$((${number}*$KiB))
    else
	base="b"
	z=${y%%[a-z]*}
	number=${z//,/}
	bytes=$number
    fi

#echo base:$base number:$number bytes=$bytes
    # return numbers in MiB
    case $base in
	g )
	    c=0
	    for ((x=$GiB;;x+=$GiB)) ; do
		((++c))
		[[ $x -ge $bytes ]] && break
	    done
	    echo ${c}GiB
	    ;;
	m )
	    c=0
	    for ((x=$MiB;;x+=$MiB)) ; do
		((++c))
		[[ $x -ge $bytes ]] && break
	    done
	    echo ${c}MiB
	    ;;

	k )
	    c=0
	    for ((x=${KiB256};;x+=${KiB256})) ; do
		((++c))
		[[ $x -ge $number ]] && break
	    done
	    [[ $number -ge $(($MiB*4)) ]] && ((++c))
	    echo $((${c}*${SmallestCNT}))MiB
	    ;;
	
	b )
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
