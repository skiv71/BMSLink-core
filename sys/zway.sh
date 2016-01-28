#!/bin/bash

# args
dev=$1

# check
[[ $# -eq 1 ]] || exit 1

# libs
export PATH=$PATH:$(lib-path $0)

# functions
end() {
	sleep 0.5
	prt-msg controller...
	sleep 0.5
	echo stopping!
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
prt-msg com port...
prt=$(dev-prt $dev)
sleep 0.5
if [ -n "$prt" ]; then
	echo $prt
else
	echo none found!
	end
fi
sleep 0.5

# connect
prt-msg connecting...
dev-con $dev &>/dev/null &
con=$!
sleep 1
if chk-pid $con; then
	echo done!
else
	echo failed!
	end
fi
sleep 0.5

# home
prt-msg checking home...
if [[ $? -eq 0 ]]; then
	echo done!
else
	echo failed!
	end
fi
sleep 0.5

# tcp
prt-msg setting http...
tcp=$(zwy-tcp $dev new)
sleep 0.5
if [ -n "$tcp" ]; then
	echo $tcp
else
	echo none found!
	end
fi
sleep 0.5

# auto
prt-msg updating automation...
zwy-auto $dev $tcp
if [[ $? -eq 0 ]]; then
	sleep 0.5
	echo done!
else
	echo failed!
	end
fi
sleep 0.5

# config
prt-msg creating config...
zwy-cfg $dev new
if [[ $? -eq 0 ]]; then
	sleep 0.5
	echo done!
else
	echo failed!
	end
fi
sleep 0.5

# server
prt-msg starting z-way...
zwy-svr $dev &>/dev/null &
zwy=$!
fail=0
until chk-tcp $tcp; do
	sleep 1
	((fail++))
	if [[ $fail -gt 5 ]]; then
		echo failed!
		end
	fi
done
echo done!
sleep 0.5

# initialise
prt-msg initialising...
sleep 2 &
slp=$!
zwy-arch $dev
wait $slp
echo done!
sleep 0.5

# polling
prt-msg starting poll...
init=0
fail=0
int=1
while chk-pid $zwy; do
	sleep $int
	slp=$!
	poll=$(zwy-poll $dev $ep)
	ep=$(zwy-ep $poll)
	if [ -n "$ep" ]; then
		if [[ $init -eq 0 ]]; then
			echo done!
			init=1
		fi
	else
		((fail++))
	fi
	#if [[ $init -eq 1 ]]; then
	#	sleep 0.5
	#	init=2
	#fi
	if [[ $init -eq 1 ]]; then
		zwy-send $dev
		zwy-parse $dev $poll
		zwy-mains $dev
		zwy-battery $dev
		zwy-zddx $dev
		dev-purge $dev poll &
	fi
	if [[ $fail -gt 5 ]]; then
		echo failed!
		end
	fi
	wait $slp
done

# server
echo z-way error!
end
