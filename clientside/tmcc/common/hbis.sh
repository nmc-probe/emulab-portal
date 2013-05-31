
# what a mess, need to replace with something sane

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
#    z=$(echo ${number} | tr -d [:punct:] | tr -d [:space:])
    z=$number
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
