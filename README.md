connect repo setup
-----------------------

First, fork this repository to your github account.

Make sure you have your VM set up - if you don't, follow [these instructions](https://github.com/Tapjoy/vagrant) first.

When you are in your VM, go into `/vagrant` directory and clone the repository:

```
cd /vagrant
git clone git@github.com:[your github nickname]/connect.git
```

Install necessary gems under ruby 1.8.7:

```
cd /vagrant/connect/tapjoyads
rvm use 1.8.7-p358
bundle
```

Copy the database config file and run setup script:

```
cp config/database-default.yml config/database.yml
rake setup
```

Setup the database by syncing the production db with the local db:

```
cd /vagrant/connect/tapjoyads
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

Within Vagrant, you can run the application directly from the `/vagrant/connect/tapjoyads` directory by running:

```
rails s thin
```

To access, go to [http://127.0.0.1:8080](http://127.0.0.1:8080).
