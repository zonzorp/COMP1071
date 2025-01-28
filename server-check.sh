#!/bin/bash
#
# this script will check to see if the activities in the labs have been successfully completed on this server
#This script has many "switches" or "options" to select labs, and even fill in your $firstname and $lastname variables
#For example if you wanted to test labs 1-5 type
#./server-check.sh firstname lastname --lab 12345
#The --lab switch can also contain single numbers such as
#./server-check.sh firstname lastname --lab 1
#

############
# Todo
############
# Lab 1:
# add tree, glances, and htop packages to lab and slides
# modify default user homedir to only have Documents, Pictures, Downloads, .bash_login
# make changes to home dir and PATH before installing packages, so that sl and fortune work better
# change package name for fortune to fortune-mod
# .bash_login should source ~/.profile
# get rid of adduser example and only keep useradd version

# to accomodate centos-7:
#   apt to yum, dpkg to rpm
#   to add pkgs.org repo, do wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm;rpm -i epel*
#   no memstat for centos, consider dropping memstat
#   fortune-mod is required name for fortune package
#   distinction between useradd and adduser lost in centos
#   add install of lshw package
#   changing /etc/hostname file immediately changes hostname, update slides
# wheel group instead of sudo group

############
# Ideas for Enhancements
############

# add an ssh key to allow remote connections for student login for me to use

############
# Variables
############
labnum="123456789"
firstname="$FIRSTNAME"
lastname="$LASTNAME"
studentnumber="$STUDENTNUMBER"
score=0
labscore=0
labmaxscore=0
maxscore=0
labscoresURL="https://zonzorp.net/gc/postlabscores.php"
datetime=$(date +"%Y-%m-%d@%H:%M:%S%p")
logfile="/tmp/sc$datetime$$.log"
course="COMP1071"
case `date +%m` in
01|02|03|04) semester="W`date +%y`";;
05|06|07|08) semester="S`date +%y`";;
09|10|11|12) semester="F`date +%y`";;
esac
skipUpdate="no"
ufwAlwaysOn="yes"
. /etc/os-release

############
# Functions
############

function usage {
	echo "$0 [-v] [-l|--lab labnumber(s)] [firstname lastname studentnumber]"
}

function problem-report {
	tee -a $logfile <<< ">>> Problem found: $1"
}

function verbose-report {
	[ "$verbose" = "yes" ] && echo "$1"
	echo "$1" >> $logfile
}

function scores-report {
	tee -a $logfile <<< "$1"
}

# function to print out header for output report section
# Usage: lab_header lab-name
function lab_header {
	echo ""
	echo "Checking for Lab $1 tasks"
	echo "--------------------------"
}

# function to check if packages are installed
# Usage: package_checks space-delimited-package-names
function package_checks {
	verbose-report ""
	verbose-report "Package install check"
	verbose-report "---------------------"
	final_status=0
	for pkgname in $1; do
		dpkg -L $pkgname >& /dev/null
		if [ $? != "0" ]; then
			final_status=$?
			problem-report "$pkgname package not installed"
			problem-report "Use apt-get to install the package"
		else
			verbose-report "$pkgname package found ok"
			((labscore++))
		fi
		((labmaxscore++))
	done
	return $final_status
}

# function to do nslookups of DNS records
# Usage: dns_lookup_checks space-delimited-names domain record-type
function dns_lookup_checks {
	for host in $1; do
		if [[ "$VERSION_ID" < "18.04" ]]; then
			nslookup -norecurse -querytype=$3 $host.$2>/dev/null
		else
			nslookup -querytype=$3 $host.$2>/dev/null
		fi
		if [ $? != "0" ]; then
			problem-report "$3 record for $host.$2 not found using nslookup"
			if [ "$2" != "mytld" ]; then
				problem-report "Be sure there is a $3 record for $host in your db.$2 file and reload bind if necessary"
			else
				problem-report "Be sure you have a zone definition for $host.$2 in your named.conf.local file"
			fi
		else
			verbose-report "$host.$2 record looked up ok"
			((labscore+=3))
		fi
		((labmaxscore+=3))
	done
}

# function to do nslookups of reverse DNS records
# Usage: dns_lookup_checks space-delimited-names domain record-type
function reverse_dns_lookup_checks {
	for host in $1; do
		if [[ "$VERSION_ID" < "18.04" ]]; then
			nslookup -norecurse -querytype=$3 $host.$2>/dev/null
		else
			nslookup -querytype=$3 $host.$2>/dev/null
		fi
		if [ $? != "0" ]; then
			problem-report "$3 record for $host.$2 not found using nslookup"
			if [ "$2" != "mytld" ]; then
				problem-report "Be sure there is a $3 record for $2 in your db.$host file and reload bind if necessary"
			else
				problem-report "Be sure you have a zone definition for network $host in your named.conf.local file"
			fi
		else
			verbose-report "$host.$2 record looked up ok"
			((labscore+=3))
		fi
		((labmaxscore+=3))
	done
}

function check_config_file {
	configfile="$1"
	directive="$2"
	value="$3"
	grep -q "$directive[ 	][ 	]*$value" $configfile
	if [ $? != "0" ]; then
		problem-report "$directive should be $value in $configfile"
	else
		verbose-report "$directive in $configfile ok"
		((labscore+=1))
	fi
	((labmaxscore+=1))
}

function check_config_file_allow_extra_stuff {
	configfile="$1"
	directive="$2"
	value="$3"
	grep -q "$directive[ 	].*$value.*" $configfile
	if [ $? != "0" ]; then
		problem-report "$directive should be $value in $configfile"
	else
		verbose-report "$directive in $configfile probably ok"
		((labscore+=1))
	fi
	((labmaxscore+=1))
}

