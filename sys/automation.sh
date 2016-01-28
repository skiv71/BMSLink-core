#!/bin/bash

# initialise
path=$(bms-temp)
int=1
rpt=5

# check
[ -n "$path" ] || exit 1

# functions
end() {
  prt-sep
  prt-msg stopping automation controller
  exit 0
}

# traps
trap 'echo && end' SIGINT
trap end SIGTERM SIGHUP

# start
path+=/auto
chk-dir $path || mkdir -p $path

# sql
table=automation
sql="select name,script from $table where enabled=1"

# main
prt-sep
prt-msg starting automation controller!

# loop
while :; do
	sleep $int
	slp=$!
	bms-sql $sql | {
		while read line; do
			name=($line)
			file=$path/$name
			if chk-file $file; then
				[[ $(file-age $file) -ge $rpt ]] || continue
			fi
			code="$(prt-und ${name[1]})"
			par-auto $code > $path/.script
			chmod +x $path/.script
			$path/.script
			if [[ $? -eq 2 ]]; then
				prt-sep
				prt-msg exec, $name
				prt-msg code, $code
				mv $path/.script $file
			fi
		done
	}
	wait $slp
done
