#!/bin/bash


ip route replace default via 172.28.0.2 dev eth0


concise_ping () {
	printf "Pinging ${1}: "
	ping -qc1 -w 1 $1 2>&1 | awk -F'/' 'END{ print (/^round/? "OK "$4" ms":"FAIL") }'
}

sleep 1


IP=`hostname -i`
ID=${IP: -3:1}


iperf3 -c 172.28.0.2 -R -f m -i 0 -p 1000$ID

sleep 1

if [ "$ID" == "2" ]; then
	iperf3 -c 172.28.0.2 -R -f m -i 0 -p 10000 -u -b 0 &
	iperf3 -c 172.28.0.2 -R -f m -i 0 -p 1000$ID
else
	sleep 20
fi

concise_ping 172.28.0.2
concise_ping google.com



printf "Testing SHH: "
nc -w 1 -z 172.28.0.2 22 && echo "OK!" || echo "Failed!"