function check_interface_config {
	ifacename="$1"
	ifaceaddr="$2"
	if [[ "${addrs[$ifacename]}" =~ "$ifaceaddr" ]]; then
		verbose-report "$ifacename/$ifaceaddr configured ok"
		((labscore+=3))
	else
		problem-report "$ifacename should be configured for address $ifaceaddr"
		if [[ "$VERSION_ID" < "18.04" ]]; then
			problem-report "Check your interfaces files"
		else
			problem-report "Check your netplan files"
		fi
	fi
	((labmaxscore+=3))
}

function check_ufw {
	service="$1"
	port="$2"
	if [ "$ufwAlwaysOn" = "yes" ]; then
		ufw status verbose |& grep "^$port " >/dev/null
		if [ $? != "0" ]; then
			problem-report "Firewall rule for $service missing"
			problem-report "Review the instructions for setting up a $service allow rule for ufw"
		else
			verbose-report "Firewall config for $service ok"
			((labscore+=2))
		fi
		((labmaxscore+=2))
	fi
}

############
# Main
############

# start a new logfile and start it with date/time info
date +"server-check running on %Y-%M-%D at %H:%M %p" >$logfile
echo "$0 $@" >>$logfile

#Checks if your userID is that of root when either using sudo
#or if directly logged in as the root account
if [ `id -u` != "0" ]; then
	problem-report "You need to be root for parts of this script to run properly."
	problem-report "Consider using sudo to run this script"
	problem-report "To run this script try:"
	problem-report "sudo `basename $0`"
	rm $logfile # this logfile is pointless, discard it
	exit 1
fi
# test if internet is reachable
ping -c 1 8.8.8.8 >&/dev/null
if [ $? -ne 0 ]; then
	problem-report "Not connected to the internet. This script requires a functional IPV4 internet connection."
	problem-report "Check that you are getting dhcp service on your first network interface (try 'ip a')."
	problem-report "Check that you have internet service on your host computer (try 'ping 8.8.8.8' in a command window on the host computer)"
	# leave the logfile in place for troubleshooting purposes
	exit 1
fi

verbose="no"
while [ $# -gt 0 ]; do
	case "$1" in
		-l | --lab)
			labnum="$2"
			shift
			;;
		-s )
			skipUpdate="yes" # this hidden options skips checking for script updates
			;;
		-f )
			ufwAlwaysOn="no" # this hidden option allows not checking ufw rules for all services
			;;
		-v )
			verbose="yes"
			;;
		*)
			if [ "$firstname" = "" ]; then
				firstname="$1"
			elif [ "$lastname" = "" ]; then
				lastname="$1"
			elif [ "$studentnumber" = "" ]; then
				studentnumber="$1"
			else
				usage
				rm $logfile # this logfile is pointless, discard it
				exit
			fi
			;;
	esac
	shift
done

if [ "$skipUpdate" = "no" ]; then
	echo "Checking if script is up to date, please wait"
	wget -nv -O /root/server-check-new.sh https://zonzorp.github.io/COMP1071/server-check.sh >& /dev/null
	diff /root/server-check.sh /root/server-check-new.sh >& /dev/null
	if [ "$?" != "0" -a -s /root/server-check-new.sh ]; then
		mv /root/server-check-new.sh /root/server-check.sh
		chmod +x /root/server-check.sh
		echo "server-check.sh updated"
		/root/server-check.sh -s "$@"
		rm $logfile # this logfile is pointless, discard it
		exit
	else
		rm /root/server-check-new.sh
	fi
fi

cat <<EOF
This script will check various parts of your server to see if you have completed
the setup of the various services and configuration as instructed during the semester.
***********************!!!!!!!!!!*********************
It is expected that you use lower case only whenever you use your name as part of
your server configuration, for username, domain name, etc.
***********************!!!!!!!!!!*********************
EOF

while [ "$firstname" = "" ]; do
	read -p "Your first name? " firstname
done
while [ "$lastname" = "" ]; do
	read -p "Your last name? " lastname
done
while [ "$studentnumber" = "" ]; do
	read -p "Your student number? " studentnumber
done

if [ $(wc -c <<< "$studentnumber") -eq 9 ]; then
	snum=`cut -c 4-8 <<< "$studentnumber"`
elif [ $(wc -c <<< "$studentnumber") -eq 10 ]; then
	snum=`cut -c 5-9 <<< "$studentnumber"`
elif [ $(wc -c <<< "$studentnumber") -eq 2 ]; then
        snum=""
else
	problem-report "Your student number should be either 8 digits or 9 digits long"
	# leave the logfile in place for troubleshooting
	exit
fi
firstname=`tr 'A-Z' 'a-z'<<<"$firstname"`
lastname=`tr 'A-Z' 'a-z'<<<"$lastname"`
mydomain="$lastname$snum"
zone="$mydomain.mytld"
arch=`arch`
if [ $arch = "armv6l" -o $arch = "armv7l" ]; then
	arch=armhf
	hosttype=pi
fi
if [ $arch = "i686" -o $arch = "i586" -o $arch = "x86_64" ]; then
	arch=amd64
	hosttype=pc
fi
hostname="$hosttype$studentnumber"

# Display runtime info
verbose-report "Course/Semester: $course/$semester" 
[ "$verbose" = "yes" ] && verbose-report "First name: $firstname"
[ "$verbose" = "yes" ] && verbose-report "Last name : $lastname"
[ "$verbose" = "yes" ] && verbose-report "Student Number: $studentnumber"
[ "$verbose" = "yes" ] && verbose-report "Domain name: $zone"

