#!/bin/bash

# args
dev=$1

# initialise
path=$(dev-path $dev)
prt=$(dev-prt $dev)

# check
[ -n "$path" ] && [ -n "$prt" ] || exit 1

# libs
export PATH=$PATH:$(lib-path $0)

# functions
end() {
	sleep 0.5
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

# main
while :; do
	sleep 60 &
	slp=$!
	cdr-reset $dev
	cdr-scan $dev
	cdr-data $dev
	wait $slp
done
