```
   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$                               
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$                               
.$$$?        $$$$                                                              
=$$$         $$$I
 $$$$.      =$$$. , .$$$$$$$7 .$$$.$$$$$   .$$$   .$$$$$$I   $$$    $$$$
 +$$$$$     $$$$   $$$$$$$$$,  $$$$$$$$$I  I$$$  ~$$$$$$$$$  $$$,  :$$$
   7$$$     $$$$  $$$$  ?$$$   $$$.  $$$$  $$$= .$$$$  7$$$  $$$~  $$$, 
           +$$$7 .$$$   $$$7  =$$$   $$$$ .$$$  $$$$   7$$$  $$$+ $$$$
           $$$$: I$$I   $$$,  $$$+   $$$. I$$$  $$$$   $$$$  $$$I,$$$
           $$$$  I$$$?,7$$$  .$$$: ?$$$$  $$$$  $$$$: 7$$$.  +$$$$$$
           $$$?   $$$$$:$$$~ I$$$$$$$$.   $$$=  .$$$$$$$$    .$$$$$,
                             $$$$        .$$$                 $$$$,
                             $$$+        I$$$                $$$$7             
                             +++     ,~~~$$$+~~~~~~~~~~~~+I$$$$$,              
                                 ~$$$$$$$$$$$$$$$$$$$$$$$$$$$$$                
                               ,$$$$$$$$$$$$$$$$$$$$$$$$$$$7~                  
                               $$$$     $$$$
                              ?$$$      $$$=
                              7$$$     $$$$             
                               $$$$$$$$$$$             
                               .$$$$$$$$:
```

Environment Setup:
==================

Setup PATH and MANPATH
----------------------
* edit `/etc/paths` to look like...

```
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
```

* edit `/etc/manpaths` to look like...

```
    /usr/local/man
    /usr/local/share/man
    /usr/share/man
```

* restart your terminal to pull in the new paths

Install xcode
-------------
* use the dvd that came with your mac or download from apple


Git configurations
------------------
* Create github.com account if necessary
* In github, fork main tapjoyserver repository
  * main repo location: `https://github.com/Tapjoy/tapjoyserver` (may need to be given access)
  * click "Fork"
* Add your SSH key to github
  * see Account Settings->SSH Public Keys->Need help with public keys? for full instructions
* Clone your forked repo locally

```
git clone git@github.com:[your github nickname]/tapjoyserver.git
```

* Add main tapjoyserver repo as remote repo (for updating your code with the latest)

```
git remote add tapjoy git@github.com:Tapjoy/tapjoyserver.git
```

* important that it's named "tapjoy" for deploy script to work


Downgrade rubygems
------------------
* Uninstall existing versions if necessary
  * use `gem list` to determine if versions exist
  * if applicable, use `gem uninstall rubygems-update -v [version]` to remove

```
sudo gem install rubygems-update -v 1.3.7
sudo update_rubygems _1.3.7_
```

Install MySQL
-------------
* download `http://s3.amazonaws.com/dev_tapjoy/rails_env/mysql-5.1.56-osx10.6-x86_64.dmg`
* download `http://s3.amazonaws.com/dev_tapjoy/rails_env/my.cnf`
* copy `my.cnf` to `/etc/my.cnf`
* run the main installer in the mysql dmg
* run the startup item installer in the mysql dmg
* run the pref pane in the mysql dmg

Add mysql to the `PATH` and `MANPATH`
-------------------------------------
* create the file `/etc/paths.d/mysql` with the following line...

```
    /usr/local/mysql/bin
```

* create the file `/etc/manpaths.d/mysql` with the following line...

```
    /usr/local/mysql/man
```


Start MySQL
-----------
* start MySQL via the pref pane in System Preferences


Install memcached and ImageMagick
---------------------------------
* download `http://s3.amazonaws.com/dev_tapjoy/rails_env/magick-installer.sh`
* run `magick-installer.sh` (this will install memcached and ImageMagick and all dependencies)

Setup memcached to start on boot
--------------------------------
* download `http://s3.amazonaws.com/dev_tapjoy/rails_env/Memcached.applescript`
* open the applescript and save the script as an Application in your `/Applications` directory
* open the System Preferences and navigate to the Users & Groups section
* add the Memcached app as a Login Item for your user account
* run the Memcached app manually to start the process

Copy config files into place
----------------------------

```
    cp tapjoyserver/tapjoyads/config/newrelic-test.yml tapjoyserver/tapjoyads/config/newrelic.yml
    cp tapjoyserver/tapjoyads/config/database-default.yml tapjoyserver/tapjoyads/config/database.yml
    mkdir tapjoyserver/tapjoyads/tmp
    mkdir tapjoyserver/tapjoyads/log
    cp tapjoyserver/tapjoyads/config/local-default.yml tapjoyserver/tapjoyads/config/local.yml
```