# Gather network config details
verbose-report "Host name: $hostname"
declare -A addrs
declare -A names
ifaces=(`ip link show|awk '/: e/{gsub(/:/,"");gsub(/@.*/,"");print $2}'`)
for iface in ${ifaces[@]}; do
	if [[ "$VERSION_ID" < "18.04" ]]; then
		addr=`ifconfig $iface|grep "inet "|awk '{print $2}'|sed -e 's/addr://'`
	else
		addr=`ip addr show dev $iface|grep "inet "|awk '{print $2}'|sed -e 's,/.*,,'`
	fi
	if [ -n "$addr" ]; then
		addrs[$iface]="$addr"
		names[$iface]=`getent hosts $addr|awk '{print $2}'`
	else
		addrs[$iface]="No Address Assigned"
		names[$iface]="No Name Found"
	fi
	verbose-report "You have interface $iface configured as host '${names[$iface]}' with address '${addrs[$iface]}'"
done
defaultrouter=`ip route show default |awk '{print $3}'|head -1`

# if necessary, display default route info
if [ "$defaultrouter" = "" ]; then
	problem-report "Default route not found. Check your dhcp settings and your network configuration in your VM software."
	problem-report "This script is unlikely to produce useful output without a default route - exiting."
	# leave the logfile in place for troubleshooting
	exit 1
else
	verbose-report "Your default route is via '$defaultrouter'"
fi

if [[ $labnum =~ "1" ]]; then
dpkg -L sl>&/dev/null
if [ "$?" = "0" ]; then
	lab_header "01"
	labscore=0
	labmaxscore=0
	package_checks "sl cowsay memstat sysstat curl"
	dpkg -L fortune >& /dev/null
	if [ $? != "0" ]; then
		dpkg -L fortune-mod >& /dev/null
	fi
	if [ $? != "0" ]; then
		problem-report "fortune package must be installed"
		problem-report "Use apt-get to install the fortune package"
	else
		verbose-report "fortune package found ok"
		((labscore++))
	fi
	((labmaxscore++))
	if [ "`hostname`" != "$hostname" ]; then
		problem-report "Hostname is `hostname`, and should be $hostname"
		problem-report "Correct your /etc/hostname file if necessary and reboot"
	else
		((labscore+=3))
		verbose-report "Host name ok"
	fi
	((labmaxscore+=3))
	if getent hosts "$hostname">/dev/null; then
		verbose-report "$hostname resolves to an address ok"
		((labscore+=3))
	else
		problem-report "$hostname not found in /etc/hosts"
		problem-report "Check your /etc/hosts file to make sure you have an entry for $hostname"
	fi
	((labmaxscore+=3))
	grep -q /usr/games /etc/skel/.bash_login
	if [ $? != "0" ]; then
		problem-report "/usr/games should be added to the command path variable in /etc/skel/.bash_login"
	else
		((labscore++))
		verbose-report "/etc/skel/.bash_login path ok"
	fi
	((labmaxscore++))
	grep -q '^fortune *| *cow' /etc/skel/.bash_login
	if [ $? != "0" ]; then
		problem-report "fortune | cowthink or cowsay should be added to /etc/skel/.bash_login"
	else
		verbose-report "/etc/skel modified ok"
		((labscore++))
	fi
	((labmaxscore++))
	if [ ! -d /etc/skel/bin -o ! -d /etc/skel/public_html -o ! -d /etc/skel/Documents -o ! -d /etc/skel/Pictures ]; then
		problem-report "One or more of the files or directories is not present in /etc/skel"
		problem-report "Review the instructions to make sure you correctly built /etc/skel"
	else
		verbose-report "/etc/skel directories ok"
		((labscore++))
	fi
	((labmaxscore++))
	userentry=`grep "^$firstname:" /etc/passwd`
	if [ $? != "0" ]; then
		problem-report "no user account for user $firstname"
		problem-report "Use the useradd command to create an account for $firstname"
	else
		verbose-report "user account $firstname found ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	homedir=`awk -F : '{print $6}' <<<"$userentry"`
	if [ "$homedir" != "/home/$firstname" ]; then
		problem-report "home directory is not /home/$firstname for user $firstname"
		problem-report "Use usermod -m -d /home/$firstname $firstname to correct it"
	else
		if [ ! -d $homedir ]; then
			problem-report "Home directory for user $firstname does not exist"
			problem-report "Try userdel $firstname and add the user back properly with useradd"
		else
			if [ ! -d $homedir/bin -o ! -d $homedir/public_html -o ! -d $homedir/Documents -o ! -d $homedir/Pictures ]; then
				problem-report "One or more of the files or directories from /etc/skel are missing from the home directory for $firstname"
				problem-report "Review the instructions to make sure you correctly built /etc/skel and then copy the contents of it to /home/$firstname"
			else
				verbose-report "home directory for user account $firstname ok"
				((labscore+=2))
			fi
		fi
	fi
	((labmaxscore+=2))
	usershell=`awk -F : '{print $7}' <<< "$userentry"`
	if [ "$usershell" != "/bin/bash" ]; then
		problem-report "user shell is not /bin/bash for user $firstname"
		problem-report "Use usermod -s /bin/bash to set the shell correctly"
	else
		verbose-report "shell for user account $firstname ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
	sudogroup=`groups $firstname | grep sudo`
	if [ $? != "0" ]; then
		problem-report "user $firstname is not a member of the sudo group and needs to be"
		problem-report "Use usermod -G sudo $firstname to add the sudo group to the user's group list"
	else
		verbose-report "sudo group  membership for user account $firstname ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
	scores-report "Lab 01 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=1&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "sl package not installed, skipping lab 01"
fi
fi

if [[ $labnum =~ "2" ]]; then
labscore=0
labmaxscore=0
dpkg -L traceroute>&/dev/null
if [ $? = "0" ]; then
	lab_header "02"
	if [[ "$VERSION_ID" < "18.04" ]]; then
		package_checks "quagga"
	fi
	package_checks "traceroute ethtool nmap ufw cockpit"
