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

First configure Git and get the Tapjoy repo.

Setup git following these instructions: http://help.github.com/mac-set-up-git/

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
bundle
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
rails s thin
```

To access, go to [http://127.0.0.1:8080](http://127.0.0.1:8080).

[Some information on stopping the VM](http://vagrantup.com/v1/docs/getting-started/teardown.html)
