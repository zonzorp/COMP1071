# Lab 01 - Preparation of Server for lab use

## Logging into your Ubuntu server
If you are using Windows, the default console of your VM software will be very small and unfriendly to use for most people. No, I don't know why they make VM software like that. The Linux console has no requirements that make VM software developers do that.

If you are on a Mac, the default VM console is better, but you can use the Mac terminal application to get an even more friendly tool.

If you are on Windows, you can use powershell to run ssh or you may want to install and use a terminal emulator program such as [putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html).

Whatever terminal program you are using, you will start it and connect to your VM using ssh. Before we can connect with ssh, we need ssh running on the server and to know the address to connect to. The VM software will not tell us our address, so we should log in at least once to the VM in order to find it.
If you missed installing the ssh service in the previous lab, run the following commands from the console of your VM to ensure the ssh service is installed, and then display your server's current ip addresses.
```bash
sudo apt update
sudo apt install openssh-server
hostname -I
```
Now you can connect to your VM using a remote terminal.

### Connecting to your VM from a Mac or Linux system
1. Start a terminal app.
1. *Mac users:* You can find the terminal app on the Mac **Utilities** menu when you click on the Applications launcher. We will be using it a lot during the semester, so you might want to choose **Options**->**Keep In Dock** from the right-click menu on the app icon in the dock.
1. *Windows Users:* You can use the powershell terminal window to run ssh as long as you are running at least Windows 10. Open the Start menu, and then the Windows Powershell submenu, then the Windows Powershell tool. We will be using it a lot during the semester, so you might want to pin it to the taskbar or something useful to you to help you find it back in the future.
1. Enter the following command in the terminal window to log into your lab Linux server on the **ubuntu** user account when the terminal shows the prompt. Use the second ip address that was displayed by the `hostname -I` command on the console of your VM.
```bash
ssh ubuntu@<ip-address-of-your-vm>
```
1. If you get asked to confirm connecting to the server for the first time, enter `yes`.

### Connecting to your VM from a Windows system
Windows versions a few years old or more do not include a client program for secure command line access to remote systems. There are multiple options for this but all of them will have to be downloaded and installed. I personally recommend the putty program which has been around a long time, and is simple to install and use. If you already have the putty program and the puttygen program installed and are familiar with them, or have another ssh client program with key generation capabilities already installed that you are familiar with, feel free to to use that and skip the installation steps and got straight to connecting to the lab Linux server. If you do not have putty and puttygen installed, or an alternative to them, follow all the steps to install and start using putty.

#### Installing and using putty to connect to your lab Linux server (optional if you have another ssh tool)
1. Download the [putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) installer program.
1. Even if you have putty installed, you will also need the puttygen program, so you will need to check your start menu under putty to see if you have the puttygen program. If you do not have the puttygen program, you will need to install it too.
1. Choose the 64-bit MSI (Windows Installer) file to download and install from the [putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) website.
1. Once the installer downloads, run the installer.
1. *Pro tip for Windows users:* You can pin the putty program to your taskbar or copy/link it on your desktop, as you will be using it throughout the semester.
1. Start putty and enter the second ip address of your lab Linux server from the `hostname -I` command we ran on the VM console in the box for hostname or IP address. We will not save a profile at this time, because the IP address for our lab Linux server will be changing in the next lab. Once we change it in the next lab, we will not be changing it again, and you can save a profile at that time.
1. Click on the **Open** button. A terminal window will open that you can use to login to your lab Linux server.
1. If you get asked to confirm connecting to the server for the first time, enter `yes`.
1. Log onto the default **ubuntu** user account in the terminal window putty gave you.

## Software update and repo setup
All of the remaining commands in this lab are to be run on your lab Linux server, in the remote access terminal window. Install the system resource monitoring tools and user programs that we will be using, which may not already be installed.  The following commands can be used to install this software:

```bash
sudo apt update
sudo apt install sysstat memstat sl fortune cowsay tree glances htop
```

## Ubuntu user creation
Set up the default home directory contents for new users that get created on this system. Make the following directories in `/etc/skel`:
* **bin**
* **Documents**
* **Downloads**
* **Pictures**
* **public_html**

Create a text file called `/etc/skel/.bash_login` with commands in it to add the games and personal bin to the user's PATH, and run fortune through cowsay on every login:
```bash
export PATH=$PATH:/usr/games:~/bin
[ -f ~/.bashrc ] && . ~/.bashrc
fortune|cowsay
```

Example commands to make those directories and create that file:
```bash
sudo mkdir /etc/skel/{bin,Documents,Downloads,Pictures,public_html}
cat >~/.bash_login <<EOF
export PATH=$PATH:/usr/games:~/bin
[ -f ~/.bashrc ] && . ~/.bashrc
fortune|cowsay
EOF
sudo cp ~/.bash_login /etc/skel
```

Next we will create a personal account to use. It will be created using your own name. Do not use special characters such as dashes, spaces, or apostrophes. The full name can be mixed case (e.g. First Last), but use only lower case when entering your username for the account. The account username must be your first name. Refer to the _Ubuntu Server Guide_ if necessary for more information on managing user accounts.
```
sudo adduser firstname
```
Add your user account to the **sudo** group, so you can use `sudo` from it. The command will look similar to this:
```
sudo usermod -a -G sudo firstname
```
Set a secure password onto your account using `passwd firstname`. For the remaining labs this semester, log onto your server using the account you just created. Log out of the **ubuntu** account, and log onto your new personal account.

Verify you can run the following commands:
```
memstat
sl
fortune
iostat
sudo ss -tlpn
```
Use the `df -h` command to see how much free space you have on your server. Review the descriptive first paragraph of the man page for each of the commands on the slides from the presentation. Try each of the id, who, w, last, du, mount, lshw, lspci, lsusb, lscpu, ps, vmstat, prtstat, netstat, top, dpkg commands on your VM.

Download the `server-check.sh` script from **github** and run it for the first lab.
```
sudo /root/server-check.sh -l 1 firstname lastname studentnumber
```