# removed checks for ntopng 2021-08-27, per discussion with Ali
#	dpkg -L ntop >& /dev/null
#	if [ $? != "0" ]; then
#		dpkg -L ntopng >& /dev/null
#	fi
#	if [ $? != "0" ]; then
#		problem-report "ntop or ntopng package must be installed"
#		problem-report "Use apt-get to install the ntop or ntopng package"
#else
#		verbose-report "ntop or ntopng package found ok"
#		((labscore++))
#	fi
#	((labmaxscore++))
# take last installed interface to allow virtualbox vms to use double interfaces, one NAT, one host-only, so that host pc can connect to vm
ifname=`lshw -class network |grep 'logical name: [a-zA-Z0-9]*$' |awk '{gsub(/@.*/,"");print $3}'|tail -1`
	if [[ "$VERSION_ID" < "18.04" ]]; then
		check_interface_config $ifname.10 172.16.3.2
		check_interface_config $ifname.20 172.16.4.2
		check_interface_config $ifname.30 172.16.5.2
	else
		check_interface_config en-vl10 172.16.3.2
		check_interface_config en-vl20 172.16.4.2
		check_interface_config en-vl30 172.16.5.2
	fi
# private route checks
	ip route show|grep -q "172.16.6.0/24 via 172.16.3.1"
	if [ $? != "0" ]; then
		problem-report "There should be a route to network 172.16.6.0/24 in your route table via gateway 172.16.3.1"
		if [[ "$VERSION_ID" < "18.04" ]]; then
			problem-report "Review the instructions for setting up a static route using Quagga"
		else
			problem-report "Check your netplan files"
		fi
	else
		verbose-report "route for 172.16.6.0/24 ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	ip route show|grep -q "172.16.7.0/24 via 172.16.4.1"
	if [ $? != "0" ]; then
		problem-report "There should be a route to network 172.16.7.0/24 in your route table via gateway 172.16.4.1"
		if [[ "$VERSION_ID" < "18.04" ]]; then
			problem-report "Review the instructions for setting up a static route using Quagga"
		else
			problem-report "Check your netplan files"
		fi
	else
		verbose-report "route for 172.16.7.0/24 ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	if [[ "$VERSION_ID" < "18.04" ]]; then
		vtysh -C
		if [ $? != "0" ]; then
			problem-report "vtysh config errors found"
			problem-report "Check your /etc/quagga/vtysh.conf file"
		else
			verbose-report "vtysh config ok"
			((labscore+=3))
		fi
		((labmaxscore+=3))
		vtysh -c "show daemons" | grep zebra >& /dev/null
		if [ $? != "0" ]; then
			problem-report "zebra daemon not found in running quagga config found"
			problem-report "Check your /etc/quagga/daemons file"
		else
			verbose-report "zebra config ok"
			((labscore+=2))
		fi
		((labmaxscore+=2))
	fi
# ssh rule in firewall config check
	check_ufw ssh 22/tcp
# ntopng removed 21-08-27 per discussion with Ali
#	check_ufw ntopng 3000/tcp
#	wget -O - http://localhost:3000 >&/dev/null
#	if [ $? != "0" ]; then
#		service ntopng start
#		sleep 4
#	fi
#	wget -O - http://localhost:3000 >&/dev/null
#	if [ $? != "0" ]; then
#		problem-report "Failed to retrieve ntop web page from default web server using localhost"
#		problem-report "Review the instructions for ntop. Ensure you specified a network interface to monitor in the ntop setup. Run dpkg-reconfigure ntop if necessary."
#	else
#		verbose-report "ntop web interface retrieval using localhost ok"
#		((labscore+=2))
#	fi
#	((labmaxscore+=2))
	wget -O - http://localhost:9090 >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve cockpit web page from default web server using localhost"
		problem-report "Review the instructions for cockpit. Ensure you specified a network interface to monitor in the ntop setup. Run dpkg-reconfigure ntop if necessary."
	else
		verbose-report "cockpit web interface retrieval using localhost ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
	scores-report "Lab 02 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=2&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"

else
	problem-report "traceroute package not installed, skipping lab 02"
fi
fi

if [[ $labnum =~ "3" ]]; then
labscore=0
labmaxscore=0
dpkg -L bind9 >&/dev/null
if [ "$?" = "0" ]; then
	lab_header "03"
	package_checks "bind9 dnsutils"
# check for working dns lookups in personal domain
	dns_lookup_checks $mydomain mytld SOA
	dns_lookup_checks "ns1 www mail router3" $zone A
	dns_lookup_checks pop $zone CNAME
	reverse_dns_lookup_checks 172.16.3 1 PTR
	reverse_dns_lookup_checks 172.16.3 2 PTR
	reverse_dns_lookup_checks 172.16.4 2 PTR
	reverse_dns_lookup_checks 172.16.5 2 PTR
# Remove check for external dns, script now checks if we are online before running - 20-06-24
# Just assign the three marks for being online
	verbose-report "external dns still ok after doing lab 3"
	((labscore+=3))
	((labmaxscore+=3))
## check for working external dns
## because of ubuntu 20.04 check config details
## check for resolv.conf, should not exist, or should be empty
#	if [ -f /etc/resolv.conf ]; then
#		if [[ "$VERSION_ID" < "20.04" ]]; then
#			verbose-report "resolv.conf check not done unless running 20.04"
#			resolvconfcheck="passed"
#		elif [ $(egrep -cv '^#|^$' /etc/resolv.conf) -gt 0 ]; then
#			problem-report "resolv.conf is not empty"
#			problem-report "resolv.conf should not have any configuration lines in it"
#			resolvconfcheck="failed"
#		else
#			verbose-report "resolv.conf is empty OK"
#			resolvconfcheck="passed"
#		fi
#	else
#		verbose-report "resolv.conf is removed OK"
#		resolvconfcheck="passed"
#	fi
#	if [ "$resolvconfcheck" = "passed" ]; then
#		# try a lookup that requires external dns to be working
#		nslookup icanhazip.com >&/dev/null
#		if [ $? != "0" ]; then
#			problem-report "icanhazip.com not found by nslookup"
#			problem-report "Check that /etc/resolv.conf is empty or removed"
#			problem-report "Verify that your bind service is running and properly configured"
#			problem-report "Check that the internet is reachable"
#		else
#			verbose-report "nslookup of zonzorp.net ok"
#			((labscore+=3))
#		fi
#	fi
#	((labmaxscore+=3))
	check_ufw dns 53
	scores-report "Lab 03 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=3&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "bind9 package not installed, skipping lab 03"
