#!/bin/bash

command=''

open () {
echo "$0 args[]"
}

if [ "$#" -eq 0 ] 
then
	open;
	exit 1;
elif [ "$#" -eq 1 ]
then
	command="grep $@ /etc/apache2/logs/error_log"
	echo "$command"
elif [ "$#" -gt 1 ]
then
	declare -a array=($@)
	echo "${array[1]}"
	command="grep $1 /etc/apache2/logs/error_log"
	for (( i=2;i<=$#;i++))
	do
		command="$command | grep ${array[2]}"
	done
	echo "$command"
fi

grep $1 /etc/apache2/logs/error_log | egrep 'ModSecurity: Access denied' | sed -r "s/.*(.*) .*(\[id [\"0-9]{8,10}\]).* .*(\[hostname [-\"._a-zA-Z0-9]+\]).* *.(\[uri [-\..\_\"0-9a-zA-Z/].*\]).* (.*)/\4 --> \2  /" | sort -u | sed 's/^\[uri //;s/\] --> \[id/:/' | sed -r 's/(\]|\"| )//g' | grep -E ".php:[0-9]*" > /root/modsecgrep.txt
firstfile=`head -1 /root/modsecgrep.txt | cut -d: -f1`
for line in `cat /root/modsecgrep.txt | cut -d: -f1 | sort -u | grep -E '.php$'`;
do
	echo "<LocationMatch '$line'>"
	for ruleid in $(grep $line /root/modsecgrep.txt | awk -F":" '{print $NF}');
	do
		echo -e "\tSecRuleRemoveById \"$ruleid\""
	done
	echo '</LocationMatch>'
	line=`echo $line | sed 's@/@\\\/@g'`
#	echo $line
#	sed -i -r "/$line/d" /root/modsecgrep.txt
	echo
done
