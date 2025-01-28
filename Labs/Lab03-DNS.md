# Lab 03 - DNS

## Overview
In this lab, you will set up a dns server populated with domains useful for the rest of the semester. You will also practice configuring your server to use a private dns server in addition to the default server(s) on the network. This lab exercise requires that you have completed [Lab 2 Network Configuration](Lab02-NetworkConfig.md) before starting Lab 3. If you have not successfully completed Lab 2, various things in this lab are not possible to accomplish.

## Install Software
Install the **bind9**, **dnsutils**, and **nscd** packages.

## DNS Service Configuration

For the configuration files, you can refer to the examples in the _Ubuntu Server Guide_. Add a zone file for a domain named **yourlastnameNNNNN.mytld**, where the **NNNNN** is the last 5 digits of your student number. For example, a lastname of **chan** and a student number of **12345678** would make the domain name **chan45678.mytld**. The zone origin will be **ns1.yourlastnameNNNNN.mytld**. Your zone will have 1 nameserver, **ns1.yourlastnameNNNNN.mytld**. For all our DNS activity in this course, the zone names are the exact same as the domain names.

The zone should have the following hostnames configured:

```
router3 as 172.16.3.1
ns1 as 172.16.3.2
www as 172.16.4.2
mail as 172.16.5.2
pop as an alias for mail
```

This is an example file:

```
;
; Data file for sim.mytld
;
$TTL	604800
@	IN	SOA	ns1.sim.mytld. hostmaster.sim.mytld. (
		     2015010100		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	ns1
ns1	IN	A	172.16.3.2
;
router3	IN	A	172.16.3.1
www	IN	A	172.16.4.2
mail	IN	A	172.16.5.2
pop	IN	CNAME	mail
```

Next add the reverse lookup zones for your IP addresses. Each of these will have ns1.yourlastnameNNNNN.mytld as the origin and nameserver, with no slave nameserver.

Add a zone for 172.16.3.0/24 (i.e. 3.16.172.in-addr.arpa.). The zone should have the following addresses configured:

```
1 as router3.yourlastnameNNNNN.mytld.
2 as ns1.yourlastnameNNNNN.mytld.
```

This is an example file:

```
;
; Data file for 172.16.3.0/24 (3.16.172.in-addr.arpa)
;
$TTL	604800
@	IN	SOA	ns1.sim.mytld. hostmaster.sim.mytld. (
		     2015010100		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	ns1.sim.mytld.
1	IN	PTR	router3.sim.mytld.
2	IN	PTR	ns1.sim.mytld.
```

Add a zone for 172.16.4.0/24 (i.e. 4.16.172.in-addr.arpa.). The zone should have the following addresses configured:

```
2 as www.yourlastnameNNNNN.mytld.
```

Add a zone for 172.16.5.0/24 (i.e. 5.16.172.in-addr.arpa.). The zone should have the following addresses configured:

```
2 as mail.yourlastnameNNNNN.mytld.
```

Verify your zones are syntactically correct using ```named-checkzone domainname zonefile```.

Configure all of your new zones into **named.conf.local**. Verify you have it syntactically correct with ```named-checkconf```.

This is an example file:

```
zone "sim.mytld" {
	type primary;
	file "/etc/bind/db.sim.mytld";
};

zone "3.16.172.in-addr.arpa" {
	type primary;
	file "/etc/bind/db.172.16.3";
};

```

Now we can add Google's DNS for DNS forwarding. We will do this because you may be doing this lab on a network or ISP that blocks recursive DNS (they may be trying to stop you from running your own DNS server). We will only forward external DNS lookups so that our own private domain names continue to be looked up locally. Add the following line into your `/etc/bind/named.conf.options` file, immediately after the currently commented-out forwarders line. **Do not remove the `//` symbols from the lines that are already in the file for forwarding.**
```
	forwarders { 8.8.8.8; };
```
	

## Set up firewall rules for DNS
Add a ufw rule to allow DNS service ( ```ufw allow domain``` ) through your firewall.

## Reload the DNS configuration to start serving your private domain
Reload bind using ```rndc reload```. Verify you can use nslookup successfully for ns1.yourlastnameNNNNN.mytld using your new name server as the query server (e.g. ```nslookup ns1.yourlastnameNNNNN.mytld 172.16.3.2```). What happens when you try ```nslookup ns1.yourlastnameNNNNN.mytld```?

## Set up persistent use of your private nameserver whenever its interface is up
Adding your domain name to be used for automatic searching and using your private DNS server is done using netplan. You could modify the existing `/etc/netplan/80-comp1071.yaml` file, or you can create an additional file with just the settings you want to add. To keep things simple, we will just modify our existing file to add the nameservers mapping lines under the interface that our nameservice runs on. So that section might now look like this example file:
```
    en-vl10:
      id: 10
      link: ens38
      addresses:
        - 172.16.3.2/24
      routes:
        - to: 172.16.6.0/24
          via: 172.16.3.1
      nameservers:
        addresses: [172.16.3.2]
        search: [simpson.mytld]
```
Run `netplan apply` to apply the new configuration.

## Configure the systemd-resolved name resolver to use our nameserver
The systemd-resolved name resolver can be configured to use our nameserver by adding the following line to your `/etc/systemd/resolved.conf` file.
```bash
sudo sed -i -e 's/^#DNS=.*/DNS=172.16.3.2/' /etc/systemd/resolved.conf
```
Check that these commands do not produce errors:
```bash
nslookup ns1.yourlastnameNNNNN.mytld
dig ns1.yourlastnameNNNNN.mytld
nslookup www.yourlastnameNNNNN.mytld
nslookup router3.yourlastnameNNNNN.mytld
nslookup mail.yourlastnameNNNNN.mytld
nslookup pop.yourlastnameNNNNN.mytld
nslookup 172.16.3.2
nslookup 172.16.4.2
nslookup 172.16.5.2
nslookup georgiancollege.ca
apt update
```
If any of these fail, ask your professor for help before proceeding with the rest of the lab.

## Configure your host laptop to recognize the names in our private domain
Choose and implement a method for your host laptop to use the hostnames we are adding to our private dns server. You can add that server to your dns server list on your host laptop, or add entries to your hosts file on the host laptop. Verify that the names work by using ping or traceroute on your host laptop to the name www.yourdomain. Ensure you have completed adding routes from your host laptop to the linux server as described at the end of lab 2 before trying this.

### Evaluate your server
Run ```sudo /root/server-check.sh -l 3 firstname lastname studentnumber```. Review any problems detected and correct as necessary. Do not move on to [Lab 4 Apache2](Lab04-Apache2.html) until you have Lab 3 at 100%. If you are having trouble getting Lab 3 to 100%, try running ```sudo /root/server-check.sh -l 12 firstname lastname studentnumber``` to make sure you haven't accidentally broken what was completed in previous labs.