fi
fi

# Labs 4 & 5 need to know where things will be depending on whether we are using conf.d or conf-available/enabled
apache2_dir=/etc/apache2
if [ -f $apache2_dir/apache2.conf ]; then
	grep "^Include conf.d" /etc/apache2/apache2.conf >&/dev/null
	if [ "$?" = "0" ]; then
		apache2_confdir=$apache2_dir/conf.d
		defservernamefile=$apache2_confdir/defaulthostname
		wwwsitefile=$apache2_dir/sites-enabled/www.$zone
		securesitefile=$apache2_dir/sites-enabled/secure.$zone
	else
		apache2_confdir=$apache2_dir/conf-available
		apache2_enconfdir=$apache2_dir/conf-enabled
		defservernamefile=$apache2_enconfdir/defaulthostname.conf
		wwwsitefile=$apache2_dir/sites-enabled/www.$zone.conf
		securesitefile=$apache2_dir/sites-enabled/secure.$zone.conf
	fi
	apache2version=`apache2 -v|head -1|cut -d/ -f 2|cut -c 1-3`
fi

if [[ $labnum =~ "4" ]]; then
labscore=0
labmaxscore=0
dpkg -L apache2>&/dev/null
if [ "$?" = "0" ]; then
	lab_header "04"
	package_checks "apache2"
	dns_lookup_checks www $zone A
#check for default ServerName config file
	check_config_file $defservernamefile ServerName $hostname
	check_config_file_allow_extra_stuff /etc/apache2/mods-enabled/userdir.conf AllowOverride "Options=Indexes"
	check_config_file /home/$firstname/public_html/pics/.htaccess Options "+Indexes"
# apache2 modules checks
	if [ ! -f /etc/apache2/mods-enabled/userdir.conf ]; then
		problem-report "userdir module not enabled"
		problem-report "userdir module should be enabled using the a2enmod command"
	else
		verbose-report "userdir module enabled ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
# apache2 service response checks
	rm -f /tmp/default-site.html
	wget -O /tmp/default-site.html -q http://$hostname >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve web page from default web server using $hostname"
		problem-report "Try apachectl configtest and wget -O - http://$hostname to diagnose"
	else
		verbose-report "default site retrieval using $hostname ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	rm -f /tmp/default-site.html
	rm -f /tmp/userhomepage.html
	wget -O /tmp/userhomepage.html http://$hostname/~$firstname/ >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve users's personal web page from default web server using $hostname"
		problem-report "Try apachectl configtest and wget -O - http://$hostname/~$firstname/ to diagnose"
	else
		verbose-report "User's personal web page retrieval using $hostname ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	rm -f /tmp/userhomepage.html
	wget -O /dev/null http://$hostname/~$firstname/pics >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve users's personal pics listing from default web server using $hostname"
		problem-report "Try apachectl configtest and wget -O - http://$hostname/~$firstname/pics to diagnose"
	else
		verbose-report "User's personal pics listing retrieval using $hostname ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	rm -f /tmp/www-site.html
	# some checks for site file content
	wwwdocroot=/sites/www.$zone
	check_config_file $wwwsitefile VirtualHost www.$zone:80
	check_config_file $wwwsitefile ServerName www.$zone
	check_config_file $wwwsitefile DocumentRoot $wwwdocroot
	check_config_file $wwwsitefile Directory $wwwdocroot
	check_ufw HTTP 80/tcp
	
	wget -O /tmp/www-site.html http://www.$zone >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve web page from virtual server using www.$zone"
	else
		diff $wwwdocroot/index.html /tmp/www-site.html >& /dev/null
		if [ $? != "0" ]; then
			problem-report "Virtual server www.$zone does not retrieve the virtual site web page from the /sites hierarchy"
			problem-report "Try apachectl configtest and wget -O - http://www.$zone to diagnose"
		else
			verbose-report "virtual server index retrieval using www.$zone ok"
			((labscore+=3))
		fi
	fi
	((labmaxscore+=3))
	rm -f /tmp/www-site.html
	scores-report "Lab 04 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=4&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "apache2 not installed, skipping lab 04"
fi
fi

if [[ $labnum =~ "5" ]]; then
labscore=0
labmaxscore=0
dpkg -L easy-rsa>&/dev/null
if [ "$?" = "0" ]; then
	lab_header "05"
	package_checks "apache2 easy-rsa"
	dns_lookup_checks secure $zone CNAME
