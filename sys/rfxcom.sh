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

# config
prt-msg configuring...
rfx-cfg $dev
if [[ $? -eq 0 ]]; then
	sleep 0.5
	echo done!
else
	echo failed!
	end
fi
sleep 0.5

# dump
prt-msg dumping port...
rfx-listen $dev dump
sleep 0.5
echo done!
sleep 0.5

# listen
prt-msg opening port...
rfx-listen $dev &
sleep 0.5
echo done!

# main
fail=0
init=0
n=0
while chk-pid $con; do
	if [[ $init -eq 0 ]]; then
		rfx-hex $dev init
		rfx-init $dev
		init=1
	fi
	for file in $(rfx-hex $dev); do
		hex=$(<$file)
		if [[ $init -eq 1 ]]; then
			if [ "${hex:0:6}" = "0D0100" ]; then
				init=2
				echo done!
			else
				((fail++))
			fi
			if [[ $fail -ge 5 ]]; then
				echo failed!
				sleep 1
				fail=0
				init=0
			fi
		fi
		if [[ $init -eq 2 ]]; then
			rfx-send $dev
			rfx-data $dev $file
		fi
	done
	((n++))
	if [[ $n -gt 600 ]]; then
		dev-purge $dev listen
		n=0
	fi
	sleep 0.1
done

# error
prt-msg port error!
end
