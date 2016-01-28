#!/bin/bash

# args
dev=$1

# initialise
path=$(dev-path $dev)

# check
[ -n "$path" ] || exit 1

# libs
export PATH=$PATH:$(lib-path $0)

# functions
end() {
	prt-msg controller...
	sleep 0.5
	echo  stopping!
	exit 1
}

# traps
trap 'echo && end' SIGINT
trap end SIGTERM SIGHUP

# start
prt-msg controller...
sleep 0.5
echo starting!
dev-init $dev
sleep 0.5

# port
prt-msg ip address...
prt=$(dev-prt $dev)
sleep 0.5
if [ -n "$prt" ]; then
	echo $prt
else
	echo none found!
fi
sleep 0.5

# listen
if [ -z "$(pgrep -f "wfl-listen")" ]; then
	prt-msg no UDP listener found!
	sleep 0.5
	prt-msg starting...
	wfl-listen &
	disown $!
	sleep 0.5
	echo done!
fi
sleep 0.5

# main
fail=0
init=0
n=0
while [[ $fail -lt 5 ]]; do
	wfl-send $dev
	wfl-parse $dev
	if [[ $n -ge 50 ]]; then
		dev-purge $dev msg
		ping-host $prt || ((fail++))
		n=0
	fi
	sleep 0.1
	((n++))
done

# error
[[ $init -eq 2 ]] && echo
prt-msg port error!
end