# apache2 modules checks
	if [ ! -f /etc/apache2/mods-enabled/ssl.conf ]; then
		problem-report "ssl module not enabled"
		problem-report "Enable the ssl module using the a2enmod command"
	else
		verbose-report "ssl module enabled ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
	# some checks for site file content
	securedocroot=/sites/secure.$zone
	check_config_file $securesitefile VirtualHost secure.$zone:443
	check_config_file $securesitefile ServerName secure.$zone
	check_config_file $securesitefile DocumentRoot $securedocroot
	check_config_file $securesitefile Directory $securedocroot
	check_config_file $securesitefile SSLEngine on
	check_config_file $securesitefile SSLCertificateFile /etc/ssl/certs/secure.$zone.crt
	check_config_file $securesitefile SSLCertificateKeyFile /etc/ssl/private/secure.$zone.key
	keyfile=`grep -i SSLCertificateKeyFile $securesitefile|grep -v "#" |awk '{print $2}'`
	certfile=`grep -i SSLCertificateFile $securesitefile|grep -v "#" |awk '{print $2}'`
	verbose-report "Certificate filename in site file is $certfile"
	verbose-report "Key filename in site file is $keyfile"
	EASYRSADIR=/etc/openvpn/easy-rsa
	if [[ "$VERSION_ID" = "20.04" ]]; then
		CAKEYDIR=$EASYRSADIR/pki/private
		CACRT=$EASYRSADIR/pki/ca.crt
		CAKEY=$CAKEYDIR/ca.key
		CACRTDIR=$EASYRSADIR/pki/issued
	else
		CAKEYDIR=$EASYRSADIR/keys
		CACRT=$EASYRSADIR/keys/ca.crt
		CACRTDIR=$EASYRSADIR/keys
	fi

	if [ ! -d $EASYRSADIR ]; then
		problem-report "No $EASYRSADIR directory found."
		problem-report "Ensure you have run make-cadir $EASYRSADIR prior to creating certificates."
	else
		verbose-report "$EASYRSADIR directory exists ok"
		((labscore+=1))
		if [ ! -d $CAKEYDIR ]; then
			problem-report "No $CAKEYDIR directory found."
			problem-report "Creating the ca key/cert should have created this directory for you."
		else
			verbose-report "$CAKEYDIR directory exists ok"
			((labscore+=1))
			if [ ! -f $CACRT -o ! -f $CAKEY ]; then
				problem-report "Missing $CACRT or $CAKEY or both."
				problem-report "These files get created when you do build-ca."
			else
				verbose-report "$CACRT and $CAKEY exist"
				((labscore+=1))
			fi
			if [ ! -f $CACRTDIR/secure.$zone.crt -o ! -f $CAKEYDIR/secure.$zone.key ]; then
				problem-report "Missing $CACRTDIR/secure.$zone.crt or $CAKEYDIR/secure.$zone.key or both."
				problem-report "These files get created with you gen-req and sign-req for secure.$zone."
			else
				verbose-report "$CACRTDIR/secure.$zone.crt and $CAKEYDIR/secure.$zone.key exist"
				((labscore+=1))
			fi
			if [ ! -f /usr/share/ca-certificates/comp1071/ca.crt ]; then
				problem-report "Missing ca.crt in /usr/share/ca-certificates/comp1071."
				problem-report "Copy ca.crt from $CACRT to /usr/share/ca-certificates and run dpkg-reconfigure ca-certificates."
			else
				verbose-report "ca.crt found in /usr/share/ca-certificates/comp1071 ok"
				((labscore+=1))
			fi
			awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt  |grep -q -i "COMP1071">&/dev/null
			if [ $? != "0" ]; then
				problem-report "Missing COMP1071 CA cert in /etc/ssl/certs/ca-certificates.crt."
				problem-report "Copy ca.crt from $CACRT to /usr/share/ca-certificates and run dpkg-reconfigure ca-certificates."
			else
				verbose-report "ca.crt found in /etc/ssl/certs/ca-certificates.crt ok"
				((labscore+=1))
			fi
		fi
	fi
	((labmaxscore+=6))
	if [ ! -f "$certfile" ]; then
		problem-report "certificate not installed for secure.$zone in /etc/ssl/certs/$certfile"
		problem-report "Ensure you have a secure.$zone.crt file in /etc/ssl/certs"
		problem-report "Your apache2 site file $securesitefile should have an SSLCERTIFICATEFILE entry that matches the cert file"
	else
		verbose-report "certificate installed for secure.$zone in /etc/ssl/certs ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	if [ ! -f "$keyfile" ]; then
		problem-report "private key not installed for secure.$zone in /etc/ssl/private/$keyfile"
		problem-report "Ensure you have a secure.$zone.key file in /etc/ssl/private"
		problem-report "Your apache2 site file $securesitefile should have an SSLCERTIFICATEKEYFILE entry that matches the key file"
	else
		verbose-report "private key installed for secure.$zone in /etc/ssl/private ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	wget -O /tmp/secure-site.html https://secure.$zone >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve web page from virtual server using secure.$zone"
		problem-report "Try apachectl configtest or wget -O - https://secure.$zone to diagnose"
	else
		diff $securedocroot/index.html /tmp/secure-site.html
		if [ $? != "0" ]; then
			problem-report "Virtual server secure.$zone does not retrieve the virtual site web page from the /sites hierarchy"
			problem-report "Try apachectl configtest and wget -O - http://secure.$zone to diagnose"
		else
			verbose-report "virtual server index retrieval using secure.$zone ok"
			((labscore+=3))
		fi
	fi
	((labmaxscore+=3))
	check_ufw HTTPS 443/tcp
	scores-report "Lab 05 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=5&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "easy-rsa not installed, skipping lab 05"
fi
fi

if [[ $labnum =~ "6" ]]; then
labscore=0
labmaxscore=0
dbinstalled=1
dpkg -L mysql-server>&/dev/null
if [ "$?" != "0" ]; then
	dpkg -L mariadb-server>&/dev/null
	if [ "$?" != "0" ]; then
		problem-report "Neither mariadb or mysql server installed, skipping lab 06"
		dbinstalled=0
	fi
