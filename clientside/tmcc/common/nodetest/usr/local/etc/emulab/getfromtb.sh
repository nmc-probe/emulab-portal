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
		pc472 | pc446 | pc406 | pc511 ) echo "12GiB" ;;
		pc603 | pc607 | pc606 ) echo "128GiB" ;;
		dbox3 ) echo "48GiB" ;;
		* ) echo "tb ${d[1]} unknown_node" ;;
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
		pc472 | pc406 | pc446 | pc511 ) echo "x86_64 1 4 2 2400 111" ;;
		pc603 | pc607 | pc606 ) echo "x86_64 4 8 2 2200 111" ;;
		dbox3 ) echo "x86_64 2 6 2 2600 111" ;;
		* ) 
		    echo "tb ${d[1]} unknown_node"
	            return 1
		    ;;
	    esac
	    ;;
	diskinfo )
#	echo "asked for diskinfo node:${d[0]}:"
	    case ${d[1]} in
		pc7 ) echo "JHYJHT7R523" ;;
		pc137 ) echo "SX0SXM24424" ;;
		pc207 ) echo "3KS0XJW1 3KS0XJK4";;
		pc208 ) echo "3KS0WR70 3KS0X47T" ;;
		ibapah ) echo "160GB 500GB 500GB" ;;
#	    boss.emulab.net ) echo "" ;;
		pc406 ) echo "WD-WMAYP3198698 9SF16YDY" ;;
		pc446 ) echo "WD-WMAYP3465928 9SF16G29" ;;
		pc511 ) echo "WD-WMAYP4342739 9SF1703S" ;;
		pc603 | pc607 ) echo "250GB 600GB 600GB 600GB 600GB 600GB 600GB" ;;
		pc606 ) echo "EA03PC309EVC 9XE02KSQ  EA03PC309EPB EA03PC309E9S EA03PC20973J EA03PC20973B EA03PC309E5U" ;;
		dbox3 ) echo "9SP2LK89 9SP2LLRK" ;;
		* ) 
		    echo "unknown_node"
	            return 1
		    ;;
	    esac
	    ;;
	macinfo )
	    case ${d[1]} in
		pc4 ) echo "00d0b713f4f0 00d0b713f644 00d0b713f492 00d0b713f65a 00d0b713f470 00179AC3657F" ;;
		pc7 ) echo "00d0b713f636 00d0b713f277 00d0b726c1ca 00d0b713f44f 00d0b7102b20 00179AC3657E";;
		pc137 ) echo "00034773a233 00034773a234 0002b3861f8a 0002b3861f8b 00d0b725463a" ;;
		pc133 ) echo "000347738e57 000347738e58 0002b3861d88 0002b3861d89 00034795793e" ;;
		pc207 ) echo "001143e45bc1 001143e45bc2 000423b7424e 000423b7424f 000423b7425a 000423b7425b" ;;
		pc208 ) echo "001143e492cc 001143e492cd 000423b7210a 000423b7210b 000423b72108 000423b72109" ;;
		pc406 ) echo "0024e877694b 0024e877694d 0024e877694f 0024e8776951 00101856ab84 00101856ab86" ;;
		pc446 ) echo "0024e877ad57 0024e877ad59 0024e877ad5b 0024e877ad5d 001018568fac 001018568fae" ;;
		pc511 ) echo "0024e87908a3 0024e87908a5 0024e87908a7 0024e87908a9 001018568fc8 001018568fca" ;;
		pc603 ) echo "D4AE529B88D3 D4AE529B88D4 D4AE529B88D5 D4AE529B88D6 a0369f0731b4 a0369f0731b6 a0369f073258" ;;
		pc607 ) echo "D4AE529B6DDB D4AE529B6DDC D4AE529B6DDD D4AE529B6DDE a0369f073390 a0369f073392 a0369f070b2c" ;;
		pc606 ) echo "D4AE529B896F D4AE529B8970 D4AE529B8971 D4AE529B8972 a0369f070b1c a0369f070b1e a0369f0724f4" ;;
		boss.emulab.net ) echo "001143e453fe 001143e453ff 000e0c21a0fa 0002e3001c10" ;;
		dbox3 ) echo "c80aa9f17ce6 c80aa9f17ce7 e89a8f63eac2 e89a8f63eac3" ;;
		* )
		    echo "unknown_node"
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
