# Local Development

The `local_dev` folder contains a [Vagrant virtual machine](https://www.vagrantup.com/docs)
that helps to set up a local development environment.

The vagrant provisioning sets up some parts of the development environment.

- Installs MySql
- Installs rbenv to manage Ruby
- Creates config files for local development


Other steps need to be done manually.

- Installing the required Ruby version
- Installing the Gems
- Running the local development server 


These are the steps to create a local development environment.

Bring up the vagrant VM, then SSH into the vagrant VM.

    $ vagrant up
    $ vagrant ssh

Check that rbenv is installed.

    $ ~/rbenv-doctor.sh

In the vagrant VM, change to the source code directory.
Install the ruby version defined in `.ruby-version`.

    $ cd /opt/source
    $ rbenv install

Install the version of bundler that was used to create `Gemfile.lock`.
Check in the file for `BUNDLED WITH`.
Ensure the rbenv shim for `bundle` is available and up to date.

    $ gem install bundler -v 2.2.3
    $ rbenv rehash

Install the gems.

    $ bundle install
    $ rbenv rehash

Log in to docker to increase the api limit (optional).
Start the docker compose stack.

    $ docker login
    $ docker compose -f /opt/docker-compose/docker-compose.yml up --detach

Set up the database, including seed data.

    $ bundle exec rake db:setup

Run the tests.

    $ bundle exec rake

Create another vagrant VM ssh connection.
Start the 'guard' that provides livereload and allows the local website to run.

    $ vagrant ssh
    $ cd /opt/source
    $ bundle exec guard

Start the development server. View the [website](http://localhost:3000).

    $ bundle exec rails server --binding=0.0.0.0

Browse the [mysql database](http://localhost:8888/?server=mysql&username=root).

The password (`mysql_root_password`) can be found in the [Vagrantfile](Vagrantfile).
 
Load some data.

    $ bundle exec rake application:load:members
    $ bundle exec rake application:load:divisions[2021-07-01,2021-10-31]

Build the cache and elasticsearch index.

    $ bundle exec rake application:cache:all
    $ bundle exec rake searchkick:reindex:all

Browse the [elasticsearch indexes](http://localhost:1358/?appname=*&url=http://localhost:9200&mode=view).