fi
if [ "$dbinstalled" = 1 ]; then
	lab_header "06"
	dpkg -L mariadb-server >& /dev/null
	if [ $? != "0" ]; then
		dpkg -L mysql-server >& /dev/null
	fi
	if [ $? != "0" ]; then
		problem-report "mysql-server or mariadb-server package must be installed"
		problem-report "Use apt-get to install the myql-server package"
	else
		verbose-report "mysql-server or mariadb-server package found ok"
		((labscore++))
	fi
	((labmaxscore++))
	dpkg -L mariadb-client >& /dev/null
	if [ $? != "0" ]; then
		dpkg -L mysql-client >& /dev/null
	fi
	if [ $? != "0" ]; then
		problem-report "mysql-client or mariadb-client package must be installed"
		problem-report "Use apt-get to install the myql-client package"
	else
		verbose-report "mysql-client or mariadb-client package found ok"
		((labscore++))
	fi
	((labmaxscore++))
	package_checks "phpmyadmin webmin"
# check for mysqldump output file
	if [ ! -s /root/mysql-backup.sql ]; then
		if [ ! -s /root/mysql-backup.sql ]; then
			problem-report "mysql-backup.sql not found"
			problem-report "Review the instructions for using mysqldump to create the mysql-backup.sql file"
		else
			verbose-report "mysql-backup.sql found ok"
			((labscore+=2))
		fi
	else
		verbose-report "mysql-backup.sql found ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
	if [ ! -s /home/$firstname/tester-backup.sql ]; then
		if [ ! -s /root/tester-backup.sql ]; then
			problem-report "tester-backup.sql not found"
			problem-report "Review the instructions for using mysqldump to create the tester-backup.sql file"
		else
			verbose-report "tester-backup.sql found ok"
			((labscore+=2))
		fi
	else
		verbose-report "tester-backup.sql found ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))

# check for user tester with employees database
	mysql -u tester --password=tester tester <<< "show columns in location;" >&/dev/null
	if [ $? != "0" ]; then
		mysql -u tester tester <<<"show columns in location;" >&/dev/null
	fi
	if [ $? != "0" ]; then
		problem-report "User tester could not access tester database"
		problem-report "Use the phpmyadmin web interface to ensure that the database tester has been created and the user tester has full access to it"
		problem-report "Ensure you have restored the employees-dump.sql backup file to the tester database."
	else
		verbose-report "Mysql tester database accessed by user tester ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	wget -O - http://localhost/phpmyadmin >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Unable to retrieve phpmyadmin web page from localhost"
			problem-report "Try apachectl configtest and wget -O - http://localhost/phpmyadmin to diagnose"
	else
		verbose-report "phpmyadmin web page ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
	wget -O - --no-check-certificate https://$hostname:10000 >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Unable to retrieve webmin web page from $hostname"
		problem-report "Try apachectl configtest and wget -O - --no-check-certificate https://$hostname:10000 to diagnose"
	else
		verbose-report "webmin site web page ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	check_ufw MySQL 3306/tcp
	check_ufw webmin 10000/tcp
	scores-report "Lab 06 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=6&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "mysql-server-5.7 not installed, skipping lab 06"
fi
fi

if [[ $labnum =~ "7" ]]; then
labscore=0
labmaxscore=0
dpkg -L cups>&/dev/null
if [ "$?" = "0" ]; then
	lab_header "07"
	package_checks "cups printer-driver-cups-pdf"
	check_config_file /etc/cups/cupsd.conf Port 631
	check_config_file /etc/cups/cupsd.conf WebInterface Yes
	check_config_file /etc/cups/cups-pdf.conf TitlePref 1
	check_config_file /etc/cups/cups-pdf.conf Label 2
	lpstat -p PDF >&/dev/null
	if [ $? = "0" -a "$labnum" ]; then
		verbose-report "PDF printer queue found ok"
		((labscore+=2))
	else
		problem-report "PDF printer queue not found with lpstat -t"
		problem-report "Ensure the cups-pdf package installed correctly"
	fi
	((labmaxscore+=2))
	lp -d PDF /etc/cups/cupsd.conf >&/dev/null
	if [ $? = "0" ]; then
		verbose-report "PDF printer queue accepting print jobs ok"
		((labscore++))
	else
		problem-report "PDF printer not accepting print jobs"
		problem-report "Use lpstat -t to diagnose"
	fi
	((labmaxscore++))
	wget -O - http://localhost:631 >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Unable to retrieve CUPS web page from localhost"
		problem-report "Try accessing http://yourip:631 to diagnose"
	else
		verbose-report "CUPS web interface ok"
		((labscore++))
	fi
	((labmaxscore++))
	check_ufw IPP 631
	check_ufw Bonjour 5353
#	cmp /usr/share/cups/mime/airprint.types <<< "image/urf urf string(0,UNIRAST<00>)" >&/dev/null
#	if [ $? != "0" ]; then
#		problem-report "/usr/share/cups/mime/airprint.types missing or has wrong content"
#	else
#		verbose-report "/usr/share/cups/mime/airprint.types ok"
#		((labscore++))
#	fi
#	((labmaxscore++))
#	cmp /usr/share/cups/mime/airprint.convs <<< "image/urf urf application/pdf 100 pdftoraster" >&/dev/null
#	if [ $? != "0" ]; then
#		problem-report "/usr/share/cups/mime/airprint.convs missing or has wrong content"
#	else
#		verbose-report "/usr/share/cups/mime/airprint.convs ok"
#		((labscore++))
#	fi
#	((labmaxscore++))
#	if [ ! -s /etc/avahi/services/AirPrint-PDF.service ]; then
#		problem-report "/etc/avahi/services/AirPrint-PDF.service missing or has wrong content"
#	else
#		verbose-report "/etc/avahi/services/AirPrint-PDF.service ok"
#		((labscore++))
#	fi
#	((labmaxscore++))
	scores-report "Lab 07 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=7&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "cups package not installed, skipping lab 07"
fi
fi

