#!/bin/bash

# args
pnt=$1
val=(${2//,/ })
age=$3

# check
grep - <<< $pnt >/dev/null || exit 1

# initialise
ep=$(get-ep)

# log by interval
opts[3]=60   # every minute
opts[4]=300  # every 5 minutes
opts[5]=900  # every 15 minutes
opts[6]=1800 # every 30 minutes
opts[7]=3600 # every hour

# table
table=data
if ! bms-sql "DESCRIBE $table" &>/dev/null; then
		sql="CREATE TABLE $table"
		sql+="("
    sql+="id INT(11) NOT NULL AUTO_INCREMENT,"
		sql+="point VARCHAR(255) NOT NULL,"
		sql+="value VARCHAR(255),"
		sql+="timestamp VARCHAR(255),"
		sql+="PRIMARY KEY (id),"
		sql+="UNIQUE (point)"
		sql+=")"
		bms-sql $sql
fi

# point logging option

# main
log=0
if [ -n "$age" ]; then
	sql="SELECT timestamp FROM logging WHERE point=\"$pnt\" ORDER BY timestamp DESC LIMIT 1"
	ts=$(bms-sql $sql)
	if [ -z "$ts" ]; then
		log=1
	else
		if [[ $((ep-ts)) -ge $age ]]; then
			log=1
		fi
	fi
else
	sql="SELECT logging FROM points WHERE point=\"$pnt\""
	opt=$(bms-sql $sql)
	if [[ $opt -eq 1 ]]; then
		sql="SELECT value FROM logging WHERE point=\"$pnt\" ORDER BY timestamp DESC LIMIT 1"
		last=$(bms-sql $sql)
		if [ -z "$last" ]; then
			log=1
		else
			if [ "$val" != "$last" ]; then
				log=1
		fi
	elif [[ $opt -eq 2 ]]; then
		log=1
	fi
fi

# log
if [[ $log -eq 1 ]]; then
	sql="INSERT INTO $table (point,value,timestamp) VALUES (\"$pnt\",\"$val\",\"$ts\")"
	bms-sql $sql
fi
