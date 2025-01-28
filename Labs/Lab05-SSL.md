# Lab 5 SSL Enabled Services

## Overview
This lab provides an introduction to working with SSL-enabled services. The primary focus is on creating certificates and deploying them for use with Apache2 web service.

## Create a virtual website for the hostname **secure** in your private domain

### Create a document root and a default webpage
In lab 4 we created a directory named **/sites** to hold the document directories for our virtual websites. Create a directory named **secure.yourdomain** in the existing **/sites** directory. Add an **index.html** to the **/sites/secure.yourdomain** directory with content to identify that page as the home page for your site (e.g. _This is the SSL-protected home page for secure.yourdomain_). This will be the document store for your ssl-enabled website.

### Add the hostname secure to your DNS
Add the name **secure** to the zone file (e.g. **/etc/bind/db.yourdomain**) for **yourdomain** as a **CNAME** for **ns1** (e.g. ```secure IN CNAME ns1```). Verify you can successfully ```ping secure.yourdomain```.

## Setup a private certificate authority
Since more or less all the commands in this section require root, I suggest getting a root shell (`sudo bash`) and running the commands to make the CA and the certificates and keys in that shell. Don't forget to exit the root shell before continuing with the next section in the lab. Install the **easy-rsa** package. Use ```make-cadir``` to create a default software directory for your CA. Use that directory to create a pki with a CA certificate and key to use for issuing private certificates. The commands to accomplish these tasks could look like this:

```
sudo bash
apt update
apt install easy-rsa
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa --req-cn=COMP1071 --batch build-ca
```

You should be able to just confirm default answers for any choices presented by build-ca and make sure to use a password for the CA private key that you can remember. This is only a lab, so you don't need a strong password. Make a subdirectory named **comp1071** in your **/usr/share/ca-certificates** directory and copy your new CA certificate file from **/etc/openvpn/easy-rsa/pki/ca.crt** to it. Make the CA certificate file world-readable.
```
mkdir /usr/share/ca-certificates/comp1071
cp /etc/openvpn/easy-rsa/pki/ca.crt /usr/share/ca-certificates/comp1071/
chmod 644 /usr/share/ca-certificates/comp1071/ca.crt
```
Run the ca-certificates software package install script to install your ca.crt as a trusted root certificate.
```
dpkg-reconfigure ca-certificates
```
When the config screen comes up, you can choose **Yes** to install a new certificate, then press **space** to enable your ca.crt file in comp1071, then press **enter** to make the change take effect.

## Create a certificate and key file for the website **secure.yourdomain**
Create a key and certificate for the name **secure.yourdomain** uisng an Organization name of COMP1071, a common name of secure.yourdomain, and an email address of hostmaster@yourdomain. You may use any other information that is is valid for the locaiton information, but the Organization name must be COMP1071. Again, this is only a lab so use a password that is easy to remember for the server's private key file. When you sign the request, you will have to give your CA private key password from the previous steps.

```
cd /etc/openvpn/easy-rsa
./easyrsa gen-req secure.yourdomain
./easyrsa sign-req server secure.yourdomain
```

Once you have requested and signed the secure server's certificate, copy the crt and key files for that server from the pki subdirectory into **/etc/ssl**. Put the certificate file in the certs subdirectory, and the key file in the private subdirectory.

```
cp pki/issued/secure.yourdomain.crt /etc/ssl/certs/
cp pki/private/secure.yourdomain.key /etc/ssl/private/
```

## Create the virtual website configuration file
Create a virtual website for **secure.yourdomain** as an ssl-enabled website. Begin by copying the **default-ssl.conf** site file in **/etc/apache2/sites-available** to a file named **secure.yourdomain.conf** in **/etc/apache2/sites-available**.
```
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/secure.yourdomain.conf
```
Configure the file by modifying at least _VirtualHost_, _ServerAdmin_, _ServerName_, _SSLCertificateFile_, _SSLCertificateKeyFile_, _DocumentRoot_ and _Directory_ stanza for your _DocumentRoot_.
```
nano /etc/apache2/sites-available/secure.yourdomain.conf
```
An example file might look like this:

```
<IfModule mod_ssl.c>
	<VirtualHost secure.simpson.mytld:443>
		ServerName secure.simpson.mytld
		ServerAdmin webmaster@simpson.mytld

		DocumentRoot /sites/secure.simpson.mytld
		<Directory /sites/secure.simpson.mytld>
			Require all granted
		</Directory>

		SSLEngine on
		SSLCertificateFile /etc/ssl/certs/secure.simpson.mytld.crt
		SSLCertificateKeyFile /etc/ssl/private/secure.simpson.mytld.key

		<FilesMatch "\.(cgi|shtml|phtml|php)$">
				SSLOptions +StdEnvVars
		</FilesMatch>
		<Directory /usr/lib/cgi-bin>
				SSLOptions +StdEnvVars
		</Directory>

		BrowserMatch "MSIE [2-6]" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0
		BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
	</VirtualHost>
</IfModule>
```

## Turn on SSL for the apache2 server
Enable the ssl module for Apache2. Enable your site and restart your apache service. You will need to enter the password for the server's private key in order to start the server. Whenever you start any service that needs to ask for a password for a protected resource such as a private key file, you will need to give the password before the service will complete startup. If the startup is not interactive such as when the system boots, you will need to use the `systemd-tty-ask-password-agent --query` command to enter the password. If you see the `systemd-ask-password` process when you run `systemctl status apache2` command, it means you have not successfully given the password and the service has not completed startup. Using `systemctl reload` may not require entering passwords, as it only re-reads configuration files. If the protected resources have not changed in the config files, no password is needed.
```
a2enmod ssl
a2ensite secure.yourdomain
systemctl restart apache2
```

## Allow web access to the ssl-enabled site through your firewall
Add a UFW rule to allow secure web browsing service through your firewall.
```
ufw allow 443/tcp
```

Verify you can access the site in a terminal window.
```
wget -O - https://secure.yourdomain
```
Verify you can access your personal home page on your new site using https with a web browser on your host laptop. You may need to add the hostname secure.yourdomain to your host laptop's hosts file, and check that you still have the private route on your host laptop to the 172.16.3.0/24 network through your host 99 address. To test for those things, consider doing `ping 172.16.3.2` and `ping secure.yourdomain` in a command line terminal window on your host laptop.

## Review log files
Examine the content of **access.log** and **error.log** in **/var/log/apache2** to see what is being logged for your activity on your web server.

### Evaluate your server
Run ```sudo /root/server-check.sh -l 5 firstname lastname studentnumber```. Review any problems detected and correct as necessary. Do not move on to [Lab 6 MySQL](Lab06-Mysql.html) until you have Lab 5 at 100%. If you are having trouble getting Lab 5 to 100%, try running ```sudo /root/server-check.sh -l 1234 firstname lastname studentnumber``` to make sure you haven't accidentally broken what was completed in previous labs.
