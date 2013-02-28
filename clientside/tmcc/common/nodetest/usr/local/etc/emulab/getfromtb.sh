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
	    pc126 | pc121 ) echo "512MiB" ;;
	    pc286 | pc219 ) echo "2048MiB" ;;
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
	;;
    * )
	echo "unknown request"
	return 1
	;;
esac

return 0

}