if [[ $labnum =~ "8" ]]; then
labscore=0
labmaxscore=0
dpkg -L postfix>&/dev/null
if [ "$?" = "0" ]; then
	lab_header "08"
	package_checks "postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils roundcube"
	dns_lookup_checks $mydomain mytld MX
	dns_lookup_checks mail $zone A
	if [ ! -f /etc/ssl/certs/mail.$zone.crt ]; then
		problem-report "certificate not installed for mail.$zone in /etc/ssl/certs"
		problem-report "Review the instructions for creating your certificate and ensure you have a mail.$zone.crt file in /etc/ssl/certs"
	else
		verbose-report "certificate installed for mail.$zone in /etc/ssl/certs ok"
		if [ ! -f /etc/ssl/private/mail.$zone.key ]; then
			problem-report "private key not installed for mail.$zone in /etc/ssl/private"
			problem-report "Review the instructions for creating your private key and ensure you have a mail.$zone.key file in /etc/ssl/private"
		else
			verbose-report "private key installed for mail.$zone in /etc/ssl/private ok"
			((labscore+=3))
		fi
	fi
	((labmaxscore+=3))
	basic_postfix_config=1
#	if [ "$(postconf home_mailbox)" != "home_mailbox =" ]; then
#		basic_postfix_config=0
#		problem-report "postfix basic config not complete"
#		problem-report "see lab instructions for setting postfix home_mailbox using postconf"
#	elif [ "$(postconf smtpd_sasl_type)" != "smtpd_sasl_type = dovecot" ]; then
#		basic_postfix_config=0
#		problem-report "postfix basic config not complete"
#		problem-report "see lab instructions for setting postfix smtpd_sasl_type using postconf"
	if [ "$(postconf smtpd_tls_key_file)" != "smtpd_tls_key_file = /etc/ssl/private/mail.$zone.key" ]; then
		basic_postfix_config=0
		problem-report "postfix basic config not complete"
		problem-report "see lab instructions for setting postfix smtpd_tls_key_file using postconf"
	elif [ "$(postconf smtpd_tls_cert_file)" != "smtpd_tls_cert_file = /etc/ssl/certs/mail.$zone.crt" ]; then
		basic_postfix_config=0
		problem-report "postfix basic config not complete"
		problem-report "see lab instructions for setting postfix smtpd_tls_cert_file using postconf"
#	elif [ "$(postconf myhostname)" != "myhostname = mail.$zone" ]; then
#		basic_postfix_config=0
#		problem-report "postfix basic config not complete"
#		problem-report "see lab instructions for setting postfix myhostname using postconf"
	fi
	if [ "$basic_postfix_config" = "1" ]; then
		((labscore+=3))
		verbose-report "Postfix basic config probably ok"
	fi
	((labmaxscore+=3))
	grep "ssl_cert = </etc/ssl/certs/mail.$zone.crt" /etc/dovecot/conf.d/10-ssl.conf >& /dev/null
	if [ $? != "0" ]; then
		problem-report "Dovecot not using /etc/ssl/certs/mail.$zone.crt as certificate"
		problem-report "Review instructions for setting certificate and key in /etc/dovecot/conf.d/10-ssl.conf"
	else
		verbose-report "Dovecot certificate ok"
		grep "ssl_key = </etc/ssl/private/mail.$zone.key" /etc/dovecot/conf.d/10-ssl.conf >& /dev/null
		if [ $? != "0" ]; then
			problem-report "Dovecot not using /etc/ssl/private/mail.$zone.key as key"
			problem-report "Review instructions for setting certificate and key in /etc/dovecot/conf.d/10-ssl.conf"
		else
			verbose-report "Dovecot key ok"
			((labscore+=3))
		fi
	fi
	((labmaxscore+=3))
#	grep "mail_privileged_group = mail" /etc/dovecot/conf.d/10-mail.conf >& /dev/null
#	if [ $? != "0" ]; then
#		problem-report "Dovecot not using mail_privileged_group"
#		problem-report "Review instructions for setting mail_privileged_group in /etc/dovecot/conf.d/10-mail.conf"
#	else
#		echo "Dovecot mail_privileged_group ok"
#		((labscore+=2))
#	fi
#	((labmaxscore+=2))
	wget -O /tmp/roundcube.html http://localhost/roundcube >& /dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve roundcube web page from localhost"
	else
		verbose-report "roundcube web page on localhost ok"
		((labscore+=2))
	fi
	((labmaxscore+=2))
	check_ufw SMTP 25/tcp
	check_ufw "SMTP submission" 587/tcp
	check_ufw POP3 110/tcp
	check_ufw IMAP 143/tcp
	scores-report "Lab 08 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=8&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "postfix package not installed, skipping lab 08"
fi
fi

if [[ $labnum =~ "9" ]]; then
labscore=0
labmaxscore=0
dpkg -L vsftpd>&/dev/null
if [ "$?" = "0" ]; then
	lab_header "09"
	package_checks "samba vsftpd"
	smbclient -U student //localhost/student Password01 <<< "ls" >/dev/null
	if [ $? != "0" ]; then
		problem-report "unable to access student share using smbclient"
	else
		verbose-report "student samba share ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	wget -O /tmp/ftp.html ftp://localhost/index.html >&/dev/null
	if [ $? != "0" ]; then
		problem-report "Failed to retrieve index.html via anonymous ftp from localhost"
	else
		verbose-report "anonymous ftp on localhost ok"
		((labscore+=3))
	fi
	((labmaxscore+=3))
	check_ufw Samba 137,138/udp
	check_ufw Samba 139,445/tcp
	check_ufw FTP 21/tcp
	scores-report "Lab 09 score is $labscore out of $labmaxscore"
	score=$((score + labscore))
	maxscore=$((maxscore + labmaxscore))
	scores-report "   Running score is $score out of $maxscore"
	scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=9&score=$labscore&maxscore=$labmaxscore"
	curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
else
	problem-report "vsftpd package not installed, skipping lab 09"
fi
fi

# leave the logfile in place for troubleshooting
