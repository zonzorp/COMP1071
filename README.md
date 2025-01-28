# Resources for COMP1071 - Linux Network Administration

## Course Information
This course is part of the CSTN program at Georgian College. The course outline is updated periodically and kept available online via the [Georgian College website](https://georgiancollege.ca). There is also a course syllabus with the details for each semester kept on the [Blackboard website](https://gc.blackboard.com) for the course.
There is no textbook for this course. Online help and documentation provide the reference material.
Ubuntu Server 20.04LTS is the platform for our lab exercises and it is expected that students will run it in a virtual machine under [VMWare](https://vmware.com) ([Link to download Academic use licensed version](https://onthehub.com)), [Virtualbox](https://www.virtualbox.org) which is free from Oracle, or [Parallels](https://parallels.com) which is a highly integrated Mac application that is not free. Students are expected to install and become familiar with at least one of these software packages on their own. I have published a short video on youtube on [how to download VMWare from onthehub.com using your student account](https://youtu.be/z__OjayPFXA).

## Prerequisites
It is expected that students have taken the COMP2018 Linux System Administration course prior to taking this course. Students are expected to be familiar with the bash shell and command line interface. A Linux GUI is NOT to be installed on the server students will use for the labs. If the student is not comfortable on the command line, [Ryan's Tutorials](https://ryanstutorials.net) is an excellent website to become re-acquainted with the command line, as well as several other topics.

## Semester Assignment
The assignment for this course is to successfully complete all labs during the semester. When they are completed, the server-check.sh script must be run as root for all labs to record an assignment score. This is an individual assignment. Students may work together on it, but each student must run their own server-check.sh to record their own marks on their own virtual server.

The server check script can be downloaded and made executable using:

```
sudo wget -O /root/server-check.sh https://zonzorp.github.io/COMP1071/server-check.sh
sudo chmod +x /root/server-check.sh
```

To run the server-check script after you complete each lab, use a command like this:

```
sudo /root/server-check.sh -l N firstname lastname studentnumber
```

Replace the N with the lab being evaluated. Labs can be evaluated as many times as desired. The score received is saved every time the script is run if your name and student number are registered for the zonzorp.net gc scores database. Registered students can check their progress on the [lab scores website](https://zonzorp.net/gc). If you are not registered, you can ask your instructor to register you, or simply ignore the message about your student number not being valid for your semester, but you will not be able to see your score history.

A [video](https://youtu.be/Zt6bdhBU_Ac) showing how to use this script is available on youtube.

## Presentations and Labs
These presentations and lab instructions are intended to be used in an instructor-led environment and are not designed for self-study. Each presentation video should be reviewed before the associated lab is attempted. The lab examples in the videos may not exactly match the current lab instructions; they are for instruction purposes only. Whenever there is a difference between what is in the video and what is in the lab instructions, ALWAYS follow the lab instructions, not the example from the video. Once each lab is done, the student should be prepared to write the matching section quiz on [Blackboard](http://gc.blackboard.com). The labs are designed to build on each other in sequence and you will be unable to complete some of the labs if you do not do them in the order they are presented in the course.

### Lab System Creation
Create the VM to be used for our labs either by following the instructions at [Lab VM creation](Labs/Lab00-VM-Creation.html), or by importing [this VM ova file](https://zonzorp.net/gc/COMP1071-F21-starting-vm.ova). If you import the VM, you do not need to run the install, but you may need to modify the network interfaces to be attached correctly before the first boot of the VM. The first interface is expected to be bridged to your LAN, but will also work on the NAT VMWare network. the second interface must be connected to a VMWare private (host-only) network. If you have no host-only private networks in your VMWare installation, you would need to create one before importing the VM. Instructions for this are part of [Lab VM creation](Labs/Lab00-VM-Creation.html).

### Course materials and Labs
1. [System Management ReviewPresentation](Presentations/COMP1071 01 System Management.pdf) / [Lab](Labs/Lab01-SysMgmt.html) / [Quiz](https://gc.blackboard.com)
1. [Network Configuration Presentation](Presentations/COMP1071 02 Network Configuration.pdf) / [Lab](Labs/Lab02-NetworkConfig.html) / [Quiz](https://gc.blackboard.com)
1. [DNS Service Presentation](Presentations/COMP1071 03 DNS.pdf) / [Lab](Labs/Lab03-DNS.html) / [Quiz](https://gc.blackboard.com)
1. [Web Service with Apache2 Presentation](Presentations/COMP1071 04 Apache2.pdf) / [Lab](Labs/Lab04-Apache2.html) / [Quiz](https://gc.blackboard.com)
1. [SSL Web Service and Certificate Management Presentation](Presentations/COMP1071 07 Apache2 SSL.pdf) / [Lab](Labs/Lab05-SSL.html) / [Quiz](https://gc.blackboard.com)
1. [Database Service with MySQL Presentation](Presentations/COMP1071 08 MySQL.pdf) / [Lab](Labs/Lab06-Mysql.html) / [Quiz](https://gc.blackboard.com)
1. [Printing Service with CUPS Presentation](Presentations/COMP1071 09 CUPS.pdf) / [Lab](Labs/Lab07-CUPS.html) / [Quiz](https://gc.blackboard.com)
1. [Email with Postfix, Dovecot and Roundcube Presentation](Presentations/COMP1071 10 Email.pdf) / [Lab](Labs/Lab08-Email.html) / [Quiz](https://gc.blackboard.com)
1. [File Sharing with Samba and FTP Presentation](Presentations/COMP1071 11 Samba and FTP.pdf) / [Lab](Labs/Lab09-Samba.html) / [Quiz](https://gc.blackboard.com)

## Additional Resources
* [Video explaining desktop hardware vs server hardware in layman's terms](https://www.youtube.com/watch?v=ByI1PHMcPJQ)
* [Linux ip command examples](https://www.cyberciti.biz/faq/linux-ip-command-examples-usage-syntax/)
* [BIND vs. other software for DNS service](https://computingforgeeks.com/bind-vs-dnsmasq-vs-powerdns-vs-unbound/)
* [O'Reilly DNS and BIND ebook](https://docstore.mik.ua/orelly/networking_2ndEd/dns/index.htm)
* [Netplan configuration file examples](https://netplan.io/examples)
* [Easy-rsa 3 tutorial](https://www.howtoforge.com/tutorial/how-to-install-openvpn-server-and-client-with-easy-rsa-3-on-centos-8/)
* [systemd-resolved](https://wiki.archlinux.org/index.php/Systemd-resolved)
* [Excellent 10 minute explanation of how email moves around the internet](https://www.youtube.com/watch?v=x28ciavQ4mI)
