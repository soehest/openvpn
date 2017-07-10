##### Openvpn policy based routing

This Git repository contains small scripts for openvpn with policy based routing. Idea and route-up.sh script originated from this [thread](http://lime-technology.com/forum/index.php?topic=33118.0). Thanks Nezil. Primary usage is to allow transmission bittorrent client to operate using only the vpn ip thus hiding your own ip while torrenting. Transmission does not allow one to bind to a interface so one needs to bind it to the vpn ip. As this can (and will) change I have created a script called transmission-helper.sh to automate that process. There are countless of other types of solutions to accomplish this out there, but aiming for simplicity and something actually working I decided to create this. This solution works by routing everything on the vpn interface through the vpn interface (this is a good thing) So every program which is bound to the vpn interface will use that interface and nothing else. If the vpn interface goes down the program will just stop working. It also contains helpers for various programs to automate vpn settings etc.

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
This works for me but may not work for you. It may start giving your real ip to everyone and/or burn your house down. I take no responsibility for any of the above.

##### transmission-helper.sh
UPDATE 11-07-21017
transmission-helper.sh no longer supports arguments. Please edit transmission-helper.sh and set the wanted options.

A simple bash script supporting the following modes:

Supported modes:
BINDIP (bind-ip mode) Transmission does not support binding to an interface (https://trac.transmissionbt.com/ticket/2313) And probabaly never will. A working solution is to use transmission bind-address-ipv4 setting and set it to the ip of the vpn interface. This mode automates the process. It will get the ip of the vpn interface and compare it to the bind-ip of transmission. If they do not match configuration file will be updated with the new bind-ip and signal SIGHUP is sent to transmission (if running) which will reload and activate new bind-ip without need for restarting.
PORTFORWARDING (Portforward mode) Private Internet Access Only. Enables the new updated API (https://www.privateinternetaccess.com/forum/discussion/23431/new-pia-port-forwarding-api) to retrieve a port to use as peer-port for transmission. To use this mode transmission-helper.sh has to be called within two minutes of vpn connection. After two minutes the API will no longer be available. This only needs to be done once, so it is no longer necessary to keep pulling the API. Downside is that one needs to be creative to be able to call the script when the tunnel is up. I call the script at the end of the openvpn route-up script. Just insert 
```bash
/etc/openvpn/transmission-helper.sh & 
```
near the bottom of the file. If not using policy based routing just create a empty route-up script calling transmission-helper.sh

**Contact Info**

**[https://eth0.dk](http://eth0.dk/)**

**soehest**
