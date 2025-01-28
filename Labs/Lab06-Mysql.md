# Lab 6 Database Service

## Overview
In this lab, you will install the MySQL server software, phpmyadmin web application and webmin web application.

## Install software
Install the mysql-server and mysql-client packages.
```
sudo apt update
sudo apt install mysql-server mysql-client
```

## Service status check
Use the **mysqladmin** tool to view the database service **processlist**:

```
sudo mysqladmin -u root processlist
```

and **status**:

```
sudo mysqladmin -u root status
```

To see what state your database service is in, and the most recent log messages, you can use the **service** command:

```
service mysql status
```

## Database Backup
Use the **mysqldump** tool to dump the mysql database to a file named **mysql-backup.sql** in root's home directory

```
sudo mysqldump -u root mysql --result-file=/root/mysql-backup.sql
```

Use the **more** command to see what the sql backup file contains.

## Database access check
Use the **mysql** command line tool

```
sudo mysql -u root 
```

to show a list of databases

```
show databases;
```

the list of tables for the mysql database

```
show tables from mysql;
```

and the columns of the user table within the mysql database

```
show columns from user from mysql;
```
and set a root password for the database root user
```
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
flush privileges;
```
You can quit the interactive mysql tool with

```
exit
```

## Firewall rule for direct MySQL access over the network
Add a UFW rule to allow mysql access through your firewall

```
sudo ufw allow 3306/tcp
```

## Setup the phpmyadmin web application
Install the **phpmyadmin** and **php-gettext** packages. Select **Yes** to configure the database for **phpmyadmin** with **dbconfig-common**. Set the mysql application password for phpmyadmin which is the application's internal user. Check the **phpmyadmin.conf** file in **/etc/apache2/conf-available** to view the default configuration added to your Apache2 service in order to provide the phpmyadmin application. Note the URL Alias to access the application using a browser, in the _Alias_ directive near the start of the file.

Verify you can access the phpmyadmin web interface using a web browser on your host laptop to view the database server status and configuration (```http://yourserver/phpmyadmin```).

## Use phpmyadmin web app to create a database user and database
Login to the **phpmyadmin** web interface with the **root** login. Select the tab for _User Accounts_. Click on the link for **add user account**. Use _tester_ as both the user name and the user's password. Check the box to create a database of the same name and grant all privileges to it for the new user. Click on the **Go** icon at the bottom of the form. You now have a **tester** user who has a new empty database named **tester** which that user has full control over.

## Use the command line to restore a database backup
Download the **employees-dump.sql** database backup file from ```https://zonzorp.github.io/COMP1071/employees-dump.sql```  to your virtual server

```
wget -O /root/employees-dump.sql https://zonzorp.github.io/COMP1071/employees-dump.sql
```

Restore the employees database backup you downloaded into your **tester** database. Connect to your mysql server, use the **tester** database, and use show tables to see what was restored:

```
mysql -u tester -p tester < /root/employees-dump.sql
mysql -u tester -p
use tester;
show tables;
exit;
```

Try using the select sql command to view the contents of the 3 tables in the tester database (e.g. ```select * from tablename;```). Create your own backup of the newly restored tester database using **mysqldump** to dump just the **tester** database:

```
mysqldump -u tester -p --result-file=/root/tester-backup.sql tester
```

## Add a private repository and install the webmin web application from it
Add a file to your **/etc/apt/sources.list.d** directory named **webmin.list** with the following line in it:

```
deb http://download.webmin.com/download/repository sarge contrib
```

Run apt commands to install the signer's key, update the software database, and install the webmin application.

```
wget -O - http://www.webmin.com/jcameron-key.asc|apt-key add -
apt update
apt install webmin
```

## Allow access to the webmin web app through your firewall
Add a rule to ufw to allow tcp access to port 10000 (e.g. ```ufw allow 10000/tcp```), then use a browser on your host laptop to access **https://yourserver:10000**. Log in using your personal account on your virtual server, and use the index on the left to expand the _Servers_ section, then click on _MySQL_ to see an alternate way to manage a database server.

## Review log files
Examine the content of **error.log** in **/var/log/mysql** to see what is being logged for your mysql server.

### Evaluate your server
Run ```sudo /root/server-check.sh -l 6 firstname lastname studentnumber```. Review any problems detected and correct as necessary. Do not move on to [Lab 7 CUPS](Lab07-CUPS.html) until you have Lab 6 at 100%. If you are having trouble getting Lab 6 to 100%, try running ```sudo /root/server-check.sh -l 12345 firstname lastname studentnumber``` to make sure you haven't accidentally broken what was completed in previous labs.
