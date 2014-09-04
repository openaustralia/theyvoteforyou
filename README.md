# Public Whip [![Stories in Ready](https://badge.waffle.io/openaustralia/publicwhip.png?label=ready)](https://waffle.io/openaustralia/publicwhip) [![Build Status](https://travis-ci.org/openaustralia/publicwhip.svg?branch=test)](https://travis-ci.org/openaustralia/publicwhip) [![Code Climate](https://codeclimate.com/github/openaustralia/publicwhip.png)](https://codeclimate.com/github/openaustralia/publicwhip)

## Introduction

In our democracy the definitive exercise of the power we give our politicians
when we vote them into office is how they vote in our parliaments on our behalf.
Yet you probably don't how your MP votes. This isn't your fault.

Parliamentary voting information is notoriously difficult to find and analyse.
This project changes that by making it understandable and easy to use.

We stand on the shoulders of giants: this project is an Australian fork of the
UK [Public Whip](http://www.publicwhip.org.uk/) project.

### [This is how we do it](https://www.youtube.com/watch?v=0hiUuL5uTKc) - process overview

The [OpenAustralia.org](http://www.openaustralia.org) project
[parses](https://github.com/openaustralia/openaustralia-parser) the Australian
Federal Hansard into [ParlParse](http://parser.theyworkforyou.com/) format (this
due to it's history of being a fork of the UK
[TheyWorkForYou](http://www.theyworkforyou.com/) project - more shoulders,
giants). The debates XML files the parser creates, also available on
[data.openaustralia.org](http://data.openaustralia.org/), contain voting data
and we load this into a Rails application.

## Development

### Vagrant

The easiest way to get a development environment set up is to use [vagrant][1]
and [virtualbox][2] to bring up a virtual machine. Once you've got them
installed and have the publicwhip source code, `cd` into the source code
directory and run `vagrant up`. This will download the base virtualbox image
and set up the development environment, be prepared for a bit of a wait.

Once that's done, you'll find the original PHP app available at localhost:8080
(vagrant will automatically forward the port from the VM to the host). Run the
rspec tests from inside the VM like this:

* `vagrant ssh`
* `cd /vagrant`
* `bundle exec rake PHP_SERVER=localhost`

Assuming they pass, you can start the rails server:

* `bundle exec rails server`

Once it is up you can browse to localhost:3000 on the host.

When manually testing the site, the "sign up" confirmation emails will
automatically go to a dummy smtp server called [mailcatcher][3]. To check the
emails, browse to localhost:1080 on the host.

If vagrant reports that it can't mount the `/vagrant` virtualbox shared folder,
it's becuase the VM has had it's kernel updated. Run
`vagrant provision && vagrant reload` and you should be back in business.

[1]: http://www.vagrantup.com/
[2]: https://www.virtualbox.org/
[3]: http://mailcatcher.me/

### Without Vagrant

If you're not using Vagrant you'll need Ruby and MySQL set up and then this to
set up the Rails application:

```
# Copy database config and fill in your username, password and database settings
cp config/database.yml.example config/database.yml

# Copy secrets config
cp config/secrets.yml.example config/secrets.yml

# Generate a secret_key_base (copy this to config/secrets.yml)
bundle exec rake secret

# Copy settings config
cp config/settings.yml.example config/settings.yml

# Install bundle
bundle install

# Set up your database (including seed data)
bundle exec rake db:setup

# Run tests
bundle exec rake

# Start the server
bundle exec rails server
```
