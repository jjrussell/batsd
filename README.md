tapjoyserver repo setup
-----------------------

First configure Git and get the Tapjoy repo.

In github, fork this repository.

If you're on the vm, go into `/vagrant` and clone the repository:

```
cd /vagrant
git clone git@github.com:[your github nickname]/tapjoyserver.git
```

Install necessary gems under ruby 1.8.7 and run the repo setup script:

```
cd /vagrant/tapjoyserver/tapjoyads
rvm use 1.8.7-p357
bundle
rake setup
```

Setup the database by syncing the production db with the local db:

```
cd /vagrant/tapjoyserver/tapjoyads
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

Within Vagrant, you can run the application directly from the `/vagrant/tapjoyserver/tapjoyads` directory by running:

```
rails s thin
```

To access, go to [http://127.0.0.1:8080](http://127.0.0.1:8080).
