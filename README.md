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

Run setup

```
cd tapjoyads
bundle exec rake setup
```


If you get an error, you can try

```
bundle install
```

if it fails on mysql gem, you can try

```
gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
bundle install
```


Setting up VM
-------------

We run the environment inside of a Virtualbox VM setup through Vagrant. You will need Virtualbox for it, but Vagrant currently supports versions 4.0 and 4.1 only. Download it from [virtualbox old builds](https://www.virtualbox.org/wiki/Download_Old_Builds_4_1) and install. 

Now setup librarian and vagrant(run from /Path/To/tapjoyserver/):

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

Create ssh keys on your vagrant instance.

```
ssh-keygen -t rsa -C "user_email@tapjoy.com"
sudo su
cd ~/.ssh 
# if there is no such directory, create it (mkdir ~/.ssh)
ln -s /home/vagrant/.ssh/id_rsa.pub id_rsa.pub
ln -s /home/vagrant/.ssh/id_rsa id_rsa
exit
```

After you've generated these keys and shared them with your root user, add this key to your github account.

Setup the database by syncing the production db with the vm db (this will overwrite any pre-existing changes)

```
cd /vagrant/tapjoyads
bundle
rake db:create
rake db:sync
```

If you get annoyed to have to change into the /vagrant directory every time, just add it to the end of your .bashrc file:
```
cd /vagrant/tapjoyads/
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

Within Vagrant, you can run the application directly from the `/vagrant/tapjoyads` directory by running:

```
rails s thin
```

To access, go to [http://127.0.0.1:8080](http://127.0.0.1:8080).

[Some information on stopping the VM](http://vagrantup.com/v1/docs/getting-started/teardown.html)
