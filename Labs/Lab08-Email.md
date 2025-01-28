# Lab 8 Email Services

## Overview

In this lab, you will install and configure basic email MTA, MUA, and email web app functionality with postfix, dovecot, and roundcube software.
We will be setting up an Internet site email server for our domain. We are not adding any advanced functions, but simply setting up the basic MTA/MDA and then adding a web application MUA to access the mail on our server.
To do this, we will be taking the following actions:
1. Add an MX record for our email domain name to our DNS
1. Create a custom SSL certificate to use on our MTA
1. Allow email servce through the firewall
1. Install the MTA/MDA/MUA software

## Set up the email server hostname in your domain and set it as the MX host in your domain

Add an **MX** record for your domain, with a target of **mail.yourdomain.mytld** and a priority of **10**. In your zone file (_/etc/bind/db.yourdomain_) the record will look like: ```@ IN MX 10 mail```. Reload your dns and verify you can ```ping mail.yourdomain``` and that you can retrieve the **MX** record for yourdomain and get **mail.yourdomain** as the response. Verify that you can ```nslookup mail.yourdomain``` and get **172.16.5.2 as the address**. Do not proceed until these nslookups work correctly.

### Example zone file after adding MX record:
```
;
; created 2018-10-08 by dennis
; modified 2018-10-30 by dennis to add hostname secure as an alias for ns1
; modified 2018-11-20 by dennis to add MX record for the domain to point to mail host with priority 10
;
$TTL	86400
@	IN	SOA	ns1.simpson.mytld. hostmaster.simpson.mytld. (
			      2018112000		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	NS	ns1
@ IN  MX  10 mail
ns1	IN	A	172.16.3.2
www	IN	A	172.16.4.2
mail	IN	A	172.16.5.2
router3	IN	A	172.16.3.1
pop	IN	CNAME	mail
secure	IN	CNAME	ns1
```

### Commands to modify zone file to add the MX record and test:
```bash
edit /etc/bind/db.yourdomain
rndc reload
ping mail
nslookup -querytype=MX yourdomain
nslookup mail.yourdomain
```

## Create a certificate and key for use with your mail server

Since we are only really concerned with having encryption for mail transport, we don't usually create real certificates for mail servers. But it is good practice and this is a course lab. Generate an SSL certificate and key for use with your mail server:

```
cd /etc/openvpn/easy-rsa
./easyrsa gen-req mail.yourdomain
./easyrsa sign-req server mail.yourdomain
```

Once you have requested and signed the mail server's certificate, copy the crt and key files for that server from the pki subdirectory into **/etc/ssl**. Put the certificate file in the certs subdirectory, and the key file in the private subdirectory.

```
cp pki/issued/mail.yourdomain.crt /etc/ssl/certs/
cp pki/private/mail.yourdomain.key /etc/ssl/private/
```

## Add firewall rules to allow email to pass
Even though we have no other machines to really communicate with our mail server, add UFW rules to allow email service through your firewall:

```bash
ufw allow 25/tcp
ufw allow 587/tcp
ufw allow 110/tcp
ufw allow 143/tcp
ufw allow 465/tcp
ufw allow 993/tcp
ufw allow 995/tcp
```

## Install email software

Install the postfix and dovecot software packages. Once they are installed configure them to work together. I have given you the settings that will tell postfix to use dovecot for SASL authentication, and correct the mail server hostname. You will need to manually edit the dovecot SSL configuration file to specify the correct key and certificate file to use. 

```bash
sudo apt update
sudo apt install postfix dovecot-common dovecot-core dovecot-imapd dovecot-pop3d roundcube
nano /etc/dovecot/conf.d/10-ssl.conf
```

During the installation of the packages, you may be asked some questions. Specify **Yes** to use dbconfig-common to configure the roundcube database, leave the applicaiton password blank, specify your **site type** to be **Internet Site** and specify **yourdomainname** as the **mail system name** for your server. 

## Postfix Installation Review and Modification
Check that the email services are running.
```bash
service dovecot status
service postfix status
```

Check that the ports are being listened to, and see what the running program names are. Look for the port numbers associated with email service from the presentation.
```bash
sudo ss -tlpn
```

Run the `postconf` command to view all possible settings for your postfix service. Compare that to `postconf -n` which only shows the settings actually specified in your **/etc/postfix/main.cf** file.
```bash
postconf
postconf -n
```

Configure your mailbox, hostname, SASL authentication to use dovecot, and TLS/SSL settings using the following postconf commands.

```bash
postconf -e "home_mailbox ="
postconf -e "smtpd_sasl_type = dovecot"
postconf -e "smtpd_sasl_path = private/auth-client"
postconf -e "smtpd_sasl_local_domain ="
postconf -e "smtpd_sasl_security_options = noanonymous"
postconf -e "broken_sasl_auth_clients = yes"
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "smtp_tls_note_starttls_offer = yes"
postconf -e "smtpd_tls_loglevel = 1"
postconf -e "smtpd_tls_received_header = yes"
postconf -e "myhostname = mail.yourdomainname"
postconf -e 'smtpd_tls_key_file = /etc/ssl/private/mail.yourdomain.mytld.key'
postconf -e 'smtpd_tls_cert_file = /etc/ssl/certs/mail.yourdomain.mytld.crt'
```

