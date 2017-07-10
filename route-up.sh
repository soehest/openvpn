#!/bin/sh

# Checks to see if there is an IP routing table named 'vpn', create if missing
if [ $(cat /etc/iproute2/rt_tables | grep vpn | wc -l) -eq 0 ]; then
        echo "100     vpn" >> /etc/iproute2/rt_tables
fi

echo "------------------------------------------------------------------"
/bin/ip route show
echo "------------------------------------------------------------------"

# Remove any previous routes in the 'vpn' routing table
/bin/ip rule | sed -n 's/.*\(from[ \t]*[0-9\.]*\).*vpn/\1/p' | while read RULE
do
	echo "remove old rule:  /bin/ip rule del ${RULE}"
	/bin/ip rule del ${RULE}
done

# Delete the default route setup when the OpenVPN tunnel was established
/bin/ip route del 128.0.0.0/1 via ${route_vpn_gateway}
/bin/ip route del 0.0.0.0/1 via ${route_vpn_gateway}

# Add routes to the vpn routing table
echo ip rule add from $ifconfig_local lookup vpn
/bin/ip rule add from ${ifconfig_local} lookup vpn

# Add the route to direct all traffic using the the vpn routing table to the tunX interface
echo ip route add default dev ${dev} table vpn
/bin/ip route add default dev ${dev} table vpn

#/etc/openvpn/transmission-helper.sh &
exit 0
