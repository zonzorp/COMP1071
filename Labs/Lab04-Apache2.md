# Lab 04 Apache2

In this lab you will set up Apache2 and configure a virtual server. You will practice incorporating modules, and test your web service.

## Software Install
Install the Apache2 package using ```apt-get install apache2```.

Add a UFW rule to allow web browsing service through your firewall ( ```ufw allow 80/tcp``` ). Test that you can access your web service with a browser on your host laptop, accessing it using the IP address in the URL (**http://pcNNNNNNNNN**). Verify you see the Apache2 default page describing the available documentation and configuration basics.

Try reloading your apache configuration files using ```apachectl graceful```. Note the suggestion to set a default server name.

## Apache Configuration
Create a file named **defaulthostname.conf** in **/etc/apache2/conf-available** and put your server's name in it using the ServerName directive(i.e. _ServerName pcNNNNNNNNN_). Enable the new conf file using ```a2enconf defaulthostname```. Restart your Apache service and verify you get no more errors or suggestions. Test retrieving the default web page using ```wget -O - http://pcNNNNNNNNN``` and ```telnet pcNNNNNNNNN 80```. Verify you can still access the default site home page using your web browser to access **http://pcNNNNNNNNN**. Try to access your personal public_html document directory using **http://pcNNNNNNNNN/~your-username**. That should result in an error saying document not found.

## userdir Module
Enable the **userdir** module using ```a2enmod userdir```. Reload your apache configuration. Try to access your personal public_html document directory using **http://pcNNNNNNNNN/~your-username**. You should now see a directory listing showing an empty directory.

## userdir Module Security
We don't want directory listings to be available by default, so modify the **mods-available/userdir.conf** file to not include **Indexes** in the Directory permissions **Options** line. Use the **AllowOverride** directive to permit the users to override the missing **Indexes** directive using **.htaccess** files at their discretion (i.e. add **Options=Indexes** to an **AllowOverride** line in the **Directory** stanza of **mods-available/userdir.conf**).
After the edit, your file might look like this:

```
<IfModule mod_userdir.c>
	UserDir public_html
	UserDir disabled root

	<Directory /home/*/public_html>
		AllowOverride FileInfo AuthConfig Limit Indexes Options=Indexes
		Options MultiViews SymLinksIfOwnerMatch IncludesNoExec
		<Limit GET POST OPTIONS>
			Require all granted
		</Limit>
		<LimitExcept GET POST OPTIONS>
			Require all denied
		</LimitExcept>
	</Directory>
</IfModule>
```

Reload your configuration for apache using ```apachectl graceful``` and verify your browser can no longer get directory listings for your personal public_html pages.

## Ordinary User web page publishing
The commands in this paragraph should be run as your ordinary user, not root. In your public_html directory, create a file named index.html. Put some text in your index.html file to identify it as your personal web page (e.g. This is my personal page). Verify that the page shows up correctly when accessing your server with a browser (e.g. http://pcNNNNNNNNN/~firstname).
```
As the normal user, not sudo:

mkdir ~/public_html
echo "<h1>Some text to identify your site</h1>" > ~/public_html/index.html
wget -O - http://pcNNNNNNNNNN/~username
curl http://pcNNNNNNNNNN/~username
```
Also test accessing your server using using wget -O - http://pcNNNNNNNNN/~yourfirstname. and curl http://pcNNNNNNNNN/~your-username. Create a subdirectory named pics in your public_html. Use `curl http://zonzorp.net/pics.tgz|tar xzf -` to install some sample picture files into that `pics` directory. Try to access that using your browser with http://pcNNNNNNNNN/~firstname/pics as the URL. It should fail because there is no index file. Add a **.htaccess** file to the pics directory with `Options +Indexes` in it as an override for the directory, and try reloading the pics directory with your browser. It should show a list of picture files. Clicking on a file will try to open that file.
```
mkdir ~/public_html/pics
cd ~/public_html
curl http://zonzorp.net/pics.tgz|tar xzf -
chmod 755 pics
chmod 644 pics/*
wget -O - http://pcNNNNNNNNNN/~username/pics
echo "Options +Indexes" > ~/public_html/pics/.htaccess
wget -O - http://pcNNNNNNNNNN/~username/pics
```

## Create a virtual site for www.lastname.mytld
Create a new site for **www.yourdomain** in **/etc/apache2/sites-available** by copying the default site file already there to a file named **www.yourdomain.conf**. Configure your _VirtualHost_, _ServerAdmin_, _ServerName_, _DocumentRoot_ and _Directory_ directive for your _DocumentRoot_ in the site file for **www.yourdomain** as folllows:
```
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/www.yourdomain.conf
nano /etc/apache2/sites-available/www.yourdomain.conf
```
```
VirtualHost www.yourdomainname:80
ServerName www.yourdomainname
ServerAdmin webmaster@yourdomainname
DocumentRoot /sites/www.yourdomainname
Directory stanza to include Require all granted
```
An example file modifed as required might look like this:

```
<VirtualHost www.sim.mytld:80>
	ServerAdmin webmaster@www.sim.mytld
	ServerName www.sim.mytld
	DocumentRoot /sites/www.sim.mytld
	<Directory /sites/www.sim.mytld/>
		Require all granted
	</Directory>
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

Create a directory named **/sites** to hold document stores for virtual servers and a directory named **www.yourdomain** in **/sites** to hold the specific document store for the www site you are creating. Add an **index.html** to the **/sites/www.domain** directory with content to identify that page as the home page for your site (e.g. ```This is the home page for www.yourdomain```). Enable your site using ```a2ensite www.yourdomain``` and restart your apache service using ```apachectl graceful```. Verify you can access the site using a browser, **wget**, **curl**, or **telnet** for the url **http://www.yourdomain**. Verify you can access your personal home page on your new site  (i.e. **http://www.yourdomain/~yourfirstname** ).
```
mkdir -p /sites/www.yourdomain
echo "<h1>This is the www.yourdomain website</h1>" > /sites/www.yourdomain/index.html
a2ensite www.yourdomain
apachectl graceful
curl http://www.yourdomain
```

## Review log files
Examine the content of **access.log** and **error.log** in **/var/log/apache2** to see what is being logged for your activity on your web server.
```
tail /var/log/apache2/access.log /var/log/apche2/error.log
```

### Evaluate your server
Run ```sudo /root/server-check.sh -l 4 firstname lastname studentnumber```. Review any problems detected and correct as necessary. Do not move on to [Lab 5 SSL](Lab05-SSL.html) until you have Lab 4 at 100%. If you are having trouble getting Lab 4 to 100%, try running ```sudo /root/server-check.sh -l 123 firstname lastname studentnumber``` to make sure you haven't accidentally broken what was completed in previous labs.

## Additional Resources to get more out of the web server software
Using a browser, go to the Apache2 documentation site and review the list of modules and directives to see what sort of things can be done with an Apache2 server.
