#! /bin/bash


IP_ZONES=("172.28.1.0" "172.28.2.0" "172.28.3.0" "172.28.4.0")
IP_MASK="255.255.255.0"

DEVICE="eth1"


##########
# Egress #
##########

# Root qdisk and class
tc qdisc add dev $DEVICE root handle 1: htb
tc class add dev $DEVICE parent 1: classid 1:1 htb rate 100mbit ceil 100mbit


# Classes for every zone
tc class add dev $DEVICE parent 1:1 classid 1:10 htb rate 40mbit ceil 100mbit
tc class add dev $DEVICE parent 1:1 classid 1:11 htb rate 20mbit ceil 100mbit
tc class add dev $DEVICE parent 1:1 classid 1:12 htb rate 20mbit ceil 100mbit
tc class add dev $DEVICE parent 1:1 classid 1:13 htb rate 20mbit ceil 100mbit

# Classes for udp/tcp traffic for zone 2
tc class add dev $DEVICE parent 1:11 classid 1:20 htb prio 1 rate 20mbit ceil 100mbit
tc class add dev $DEVICE parent 1:11 classid 1:21 htb prio 2 rate 1kbit ceil 100mbit

# Outgoing traffic filters
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
 	match ip src ${IP_ZONES[0]}/24 flowid 1:10
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
 	match ip src ${IP_ZONES[1]}/24 flowid 1:11
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
	match ip src ${IP_ZONES[2]}/24 flowid 1:12
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
	match ip src ${IP_ZONES[3]}/24 flowid 1:13

# Incoming traffic filters
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
 	match ip dst ${IP_ZONES[0]}/24 flowid 1:10
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
 	match ip dst ${IP_ZONES[1]}/24 flowid 1:11
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
	match ip dst ${IP_ZONES[2]}/24 flowid 1:12
tc filter add dev $DEVICE protocol ip parent 1:0 prio 1 u32 \
	match ip dst ${IP_ZONES[3]}/24 flowid 1:13

# Filters for TCP/UDP prioritizing
tc filter add dev $DEVICE protocol ip parent 1:11 prio 1 u32 \
	match ip protocol 17 0xff flowid 1:20

tc filter add dev $DEVICE protocol ip parent 1:11 prio 2 matchall \
	classid 1:21


###########
# Ingress #
###########

tc qdisc add dev $DEVICE handle ffff: ingress

# Drop SSH from zone 3
tc filter add dev $DEVICE parent ffff: protocol ip prio 1 u32 \
    match ip src ${IP_ZONES[2]}/24\
    match ip dport 22 0xffff\
    action drop

# Drop ICMP from all zones
tc filter add dev $DEVICE parent ffff: protocol ip prio 1 u32 \
    match ip src ${IP_ZONES[0]}/24\
    match ip protocol 1 0xff\
    action drop
tc filter add dev $DEVICE parent ffff: protocol ip prio 1 u32 \
    match ip src ${IP_ZONES[1]}/24\
    match ip protocol 1 0xff\
    action drop
tc filter add dev $DEVICE parent ffff: protocol ip prio 1 u32 \
    match ip src ${IP_ZONES[2]}/24\
    match ip protocol 1 0xff\
    action drop
tc filter add dev $DEVICE parent ffff: protocol ip prio 1 u32 \
    match ip src ${IP_ZONES[3]}/24\
    match ip protocol 1 0xff\
    action drop




iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

iperf3 -s -f m -i 0 -p 10001 >/dev/null &
iperf3 -s -f m -i 0 -p 10002 >/dev/null &
iperf3 -s -f m -i 0 -p 10003 >/dev/null &
iperf3 -s -f m -i 0 -p 10004 >/dev/null &
iperf3 -s -f m -i 0 -p 10000 >/dev/null &
iperf3 -s -f m -i 0 -p 22 2>/dev/null >/dev/null &

sleep 60