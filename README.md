##### Openvpn policy based routing

This Git repository contains small scripts for openvpn with policy based routing. Idea and route-up.sh script originated from this [thread](http://lime-technology.com/forum/index.php?topic=33118.0). Thanks Nezil. Primary usage is to allow transmission bittorrent client to operate using only the vpn ip thus hiding your own ip while torrenting. Transmission does not allow one to bind to a interface so one needs to bind it to the vpn ip. As this can (and will) change I have created a script called transmission-helper.sh to automate that process. There are countless of other types of solutions to accomplish this out there, but aiming for simplicity and something actually working I decided to create this. This solution works by routing everything on the vpn interface through the vpn interface (this is a good thing) So every program which is bound to the vpn interface will use that interface and nothing else. If the vpn interface goes down the program will just stop working.

Openvpn prerequisites:
You will need to have openvpn running. Installation of openvpn is out of the scope of this project. You should be able to find a guide for your distribution using your favorite search site. With a working openvpn you will need to make a few additions to your openvpn.conf file. Following lines need to be added at bottom of your openvpn.conf

```bash
script-security 3
route-delay 5
route-up "/etc/openvpn/route-up.sh"
keepalive 10 60
```
Remember to specify the correct path for the route-up.sh script. The script is located in the repository and should be copied to the correct destination. This script is run after openvpn is started and will configure and setup a second routing table for the vpn connection.

Kernel requirements:  
To configure policy based routing the following options needs to be enabled in the kernel:
Networking, Networking support, TCP/IP networking:

CONFIG_IP_ADVANCED_ROUTER=y (IP: advanced router)  
CONFIG_IP_MULTIPLE_TABLES=y (IP: policy routing)  
CONFIG_IP_ROUTE_MULTIPATH=y (IP: equal cost multipath)  

To test if your openvpn setup is working with multiple routes use the included test-routes.sh. Please edit file before running.

Current helpers included:
transmission-helper.sh

Readme's for helpers are located in the bottom of this readme. (Cool stuff here. a readme in a readme)

This repository was created as I did spend a bit of time to code and think others could have use for this. You are most welcome to add new helpers.

#####Disclaimer:
This works for me but may not work for you. It may start giving your real ip to everyone and/or burn your house down. I take no responsibility for any of above or anything else for that matter.

##### transmission-helper.sh
Usage: ./transmission-helper.sh OPTIONS  
Supported modes:  
-i (ip mode)  
-p (Portforward mode)  
-q quiet (no output except errors)  
See readme for instructions.  

A simple bash script which will on run and depending of supplied options will check the current ip on interface specified in the bash file and compare it against the ip of transmission. If they do not match the new ip is written to settings.json and signal SIGHUP will be sent to transmission (if transmission is running) which will reload the new settings without need for restart. If using privateinternetaccess there is also a portforward mode which will do the same as above but for the incoming port. Before first run please edit transmission-helper.sh and set the correct variables.

I recommend adding transmission-helper.sh to your transmission init.d script to ensure you do not fire up your transmission when the vpn is not running. I do this by adding:

```bash
/usr/local/bin/transmission-helper.sh -ip
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
```

before the init.d will start up transmission. If any error it should stop executing the init.d script.  


**Contact Info**

**[http://eth0.dk](http://eth0.dk/)**

**soehest**
