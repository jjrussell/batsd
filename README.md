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

Install osx-gcc
-------------
* Download and install [osx-gcc](https://github.com/kennethreitz/osx-gcc-installer/downloads).

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

### System Ruby

```
sudo gem install rubygems-update -v 1.3.7
sudo update_rubygems _1.3.7_
```

### RVM

```
rvm rubygems 1.3.7
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

### System Ruby

```
sudo env ARCHFLAGS="-arch x86_64" gem install memcached -v 1.2.7
sudo env ARCHFLAGS="-arch x86_64" gem install mysql -v 2.8.1 -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
sudo gem install rcov -v 0.9.10
sudo gem install -v 2.3.14 rails
sudo gem install json -v 1.5.3
sudo gem install rdoc
sudo gem install rdoc-data
sudo rdoc-data --install
```

### RVM
```
env ARCHFLAGS="-arch x86_64" gem install memcached -v 1.2.7
env ARCHFLAGS="-arch x86_64" gem install mysql -v 2.8.1 -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
gem install rcov -v 0.9.10
gem install -v 2.3.14 rails
gem install json -v 1.5.3
gem install rdoc
gem install rdoc-data
rdoc-data --install
```

Then from within the `tapjoyserver/tapjoyads` directory:
```
bundle install
```

Set up accounts and database
----------------------------
* Create developer account at `dashboard.tapjoy.com` and have someone give you the "admin" role
* Sync prod db with local db (this will overwrite any pre-existing changes)

```
rake admin:sync_db
```

* Now you have an admin account in production and locally

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

# Running tapjoyads
Using Unicorn and Foreman, you can run the application directly from the `tapjoyserver/tapjoyads` directory by running:

```
foreman start
```

If you need to restart the application, simply `ctrl+c` and then re-run the command.

To access directly, go to [http://127.0.0.1:8080]().  Otherwise, use one of the following methods.

## OPTIONAL: Using Apache for alternate local domains (instead of `http://localhost:3000`)
### Routing to Unicorn (prefered)

* Open `/etc/apache2/httpd.conf`, make sure `Include /private/etc/apache2/extra/httpd-vhosts.conf` is commented.
* In the same file, add `Include /private/etc/apache2/extra/httpd-proxy.conf` after `httpd-vhosts.conf`.
* Open `/etc/apache2/extra/httpd-proxy.conf` and add the following contents:

```
ProxyRequests Off

<Proxy *>
  Order deny,allow
  Allow from all
</Proxy>

ProxyPass / http://localhost:8080/
ProxyPassReverse / http://localhost:8080/
ProxyPreserveHost On
ProxyStatus On
```

* Open `/etc/hosts` and add `127.0.0.1   tapjoy.local` to the end of the file
* To start Apache in OS X, System Preferences -> Sharing -> Check checkbox for 'Web Sharing'

### Using Passenger

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
