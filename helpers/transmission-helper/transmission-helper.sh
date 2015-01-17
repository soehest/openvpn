#!/bin/bash
#Version 0.0.1
DATE=`date +%H:%M:%S`
INTERFACE="tun0"
USERNAME="PUTUSERNAMEHERE"
PASSWORD="PUTPASSWORDHERE"
PORTFORWARDING="yes"
LOGGING="true"
LOGFILE="/tmp/transmission-helper.log"
CLIENTIDFILE="/tmp/clientid"
PIDFILE="/var/run/transmission/transmission.pid"
TRANSMISSIONCONFIG="/var/lib/transmission/config/settings.json"

usage(){
  echo "Usage: $0 OPTIONS"
  echo "Supported modes:"
  echo "-i (ip mode)"
  echo "-p (Portforward mode)"
  echo "-q quiet (no output except errors)"
  echo "See readme for instructions."
  exit 1
}

output(){
  if ! [ "$quiet" = "true" ]; then
    echo $*
  fi
  if [ "$LOGGING" = "true" ]; then
    echo "[$(date)]: $*" >> $LOGFILE
  fi
}

function log {
  echo "[$(date)]: $*" >> $LOGFILE
}

writebindip(){
  sed -i 's/\(\"bind-address-ipv4\":\).*,/\1 '"\"$1"\"',/' $TRANSMISSIONCONFIG
  output "$TRANSMISSIONCONFIG changed."
}

writepeerport(){
  sed -i 's/\(\"peer-port\":\).*,/\1 '"$1"',/' $TRANSMISSIONCONFIG
  output "$TRANSMISSIONCONFIG changed."
}


if [ "$LOGGING" = "true" ]; then
  log "$0 called with $@"
fi

while getopts ":ipq" opt; do
  case $opt in
    i)
      ip=true
    ;;
    p)
      portforward=true
    ;;
    q)
      quiet=true
    ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
    ;;
  esac
done

if [[ -z $ip ]] && [[ -z $portforward ]]; then
  usage
  exit 1
fi

if ! /bin/ifconfig $INTERFACE >>/dev/null 2>&1; then
  output "interface $INTERFACE not found, exiting"
  exit 1
fi

if ! [ -f $TRANSMISSIONCONFIG ]; then
  output "$TRANSMISSIONCONFIG not found, exiting"
  exit 1
fi

vpnip=$(ip -f inet -o addr show tun0|cut -d\  -f 7 | cut -d/ -f 1)
output "$INTERFACE ip: $vpnip"
if [ -f $PIDFILE ]; then
  output "Status Transmission: [UP]"
  pid=$(cat $PIDFILE)
  output "Transmission pid: $pid"
  running=true
else
  output "Status Transmission: [DOWN]"
fi

if [ "$ip" = "true" ]; then
  transmissionip=$(sed -n 's/.*"bind-address-ipv4": "\(.*\)",.*/\1/p' $TRANSMISSIONCONFIG)
  output "bind-ip from $TRANSMISSIONCONFIG: $transmissionip"
  if ! [ "$vpnip" == "$transmissionip" ]; then
    output "Ip changed. Writing new ip to $TRANSMISSIONCONFIG"
    writebindip $vpnip
    update=true
  fi
fi

if [ "$portforward" = "true" ]; then
  if [ -f $CLIENTIDFILE ]; then
    client_id=$(cat $CLIENTIDFILE)
  else
    client_id=`head -n 100 /dev/urandom | md5sum | tr -d " -"`
    echo $client_id > $CLIENTIDFILE
  fi
  transmissionport=$(sed -n 's/.*"peer-port": \(.*\),.*/\1/p' $TRANSMISSIONCONFIG)
  output "peer-port from $TRANSMISSIONCONFIG: $transmissionport"
  currentport=`wget --bind-address=$vpnip -q --post-data="user=$USERNAME&pass=$PASSWORD&client_id=$client_id&local_ip=$vpnip" -O - 'https://www.privateinternetaccess.com/vpninfo/port_forward_assignment' | head -1 | grep -oE "[0-9]+"`
  output "peer-port from https://www.privateinternetaccess.com $currentport"
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