open `local.yml` and change the urls to point to the local address of the app (ex: `http://tapjoy.local` or `http://localhost:3000`)

Download GeoIP database
-----------------------
* download `http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz`
* extract database file and move it into place

```
    gunzip GeoLiteCity.dat.gz
    mv GeoLiteCity.dat tapjoyserver/tapjoyads/data/GeoIPCity.dat
```

Install required gems
---------------------

```
sudo env ARCHFLAGS="-arch x86_64" gem install memcached -v 1.2.7
sudo env ARCHFLAGS="-arch x86_64" gem install mysql -v 2.8.1 -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
sudo gem install rcov -v 0.9.10
sudo gem install -v 2.3.14 rails
sudo gem install rdoc
sudo gem install rdoc-data
```
Then from within the tapjoyserver/tapjoyads directory:
```
sudo rake gems:install
```

Set up accounts and database
----------------------------
* Create developer account at `dashboard.tapjoy.com` and have someone give you the "admin" role
* Sync prod db with local db (this will overwrite any pre-existing changes)

```
rake admin:sync_db
```

* Now you have an admin account in production and locally

Add wkhtmltoimage binary (this is so ad previews will work)
-----------------------------------------------------------
* Utilized by imgkit gem
* For OSX:
  * Download binary from: http://code.google.com/p/wkhtmltopdf/downloads/detail?name=wkhtmltoimage-OSX-0.10.0_rc2-static.tar.bz2&can=2&q=
* For other OS's:
  * Find and download appropriate **wkhtmltoimage** binary at http://code.google.com/p/wkhtmltopdf/downloads/list
* sudo mv [filename] /usr/local/bin/wkhtmltoimage

Download desired editor (most people use TextMate) and set it to use soft tabs (2 spaces)
-----------------------------------------------------------------------------------------
*  Instructions for TextMate:
  * TextMate -> Preferences -> Advanced -> Shell Variables
  * Add `TM_SOFT_TABS` with value of YES (make sure it doesn't convert the TM to a ™ symbol)
  * Add `TM_TAB_SIZE` with value of 2
  * See `http://manual.macromates.com/en/environment_variables.html` if curious about other TextMate shell variables

RECOMMENDED: Set git pre-commit hook to run
----------------------------------------
* The pre-commit hook runs before any git commit.
* It automatically strips trailing whitespace and adds newlines to the end of files, which is compliant with our style guide.

```
cp tapjoyserver/setup/pre-commit tapjoyserver/.git/hooks/
```

Alternatively, use `ln -s` instead of `cp` so any updates to the script in the repo get automatically changed in the git folder.

OPTIONAL: to install Passenger (so you can use alternate local domains instead of `http://localhost:3000`)
--------------------------------------------------------------------------------------------------------

```
sudo gem install passenger
sudo passenger-install-apache2-module (follow on-screen instructions)
```

* Open `/etc/apache2/httpd.conf` and remove the '#' in front of `Include /private/etc/apache2/extra/httpd-vhosts.conf`
* Open `/etc/apache2/extra/httpd-vhosts.conf` and replace contents with the following:

```
    # My Virtual Hosts
    NameVirtualHost *:80

    <VirtualHost *:80>
      DocumentRoot "/path/to/tapjoyserver/tapjoyads/public"
      ServerName tapjoy.local
      RailsEnv development
      RailsBaseURI /
      <Directory "/path/to/tapjoyserver/tapjoyads/public">
        Options FollowSymLinks
        Options -MultiViews
        AllowOverride None
        Order allow,deny
        Allow from all
      </Directory>
    </VirtualHost>

    <VirtualHost *:80>
      DocumentRoot "/Library/WebServer/Documents"
      ServerName localhost
    </VirtualHost>
```

* Open `/etc/hosts` and add `127.0.0.1   tapjoy.local` to the end of the file 
* To start Apache in OSX, System Preferences -> Sharing -> Check checkbox for 'Web Sharing'

OPTIONAL: To install sinatra-rubygems (for easy access to local gem Rdocs)
--------------------------------------------------------------------------

```
sudo gem install sinatra
git clone git://github.com/jnewland/sinatra-rubygems.git
```

* Open `/etc/apache2/extra/httpd-vhosts.conf` and append the following to the end:

```
  <VirtualHost *:80>
    DocumentRoot "/path/to/sinatra-rubygems/public"
    ServerName gems.local
    RackEnv production
    RackBaseURI /
    <Directory "/path/to/sinatra-rubygems/public">
      Order allow,deny
      Allow from all
    </Directory>
  </VirtualHost>
```

* Open `/etc/hosts` and add `127.0.0.1   gems.local` to the end of the file
* To restart Apache: `sudo apachectl restart`
