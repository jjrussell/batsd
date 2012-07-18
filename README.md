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

Environment Setup
=================

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

Setting up VM
-------------

We run the environment inside of a Virtualbox VM setup through Vagrant. To set it up, first
install [virtualbox](http://www.virtualbox.org/wiki/Downloads).

Now setup librarian and vagrant:

```
gem install vagrant
gem install librarian
librarian-chef install
vagrant up
```

SSH into the vm:

```
vagrant ssh
```

Setup the database by syncing the production db with the vm db (this will overwrite any pre-existing changes)

```
cd /vagrant
rvmsudo bundle
rake db:create
rake db:sync
```

Running the tests
-----------------

To make sure everything is set up correctly, run the test suite:

```
rake
```

If any tests fail, ask for help in Flowdock.

Running the server
------------------

Using Unicorn and Foreman, you can run the application directly from the `tapjoyserver/tapjoyads` directory by running:

```
foreman start
```

To access, go to [http://127.0.0.1:8080](http://127.0.0.1:8080).

[Some information on stopping the VM](http://vagrantup.com/v1/docs/getting-started/teardown.html)