Reload your postfix service and check the config to see that your changes went in as you expected and that the service is still running properly.
```bash
service postfix reload
postconf -n
service postfix status
```

Check the log to ensure there were no errors.
```bash
tail /var/log/mail.err
```

## Dovecot Installation Review and Modification
View your current dovecot settings using doveadm and compare that output to the output of doveconf -n, which can be more useful.

```bash
doveadm config
doveconf -n
```

Edit your **/etc/dovecot/conf.d/10-ssl.conf** file to use your correct key and certificate files:

```bash
ssl_cert = </etc/ssl/certs/mail.yourdomain.crt
ssl_key = </etc/ssl/private/mail.yourdomain.key
```

Tell dovecot to read its modified configuration and check that the service is still running properly.

```bash
service dovecot reload
service dovecot status
```

## Command line email
Send an email to your personal email account from root using the mail command to verify you can send and deliver email. Review the mail log to see what gets put there when an email is handled by the service.

```bash
sudo apt install mailutils
mail username
tail /var/log/mail.log
```

## Protocol testing

These types of protocol-based tests may or may not successfully complete depending on the configuration of your server. The default settings for the service daemons change over time so from semester to semester, these tests may generate differing results.
### POP3
1. Use `telnet localhost 110` to connect to the POP service (port 110), and issue the user (_USER yourfirstname_) and password (_PASS yourpassword_) handshake. It will either let you log in or refuse it.
1. If you successfully logged in with POP3, use the list (_LIST_) protocol commands to see how many email messages you have waiting.
1. You can exit your pop connection using _QUIT_.

### IMAP4
1. Use `telnet localhost 143` to connect to the IMAP service (port 143).
1. Issue the login (_a LOGIN yourfirstname yourpassword_) protocol command.
1. If the login succeeded, try status (_a STATUS INBOX (MESSAGES UNSEEN)_), and examine (_a EXAMINE INBOX_) imap protocol commands to see how many messages are in your _INBOX_.
1. You can use the _logout_ command to exit your IMAP (_a LOGOUT_)session.

## Roundcube webmail app
Install the **roundcube** webmail interface package. Tell dbconfig Yes to configure the database, and just hit `enter` when asked about setting a password for the roundcube database user.

```bash
apt install roundcube
```

Since we are not concerned about the implications of running **roundcube** on all of our sites, uncomment the _Alias_ line near the start of the **/etc/apache2/conf-available/roundcube.conf** file. Reload your apache service and verify it is still running properly.

```bash
nano /etc/apache2/conf-available/roundcube.conf
apachectl graceful
service apache2 status
```

Verify you can access the webmail interface with your browser by accessing **http://your-ip/roundcube** and logging in using your personal Linux account.

## Review log files
Examine the content of **mail.log** and **mail.err** in **/var/log** to see what is being logged for your activity on your mail server. Examine the content of **errors** in **/var/log/roundcube/** to see if you are having any problems with the roundcube webapp.

### Evaluate your server
Run ```sudo /root/server-check.sh -l 8 firstname lastname studentnumber```. Review any problems detected and correct as necessary. Do not move on to [Lab 9 File Sharing](Lab09-Samba.html) until you have Lab 8 at 100%. If you are having trouble getting Lab 8 to 100%, try running ```sudo /root/server-check.sh -l 1234567 firstname lastname studentnumber``` to make sure you haven't accidentally broken what was completed in previous labs.

### Extra Exercise
This extra exercise does not count for marks and is not required. But it is a useful practice for setting up email relaying through an ISP which blocks the SMTP port (most modern ISPs block this and force you send email through their servers). If you have your email server setup like shown in this lab, you can use the following commands to add relaying via an external server. Use the actual name of the mail server you are relaying through instead of `yourispmailserverdomainname` and your ISP-required email login and password instead of `myemailaddress` and `myemailpassword`.
```bash
externalrelayhost=yourispmailserverdomainname
emailaddr='myemailaddress'
emailpass='myemailpassword'
sudo postconf -e "smtp_sasl_auth_enable = yes"
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_sasl_tls_security_options = noanonymous"
sudo postconf -e "relayhost = [$externalrelayhost]:submission"
sudo postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
echo "[$externalrelayhost]:submission $emailaddr:$emailpass" | sudo tee /etc/postfix/sasl_passwd >/dev/null
sudo postmap hash:sasl_passwd
sudo systemctl restart postfix
```
Your Linux mail server should now be able to send email to any legitimate internet email address, although they cannot send email to your email server without further work on your part. It is still useful for sending yourself email from your Linux system instead of having to log onto the Linux system to read mail sent to root or other users. You can even create an alias for root to forward root mail to your normal email account. You can test this using a command like:
```bash
sudo nano /etc/aliases
sudo newaliases
mail -s "Test message from COMP1071 server" root <<< "testing...testing"
```

## Further Resources and Reading
Review **http://www.postfix.org/SASL_README.html** for a detailed howto on setting up other scenarios for postfix using either dovecot or cyrus for Simple Authentication and Security Layer.

Review **https://help.ubuntu.com/community/PostfixVirtualMailBoxClamSmtpHowto** for an overview of how to configure multiple email domains on a single postfix/dovecot server.

Review [Postfix SOHO Hints and Tips](http://www.postfix.org/SOHO_README.html) for settings and commands for configuring email servers connected to ISPs that require you to relay mail through servers.
