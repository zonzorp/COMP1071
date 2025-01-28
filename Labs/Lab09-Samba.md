# Lab 9 File Sharing

## Overview
In this lab, you will install and do basic configuration of Samba and FTP services.

## Software install

Install the **samba**, **smbclient**, and **vsftpd** packages:

```
sudo apt update
sudo apt install samba smbclient vsftpd
```

## Review service status

Check the status of the services:

```
sudo service smbd status
sudo service nmbd status
sudo service vsftpd status
```

## Configure home directory sharing with Samba

Configure Samba to share user home directories in read-write mode by editing **/etc/samba/smb.conf**. Test your file:

```
testparm
```

Correct any errors. Restart samba:

```
sudo service smbd restart
```

Verify you can see your shares:

```
smbclient -L localhost
```

Make your Linux account available for Samba use:

```
pdbedit -a -u yourfirstname
``` 

Verify your account is available for use with samba:

```
pdbedit -L -v
```

Test that you can access your home directory share. 

```
echo "ls" | smbclient -U yourfirstname //localhost/yourfirstname yourpassword
```

## Add a new user to the server who will only use it to hold files for use on a Windows client

Create a Linux user named **student** with a shell of **/bin/nologin** and a home directory to be used to hold files for a windows-only user:

```
sudo useradd -m -s /bin/nologin student
```

Do not set a password on the account, leave it locked. Use ```pdbedit``` to add that user to samba:

```
pdbedit -a -u student
```

Set the student user samba password to **Password01** so that the server check script can test it. Check that the student user has valid SMB access to their home directory hosted on your Linux server:

```
echo "ls" | smbclient -U student //localhost/student Password01
```

## Set up FTP service

1. Edit your **/etc/vsftpd.conf**.
   1. Verify that you have anonymous enabled (_anonymous_enable_) but set to _read only_ (no _anon_upload_enable_).
   1. Verify that local users are allowed to log in (_local_enable_) and write files (_write_enable_).
   1. If you make changes to the settings, restart the vsftpd service.
1. Verify you can access your ftp server with your personal account using the ftp command.

```
ftp localhost
<login to the ftp server using your personal account>
ls
logout
```
1. Create a file named **index.html** in the anonymous ftp directory (**~ftp**).
   * Make the content something that clearly identifies the file (e.g. _This is the index file from the ftp server_).
```
sudo echo "Your text" > ~ftp/index.html
```
1. Make sure the file is owned by the user **ftp**.
```
chown ftp ~ftp/index.html
```
1. Verify you can see the document using `wget` or `curl ` or with a web browser using the url **ftp://your-ip-address/index.html**.
```
curl ftp://your-server-ip/index.html
```

## Firewall Rules

Add UFW rules to allow smb, nmb, and ftp service through your firewall:

```
sudo ufw allow 21/tcp
sudo ufw allow 137,138/udp
sudo ufw allow 139,445/tcp
```

## Completing the semester assignment

Run the server-check.sh script for all 9 labs to ensure your marks are recorded for the semester assignment final mark;

```
sudo /root/server-check.sh firstname lastname studentnumber
```

