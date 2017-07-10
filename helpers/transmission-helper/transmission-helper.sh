#!/bin/bash
#Version 0.0.2 (11-07-2017)
DATE=`date +%H:%M:%S`
VPNINTERFACE="tun0"
PORTFORWARDING="YES" # Enable Private Internet Access (PIA) port forwarding
BINDIP="YES" # Enable transmission bind ip : [YES/NO]
LOGGING="YES" # Enable Logging : [YES/NO]
LOGFILE="/tmp/transmission-helper.log"
QUIET="YES" # Enable quiet mode (no output except errors) : [YES/NO]
CLIENTIDFILE="/tmp/clientid"
PIDFILE="/var/run/transmission/transmission.pid"
TRANSMISSIONCONFIG="/etc/transmission-daemon/settings.json"

sleep 5

output(){
  if ! [ "$QUIET" = "YES" ]; then
    echo $*
  fi
  if [ "$LOGGING" = "YES" ]; then
    echo "[$(date)]: $*" >> $LOGFILE
  fi
}

writebindip(){
  sed -i 's/\(\"bind-address-ipv4\":\).*,/\1 '"\"$1"\"',/' $TRANSMISSIONCONFIG
  output "$TRANSMISSIONCONFIG changed."
}

writepeerport(){
  sed -i 's/\(\"peer-port\":\).*,/\1 '"$1"',/' $TRANSMISSIONCONFIG
  output "$TRANSMISSIONCONFIG changed."
}

PARENT_COMMAND=$(ps $PPID | tail -n 1 | awk "{print \$5}")

if [ "$LOGGING" = "YES" ]; then
  output "$0 called from $PARENT_COMMAND"
fi

vpnip=$(ip -f inet -o addr show tun0|cut -d\  -f 7 | cut -d/ -f 1)
output "$VPNINTERFACE IP [$vpnip]"
if [ -f $PIDFILE ]; then
  pid=$(cat $PIDFILE)
  output "Status Transmission: [UP] PID ($pid)"
  running=true
else
  output "Status Transmission: [DOWN]"
fi


if [ "$BINDIP" = "YES" ]; then
  transmissionip=$(sed -n 's/.*"bind-address-ipv4": "\(.*\)",.*/\1/p' $TRANSMISSIONCONFIG)
  output "IP from $TRANSMISSIONCONFIG [$transmissionip]"
  output "IP from openvpn [$vpnip]"
  if ! [ "$vpnip" == "$transmissionip" ]; then
    output "IP changed. Writing new ip to $TRANSMISSIONCONFIG"
    writebindip $vpnip
    update=true
  fi
fi

if [ "$PORTFORWARDING" = "YES" ]; then
  if [ -f $CLIENTIDFILE ]; then
    client_id=$(cat $CLIENTIDFILE)
  else
    client_id=`head -n 100 /dev/urandom | sha256sum | tr -d " -"`
    echo $client_id > $CLIENTIDFILE
  fi
  transmissionport=$(sed -n 's/.*"peer-port": \(.*\),.*/\1/p' $TRANSMISSIONCONFIG)
  output "peer-port from $TRANSMISSIONCONFIG: ($transmissionport)"
  #currentport=`wget --bind-address=$vpnip -q -O - "http://209.222.18.222:2000/?client_id=$client_id" | head -1 | grep -oE "[0-9]+"`
  currentport=`curl -f -s -S --interface $VPNINTERFACE "http://209.222.18.222:2000/?client_id=$client_id" | head -1 | grep -oE "[0-9]+"`
  if [ -z "$currentport" ]; then
    output "Unable to get port from Private Internet Access"
    exit 1
  fi
  output "peer-port from https://www.privateinternetaccess.com ($currentport)"
  if ! [ "$currentport" == "$transmissionport" ]; then
    output "Port changed. Writing new port to $TRANSMISSIONCONFIG"
    writepeerport $currentport
    update=true
  fi
  #exit
fi

if [ "$update" = "true" ] && [ "$running" = "true" ]; then
  output "Changes detected. sending SIGHUP to transmission pid ($pid)"
  kill -SIGHUP $pid
fi
