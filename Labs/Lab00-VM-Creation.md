# Lab 00 - Create a new VM for the course

## Virtual Machine (VM) Creation
In this lab, you will create a new Ubuntu Linux installation on a virtual machine. Create a virtual machine specifically for this class, as performing other tasks on it may modify the configuration in undesirable ways. Do NOT use the VMWare easy install option, or you will lose control over how the install is done and you may wind up having to start over. If you are using VMWare, disabling easy-install/auto-install is less than obvious, but [this webpage describes the procedure](https://www.computersnyou.com/371/how-to-disable-easy-installing-feature-in-vmware-workstation/).
1. Download the Ubuntu server 20.04 iso image from [Canonical](https://ubuntu.com) while you perform the next steps, as the download may take a little while.
1. Create a **new virtual network** in your VM software which is set to type **host-only with dhcp enabled**. We will be using this for our second network interface on our server, so pay attention to the name assigned to it by your VM software.
1. Create a **new virtual machine** in your VM software. Name the virtual machine whatever you like. We will be changing this later.
1. Assign at least 2 CPUs, 1GB of RAM, and 16GB of disk. You can assign more resources if you wish, but it is unnecessary.
1. Set the network interface of your VM to bridged.
1. Add a **second network interface** to your virtual machine, *connected to the virtual host-only ethernet network you just created*.
1. Set the CD drive to use your downloaded Linux image as the install image.
1. Start your virtual machine to boot from your downloaded iso image.

## Ubuntu Install
When you have created the VM, you can start the install by choosing Continue or powering on the VM, depending on which virtualization software you are using. The install questions asked will depend somewhat on which VM software you are using and what version of that software you are running. Do not use any Quick Install, Easy Install, or Auto Install options. Deselect them if they are selected by default. The selections to make during the install are given here for Ubuntu 20.04LTS Server.
* Whenever you are asked to select a language, select **English** as the language.
* Choose to install **Ubuntu** or **Ubuntu Server** if you are given choices about what to install.
* The keyboard layout for most laptops is most commonly **US English**. If you are on a Mac, you will want to use the **Variant** menu to select a Macintosh keyboard layout.
* When the network information is displayed, take note of the IP address of the second interface. This will be the address to connect to using SSH after the installation completes.
* Leave the http proxy blank.
* Use the entire disk for your disk partitioning. Use the default disk choice, and the default partitioning.
* Use **Default User** for your full name. Set the hostname of to be **pcNNNNNNNN** where **NNNNNNNN** is your full student number. Set the default username to **ubuntu**. Assign a password you can remember.
* Install OpenSSH Server when it is offered. You do not need to import an SSH identity. Do not install any other optional software.
* Reboot when it is offered as a choice.

After reboot completes and the ssh initialization finishes, remotely connect with ssh to your server (using putty on windows or a terminal window on any other operating system).

## Software update
Log onto the default **ubuntu** account. Run the following commands to ensure your software is up to date and ensure the the curl tool is installed (it should be by default) which is used by the server-check script.

```bash
sudo apt update
sudo apt upgrade
sudo apt install curl
```

## Create a snapshot
Use the following command to properly shutdown your ubuntu VM.

```bash
sudo poweroff
```

When the VM has finished shutting down, use your file manager to find the files for your VM, which typically will be in a directory called `Virtual Machines` in your home directory. Open the file for your vm called VMNAME.vmx and add the following line to the end of the file.
```bash
disk.EnableUUID = "TRUE"
```

Now use the VM or Virtual Machine menu in VMWare to create a snapshot. You should create a snapshot after every lab is completed, so that if you mess something up, the worst impact is that you will have to go back to your snapshot and redo the current lab. If you don't have the snapshots, you will have to start back at lab 0 if you mess up your VM during the semester. Once you have made the snapshot, you can run the VM again in VMWare so that it is ready for use in the next lab.

## Grading
This lab is intended to create a VM you can use the rest of the semeter. There is no marking or grading of this lab. If you do not perform this lab correctly, you will not be able to complete the future labs. So this lab is required but not graded.
