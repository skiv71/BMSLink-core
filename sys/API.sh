#!/bin/bash

# initialise
path=$(bms-temp)

# check
[ -n "$path" ] || exit 1

# traps
trap exit SIGTERM SIGHUP SIGINT

# start
path+=/API
chk-dir $path || mkdir -p $path
chmod -R 777 $path


# main
prt-msg controller...
sleep 0.5
echo started!
sleep 0.5
while :; do
	for file in $(ls $path/*.cmd 2>/dev/null); do
		while read line; do
			cmd=($line)
			msg="command [$cmd]: "
			case $cmd in
					bms-proc|kill|set-val|dev-scan|dev-del|dev-ctrl)
							i=1
							while [ -n "${cmd[$i]}" ]; do
								msg+=" "${cmd[$i]}
								((i++))
							done
							echo -n $msg
							${cmd[@]} &
							[[ $i -gt 1 ]] &&	echo ", ok!" || echo "ok!"
							;;

					*)
							echo $msg, invalid!
							;;

			esac
		done < $file
		rm -rf $file
	done
	sleep 0.1
done
