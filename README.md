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

Environment Setup for OSX 10.7 Lion
===================================

Install Xcode
-------------
Even though we typically don't use Xcode, you'll need it for GCC and Homebrew to work properly.

Download via app store: http://itunes.apple.com/us/app/xcode/id497799835?mt=12

Run Xcode to finish installation

Go to preferences:

![xcode preferences](http://f.cl.ly/items/0g3A2S173P0Z3A1C1w09/Screen%20Shot%202012-04-18%20at%203.12.30%20PM.png)

Install the `Command Line Tools`:

![command line tools](http://f.cl.ly/items/2v0d2d3R09341x171206/Screen%20Shot%202012-04-18%20at%203.14.17%20PM.png)

Verify gcc and git are installed in a terminal window:

```
gcc -v
git --version
```

Install homebrew
----------------
Homebrew is a package manager for OSX.

Install via:

```
/usr/bin/ruby -e "$(/usr/bin/curl -fksSL https://raw.github.com/mxcl/homebrew/master/Library/Contributions/install_homebrew.rb)"
```

Now run the brew doctor to set up where it'll put packages:

```
brew doctor
```

You'll probably see a message asking you to fix your paths, follow the instructions, then re-run:

```
sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
brew doctor
brew update # to get the latest brews
```


Configure Git and get Tapjoy repo
-------------------------------

Setup git following these instructions: http://help.github.com/mac-set-up-git/

NOTE: You already have git installed from the Xcode step.

In github, fork tapjoyserver repository:

  * main repo location: `https://github.com/Tapjoy/tapjoyserver`
  * click "Fork"

Clone your forked repo locally


```
git clone git@github.com:[your github nickname]/tapjoyserver.git
```

Add main tapjoyserver repo as remote repo (for updating your code with the latest):

```
git remote add tapjoy git@github.com:Tapjoy/tapjoyserver.git
```

It is important that it's named "tapjoy" for deploy script to work

Install RVM
-----------

RVM is important so we don't mess with the system's ruby, and can use the most recent version of Ruby 1.8.7.

Install RVM:

```
bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)
```

Load RVM into bash:

```
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function' >> ~/.bash_profile
source ~/.bash_profile # to reload ~/.bash_profile
rvm get head # to update rvm
```

Install Ruby 1.8.7
------------------

First install the osx-gcc-installer:

```
https://github.com/kennethreitz/osx-gcc-installer/downloads
```

Install the current version of 1.8.7 as the default:

```
rvm install 1.8.7
rvm use 1.8.7 --default
```

Install MySQL
-------------

Install MySQL:

```
brew install mysql
```

Follow the post-install directions. (Type `brew info mysql` to see them again)

Install memcached
-----------------

Install memcached:

```
brew install memcached
```

Follow the post-install directions. (Type `brew info mysql` to see them again)


Copy local config files
-----------------------

```
cd tapjoyserver/tapjoyads
cp config/newrelic-test.yml config/newrelic.yml
cp config/database-default.yml config/database.yml
cp config/local-default.yml config/local.yml
```

Download GeoIP database
-----------------------

Download GeoIP database, unzip it and move it to the 

```
curl http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz | gunzip > data/GeoIPCity.dat
```

Install required gems
---------------------

```
brew install imagemagick # required for rmagick gem
bundle install
```

Set up accounts and database
----------------------------

Create developer account at `dashboard.tapjoy.com` and have someone give you the "admin" role

Sync prod db with local db (this will overwrite any pre-existing changes)

```
mkdir tmp
rake db:create
rake admin:sync_db
```

Running the tests
-----------------

To make sure everything is set up correctly, run the test suite:

```
rake
```

If any tests fail, ask for help in Campfire.

Running locally
---------------

Using Unicorn and Foreman, you can run the application directly from the `tapjoyserver/tapjoyads` directory by running:

```
foreman start
```

If you need to restart the application, simply `ctrl+c` and then re-run the command.

To access directly, go to [http://127.0.0.1:8080]().


Optional steps
==============

Set git pre-commit hook to run
------------------------------

The pre-commit hook runs before any git commit. It automatically strips trailing whitespace and adds newlines to the end of files, which is compliant with our style guide.

```
ln -s tapjoyserver/.pre-commit tapjoyserver/.git/hooks/
```

.rvmrc file
-----------

If you would like to run projects with different gemsets or rubies, it can be helpful to have a .rvmrc file in the project. This will make it so whenever the folder is opened, the correct ruby + gemset will be used.

Here is an example .rvmrc that uses `ruby-1.8.7p357` and a `tapjoyserver` gemset:

```
rvm ruby-1.8.7-p357@tapjoyserver
```
