# Lab 02 Network Configuration

## Overview
In this lab, you will practice configuring network connections, routing, and the firewall. The virtual intranet we will be creating is conceptually organized as shown in the sketch at [https://zonzorp.github.io/COMP1071/IMG_3224.jpg](https://zonzorp.github.io/COMP1071/IMG_3224.jpg). The Ubuntu 18.04 network configuration documentation can be found at [https://help.ubuntu.com/lts/serverguide/network-configuration.html.en-CA](https://help.ubuntu.com/lts/serverguide/network-configuration.html.en-CA).

Most of the commands in this lab require root.

## Install software
Install the ethtool, cockpit, nmap, ufw, and traceroute packages. You may find some of these are pre-installed on your distro.
```
sudo apt update
sudo apt upgrade
sudo apt install ethtool cockpit nmap ufw traceroute
```

## Set up static addressing for the server
By default, your server was setup to use DHCP on both interfaces. Leave the first interface (*ens33* on VMWare, *enp0s3* on Virtualbox) set for DHCP, so that we do not lose the ability to reach the internet while at the college. The second interface will be configured to use a static IP configuration. Use `ip addr ens34` or `ip addr enp0s8` to find your current IP address on your second interface. You will want to continue to use the same network number and mask to avoid having to reconfigure the virtual network it is attached to. Change the host part to be host number 99. So if you had an address of 1.2.3.4/24, your new address will be 1.2.3.99/24. Create a new netplan config file named `/etc/netplan/80-comp1071.yaml` and put a static address configuration in it for your second interface. We will be using the dhcp-supplied gateway for reaching the internet, so do not put a gateway into this config file.

#### In file /etc/netplan/80-comp1071.yaml:
```
network:
  version: 2
  renderer: networkd
  ethernets:
    ens34:
      addresses:
        - 1.2.3.99/24
```
In the config file put into /etc/netplan by the Ubuntu installer, disable the lines for the second interface (i.e. *ens34* or *enp0s8*) by putting `#` at the start of those lines.

#### In installer-created yaml files:
```
network:
    ethernets:
        ens33:
            addresses: []
            dhcp4: true
#        ens34:
#            addresses: []
#            dhcp4: true
#            optional: true
    version: 2
```
Run `netplan apply` to apply the new configuration. You will now need to reconnect if you did this using an SSH connection to the old address. Run `ip addr` and verify that your second interface is now statically configured as host *99* on the network. Verify that you can successfully `ping` your new address. Verify that you can ping your host laptop's address on the host-only network (it might be host 1 or it might be host 2 on the host-only network).
```
sudo netplan apply
ip addr
ping -c 1 n.n.n.99
ping -c 1 n.n.n.1
ping -c 1 n.n.n.2
```

## Add some VLANs
Create 3 vlan interface definitions by adding the following configuration to your `/etc/netplan/80-comp1071.yaml` file.

#### In file /etc/netplan/80-comp1071.yaml:
```
  vlans:
    en-vl10:
      id: 10
      link: ens34
      addresses:
        - 172.16.3.2/24
    en-vl20:
      id: 20
      link: ens34
      addresses:
        - 172.16.4.2/24
    en-vl30:
      id: 30
      link: ens34
      addresses:
        - 172.16.5.2/24
```
Run `netplan apply` to apply the new configuration. Run `ip addr` and verify that your second interface has the three vlan addresses showing on it. Verify that you can successfully `ping` your new addresses.
```
ping -c 1 172.16.3.2
ping -c 1 172.16.4.2
ping -c 1 172.16.5.2
```

Use ```ip link show``` and ```ip addr show``` to view your configured interfaces. Note the IP and MAC addresses. Use ```sudo lshw -C network``` and ```sudo ethtool _interfacename_``` to review the types of information available from these commands.

## Set up private routes and enable routing
### Review starting state
Use ```ip route show``` to view your route table.

### Manually add a private route
Use ```sudo ip route add 172.16.6.0/24 via 172.16.3.1``` to add a private static route to a fictitious network through a fictitious router with the address _172.16.3.1_. Run ```ip route``` to show the addition to your route table. Use ```traceroute 172.16.6.1``` to show an attempted trace to the fictitious network. Observe the unreachable host indication. Use ```traceroute gc.blackboard.com``` to view a more successful traceroute.

### Set up persistent static routes in netplan
We will not be setting up additional virtual machines, but we can simulate having a larger network. Add two persistent routes to fictitous networks through two of your vlan interfaces. Modify your `/etc/netplan/80-comp1071.yaml` file in the sections for the vlans to add the desired routes. The end result should look like this:

#### In file /etc/netplan/80-comp1071.yaml:
```
  vlans:
    en-vl10:
      id: 10
      link: ens34
      addresses:
        - 172.16.3.2/24
      routes:
        - to: 172.16.6.0/24
          via: 172.16.3.1
    en-vl20:
      id: 20
      link: ens34
      addresses:
        - 172.16.4.2/24
      routes:
        - to: 172.16.7.0/24
          via: 172.16.4.1
    en-vl30:
      id: 30
      link: ens34
      addresses:
        - 172.16.5.2/24
```
Use ```sudo netplan apply``` to apply your changes. Run `ip route` to verify that your new routes have been added to the kernel's routing table.

## Examine current network connections using netstat
Use ```sudo ss -tp``` to view your active tcp connections. Also try ```sudo ss -tap``` and ```sudo ss -tapn``` to observe the entire list of tcp connections. Start a second terminal window and use it to connect to your server. View the change to the list produced by ```sudo ss -tp```.

## Probe a network host using nmap
Use ```nmap -h``` to review the types of network scans you can do. Try ```nmap neighbourIP``` where neighbourIP is the IP address of your host computer.

## Add your linux server hostname and private routes to your laptop to reach the fictitious networks through your Linux router
On your host laptop OS, add the hostname (e.g. *pcNNNNNNNNN*) and primary IP (e.g. *1.2.3.99*) of your second Linux interface to your host laptop's *hosts* file (`c:\windows\system32\drivers\etc\hosts` on windows, `/etc/hosts` on a Mac).
Add private routes on your laptop to the networks (172.16.3.0/24, 172.16.4.0/24, 172.16.5.0/24) on your linux server, using the linux server as the gateway to reach them (e.g. `ip route add 172.16.3.0/24 via your-linux-server-ip`)(on windows: `route add 172.16.3.0 mask 255.255.255.0 your-linux-server-ip`).
Since we want our Linux server to forward packets between interfaces (act as a router), we need to enable that on the Linux machine. On your Linux machine, the following commands will enable ip forwarding and make the change persistent:
```
sudo sysctl -w net.ipv4.ip_forward=1
sudo sed -i 's/.*net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
```
Verify that the host laptop knows your linux machine hostname and that the private routes work by running the following commands in a *terminal*, *cmd* or *powershell* window:

```
ping pcNNNNNNNNNN
ping 172.16.3.2
ping 172.16.4.2
ping 176.16.5.2
```

## Explore the *cockpit* tool
Connect to the *cockpit* webapp on your server using a web browser to access port *9090* on your server (http://pcNNNNNNN:9090). Login using the account you made for yourself in [Lab 1 System Admin](Lab01-SysMgmt.html). Explore the *cockpit* webapp.

## Set up a basic firewall
View your firewall status.
```
sudo ufw status
```
Add a rule for ssh to be allowed through your firewall and enable the ufw ruleset. Recheck the firewall status to see what changed.
```
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status
```
Try using your web browser to access the *cockpit* webapp. Verify you can no longer access them due to the firewall being turned on. Use the `iptables` low-level command to see the kernel firewall ruleset you now have in place.
```
sudo iptables --list
```
Allow access to *ntopng* and *cockpit* through your firewall and recheck your firewall status to see what changed.
```
sudo ufw allow 9090/tcp
sudo ufw status
```
Verify you can access *cockpit* on your server using a browser again. Explore the system management information you can access using the cockpit webapp.
Refer to the _Ubuntu Server Guide_ for more information on how to use the Linux firewall and *UFW* in particular.

### Evaluate your server
Run ```sudo /root/server-check.sh -l 2 firstname lastname studentnumber```. Review any problems detected and correct as necessary. Do not move on to [Lab 3 DNS](Lab03-DNS.html) until you have Lab 2 at 100%. If you are having trouble getting Lab 2 to 100%, try running ```sudo /root/server-check.sh -l 1 firstname lastname studentnumber``` to make sure you haven't accidentally broken what was completed in [Lab 1 System Admin](Lab01-SysMgmt.html).
