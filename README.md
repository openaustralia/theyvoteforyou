# Public Whip [![Stories in Ready](https://badge.waffle.io/openaustralia/publicwhip.png?label=ready)](https://waffle.io/openaustralia/publicwhip) [![Build Status](https://travis-ci.org/openaustralia/publicwhip.svg?branch=master)](https://travis-ci.org/openaustralia/publicwhip) [![Code Climate](https://codeclimate.com/github/openaustralia/publicwhip.png)](https://codeclimate.com/github/openaustralia/publicwhip) [![Test Coverage](https://codeclimate.com/github/openaustralia/publicwhip/badges/coverage.svg)](https://codeclimate.com/github/openaustralia/publicwhip/coverage)

## Introduction

In our democracy the definitive exercise of the power we give our politicians
when we vote them into office is how they vote in our parliaments on our behalf.
Yet you probably don't know how your MP votes. This isn't your fault.

Parliamentary voting information is notoriously difficult to find and analyse.
This project changes that by making it understandable and easy to use.

We stand on the shoulders of giants: this project is an Australian fork of the
UK [Public Whip](http://www.publicwhip.org.uk/) project.

### Process overview

#### Australia

The [OpenAustralia.org](http://www.openaustralia.org.au) project
[parses](https://github.com/openaustralia/openaustralia-parser) the Australian
Federal Hansard into [ParlParse](http://parser.theyworkforyou.com/) format (this
due to it's history of being a fork of the UK
[TheyWorkForYou](http://www.theyworkforyou.com/) project - more shoulders,
giants). The debates XML files the parser creates, also available on
[data.openaustralia.org](http://data.openaustralia.org.au/), contain voting data
and we load this into a Rails application.

#### Ukraine

People data is collected by a [morph.io scraper](https://morph.io/openaustralia/ukraine_verkhovna_rada_deputies) and fed into [EveryPolitician](http://everypolitician.org/ukraine/). This produces [Popolo formatted](http://www.popoloproject.com/) data that is then loaded into TVFY using a Rake task, e.g.:

    bundle exec rake application:load:ukraine:popolo[https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Ukraine/Verkhovna_Rada/ep-popolo-v1.0.json]

Once the people data has been loaded you can start loading votes. These are scraped by [another morph.io scraper](https://morph.io/openaustralia/ukraine_verkhovna_rada_votes), that saves data in a flat format that can easily be converted to Popolo. The conversion is handled by a [small proxy application](https://github.com/openaustralia/morph_popolo) and the results are imported using another Rake task, e.g.:

    bundle exec rake application:load:ukraine:popolo[https://arcane-mountain-8284.herokuapp.com/vote_events/2015-06-17]

As with other countries you then need to update the caches:

    bundle exec rake application:cache:all_except_member_distances

## Development

If your machine is already set up to develop Rails applications with MySQL just
carry out the following steps and you should be good to go. Developing with
[Vagrant](https://www.vagrantup.com/) is also possible (see below) but was
mainly useful with the retired PHP application.

Before beginning, install MySQL, HTMLTidy and Ruby:

```
# OS X ...
brew install tidy-html5 mysql rbenv ruby-build
rbenv install $(cat .ruby-version)

# ... or Linux (Debian)
sudo apt-get install tidy mysql-server mysql-client libmysqlclient-dev
# then follow: https://github.com/sstephenson/rbenv#basic-github-checkout to get rbenv and ruby-build
```

Steps required to configure, install and start the Rails application:

```
# Copy the default config files over.
# (Edit config/database.yml and fill in your username, password and database settings.)
bundle exec rake application:config:dev
cp config/database.yml.example config/database.yml

# Copy secrets config
cp config/secrets.yml.example config/secrets.yml

# Install bundle
bundle install

# Set up your database (including seed data)
bundle exec rake db:setup

# Run tests
bundle exec rake

# Start the server
bundle exec rails server
```

### Change language to Ukrainian

To change the default language of the project add `default_locale` to your project
settings file, e.g. `config/settings/development.local.yml` for your local
development settings. Use `en` for English and `uk` for Ukrainian:

```
# Name of project to display thoughout the application
project_name: Вони голосують для тебе
# Optionally change default locale, e.g. uk for Ukrainian
default_locale: uk
```

### With Vagrant

Once you have [vagrant][1] and [virtualbox][2] installed and have cloned this
repository run `vagrant up`. This will download the base virtualbox image
and set up the development environment, be prepared for a bit of a wait.

Run the tests from inside the VM like this:

* `vagrant ssh`
* `cd /vagrant`
* `bundle exec rake`

Assuming they pass, you can start the rails server:

* `bundle exec rails server`

Once it is up you can browse to http://localhost:3000

When manually testing the site, the "sign up" confirmation emails will
automatically go to a dummy smtp server called [mailcatcher][3]. To check the
emails, browse to http://localhost:1080

If vagrant reports that it can't mount the `/vagrant` virtualbox shared folder,
it's becuase the VM has had it's kernel updated. Run
`vagrant provision && vagrant reload` and you should be back in business.

The original PHP app is also available at http://localhost:8080 but only if
you're running an older branch (out of scope for this guide).

[1]: http://www.vagrantup.com/
[2]: https://www.virtualbox.org/
[3]: http://mailcatcher.me/

## Loading data

### Australia

These are the tasks you need to know about:

* `application:load:members` loads members, offices and electorates. You always
need this to run the site. Stictly speaking it only needs to run when details
need updating but can be run as often as you like as it only updates data.
* `application:load:divisions[from_date,to_date]` load division[s]. `to_date` is
optional and if omitted, allows you to load a single date.
* `application:cache` this namespace contains cache updating tasks that are
necessary for the site to run. They should be self-explainatory.

Daily updates are carried out by the `application:load:daily` Rake task,
which is run daily at 09:15 by cron.

### Ukraine

The [Popolo](http://www.popoloproject.com/) data for Ukraine is loaded with the `application:load:ukraine:popolo` Rake task. It will load people or vote data, depending on what it finds in the file.

## Better Search

You can enable [elasticsearch](https://www.elasticsearch.org/) for a better search experience.
Enable the setting in `config/settings.yml` then [download](http://www.elasticsearch.org/download)
the `.deb` for Linux or on Mac run `brew install elasticsearch`.

Add data to your index the first time with `bundle exec rake searchkick:reindex:all` and
[Searchkick](https://github.com/ankane/searchkick) should take care of updates from there.

## Production

### Extra Requirements

* Memcached

### Australia

#### Deployment

The code is deployed using Capistrano. To deploy to production run:

    bundle exec cap production deploy

You'll need a local copy of `config/newrelic.yml` that includes your licence
key to be able to record deployments to New Relic.

### Ukraine

#### Server provisioning

Ukraine's server has its configuration management in [another repository](https://github.com/OPORA/publicwhip_server/). Once you've run the server provisioning tasks you can follow the instructions below to deploy the application.

#### Deployment

After provisioning your development server, set up and deploy using [Mina](http://mina-deploy.github.io/mina/):

```
bundle exec mina ukraine-dev setup
bundle exec mina ukraine-dev deploy

# Now you can load people data
bundle exec mina ukraine-dev rake[application:load:ukraine:popolo[https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Ukraine/Verkhovna_Rada/ep-popolo-v1.0.json]]

# And some vote data
bundle exec mina ukraine-dev rake[application:load:ukraine:popolo[https://arcane-mountain-8284.herokuapp.com/vote_events/2015-07-14]]

# Setup caches
bundle exec mina ukraine-dev rake[application:cache:all_except_member_distances]

# Then build the index so search works
bundle exec mina ukraine-dev rake[searchkick:reindex:all]
```

To deploy to the **production** server, replace `ukraine-dev` with `ukraine-production` in the `deploy` command:

    bundle exec mina ukraine-production deploy

## Other Credits

This project uses some icons from the noun project under under creative commons licenses:

* Check icon by useiconic.com from The Noun Project
http://thenounproject.com/term/check/45904/
* Delete icon by useiconic.com from The Noun Project
http://thenounproject.com/term/delete/45301/
* Speech Icon by Lissette Arias from the Noun Project
http://thenounproject.com/term/lecturer/8076/
