# Lab 7 CUPS

## Overview
In this lab, you will install the CUPS service and a virtual PDF printer, then manage that printer. The instructions for commands in this lab assume you are running as a normal user, not the root user.

## Install Software
Install the cups and cups-pdf packages:

```
sudo apt update
sudo apt install cups cups-pdf
```

## Service Status Check
Check the status of the CUPS service daemon:

```
service cups status
```

Check the status of the print queues:

```
lpstat -t
``` 

View the list of available print services, including those discovered on our network:

```
sudo lpinfo -v
``` 

## Configuration
Modify your **/etc/cups/cupsd.conf** file to permit print job submission from the network by changing from the default _Listen_ directive to the _Port_ directive. Enable the web interface by setting _WebInterface yes_ if it is not set to yes by default. Restart your CUPS service

```
sudo nano /etc/cups/cupsd.conf
sudo service cups restart
```

## Firewall Rules
Add a UFW rule to allow IPP and Bonjour through your firewall:

```
sudo ufw allow 631
sudo ufw allow 5353
```

## Printing
Print out your **cupsd.conf** file:

```
lp /etc/cups/cupsd.conf
```

Verify that a pdf file has appeared in your user's **~/PDF** directory. Copy that file to your user's **~/public_html** directory and try viewing it using a web browser. You should get a permission denied because the PDF file is only readable by the user who printed it.

```
ls ~/PDF
cp ~/PDF/*.pdf ~/public_html
```

Set the permissions on the PDF file to allow the web service daemon to read the file, and try reloading the web page to view your PDF. You could even add a link to it in your index.html document to save typing out the filename in the URL.
```
chmod +r ~/public_html/*.pdf
echo "<p>My <a href=cupsd.conf__PDF-job_1.pdf>PDF file of the cupsd.conf file</a> can be viewed by clicking on the link.</p>" >> public_html/index.html
```

Modify your **/etc/cups/cups-pdf.conf** to use _Label 2_ and _TitlePref 1_. Try printing your **/etc/cups/cupsd.conf** file again. What gets put into your **~/PDF** directory this time?
```
sudo nano /etc/cups/cups-pdf.conf
lp /etc/cups/cupsd.conf
ls ~/PDF
```

## Queue and device management
Disable the pdf print queue:
```
sudo cupsdisable PDF
```

Submit several print jobs
```
lp /etc/hosts
lp /etc/services
lp /etc/hostname
lp /etc/fstab
lp /etc/protocols
``` 

Verify the jobs are waiting to print by viewing the print queue:
```
lpstat -t
```

Enable your PDF print queue:
```
sudo cupsenable PDF
```

Verify the jobs printed:
```
lpstat -t
ls ~/PDF
```

Set the pdf print queue to reject incoming print jobs and check the status with lpstat:
```
sudo cupsreject PDF
lpstat -t
```

Try to submit a print job to the PDF print queue:
```
lp /etc/hosts
```

To successfully submit print jobs, set the PDF print queue to accept print jobs again, and see the difference in lpstat:
```
sudo cupsaccept PDF
lpstat -t
```
Try to submit a print job to the PDF print queue and this time it should go through:
```
lp /etc/hosts
```

## Review log files
Examine the content of the various logfiles in **/var/log/cups** to see what is being logged for your activity on your web server:

```
ls /var/log/cups
more /var/log/cups/*_log
```

### Evaluate your server
Run ```sudo /root/server-check.sh -l 7 firstname lastname studentnumber```. Review any problems detected and correct as necessary. Do not move on to [Lab 8 Email](Lab08-Email.html) until you have Lab 7 at 100%. If you are having trouble getting Lab 7 to 100%, try running ```sudo /root/server-check.sh -l 123456 firstname lastname studentnumber``` to make sure you haven't accidentally broken what was completed in previous labs.
