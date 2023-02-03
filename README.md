# They Vote For You [![Build Status](https://travis-ci.com/openaustralia/publicwhip.svg?branch=master)](https://travis-ci.com/openaustralia/publicwhip) [![Code Climate](https://codeclimate.com/github/openaustralia/publicwhip.png)](https://codeclimate.com/github/openaustralia/publicwhip) [![Test Coverage](https://codeclimate.com/github/openaustralia/publicwhip/badges/coverage.svg)](https://codeclimate.com/github/openaustralia/publicwhip/coverage)

## Introduction

In our democracy the definitive exercise of the power we give our politicians
when we vote them into office is how they vote in our parliaments on our behalf.
Yet you probably don't know how your MP votes. This isn't your fault.

Parliamentary voting information is notoriously difficult to find and analyse.
This project changes that by making it understandable and easy to use.

Over 10 years ago the pioneering [Public Whip](http://www.publicwhip.org.uk/) project was created in the UK. This is an evolution of that original PHP application into a modern Rails application.

### Process overview

#### Australia

The [OpenAustralia.org](https://www.openaustralia.org.au) project
[parses](https://github.com/openaustralia/openaustralia-parser) the Australian
Federal Hansard into [ParlParse](http://parser.theyworkforyou.com/) format (this
due to it's history of being a fork of the UK
[TheyWorkForYou](http://www.theyworkforyou.com/) project). The debates XML files the parser creates, also available on
[data.openaustralia.org](http://data.openaustralia.org.au/), contain voting data
and we load this into a Rails application.

#### UK

The UK Public Whip site still operates from the original PHP codebase however it's very possible for it to be upgraded to Rails in the future. During the development of [They Vote For You](https://theyvoteforyou.org.au/), the OpenAustralia Foundation was careful to ensure there is an upgrade path.

To upgrade, checkout the `php-compatibility` branch and point the Rails application at a copy of the UK production database. Test the site out and fix any bugs - there are likely to be some UK-specific additions needed to the Rails application.

Once the site is working you can then checkout a more recent version of the codebase and run `rake db:migrate` to upgrade the database schema. This also is likely to need some UK-specific changes.

The final step is to customise the site language and interface. The best way to achieve this would be to develop some sort of theming system.

#### Ukraine

People data is collected by a [morph.io scraper](https://morph.io/openaustralia/ukraine_verkhovna_rada_deputies) and fed into [EveryPolitician](http://everypolitician.org/ukraine/). This produces [Popolo formatted](http://www.popoloproject.com/) data that is then loaded into TVFY using a Rake task, e.g.:

    bundle exec rake application:load:popolo[https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Ukraine/Verkhovna_Rada/ep-popolo-v1.0.json]

Once the people data has been loaded you can start loading votes. These are scraped by [another morph.io scraper](https://morph.io/openaustralia/ukraine_verkhovna_rada_votes), that saves data in a flat format that can easily be converted to Popolo. The conversion is handled by a [small proxy application](https://github.com/openaustralia/morph_popolo) and the results are imported using another Rake task, e.g.:

    bundle exec rake application:load:popolo[https://arcane-mountain-8284.herokuapp.com/vote_events/2015-07-14]

## Development

If your machine is already set up to develop Rails applications with MySQL just
carry out the following steps and you should be good to go.

Developing with [Vagrant](https://www.vagrantup.com/) is also possible (see below) but was
mainly useful with the retired PHP application. A new Vagrant setup can be found in the
[OpenAustralia/Infrastructure](https://github.com/openaustralia/infrastructure#provisioning-local-development-servers-using-vagrant)
repository, however this is primarily intended as a "production-like" test environment
rather than providing a development environment.

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
# Install bundle
bundle install

# Install mailcatcher
gem install mailcatcher

# Copy the default config files over.
cp config/database.yml.example config/database.yml

# (Edit config/database.yml and fill in your username, password and database settings.)
bundle exec rake application:config:dev

# Copy secrets config
cp config/secrets.yml.example config/secrets.yml

# Set up your database (including seed data)
bundle exec rake db:setup

# Run tests
bundle exec rake

# Start the server
bundle exec rails server
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

These rake tasks are the ones you're most likely to need to run. You
can run them as the `deploy` user in `/srv/www/production/current`, for instance:

```
deploy@ip-172-31-37-36:/srv/www/production/current$ RAILS_ENV=production bundle exec rake application:load:divisions[2018-10-18]
```

* `application:load:members` loads members, offices and electorates. You always
need this to run the site. Strictly speaking it only needs to run when details
need updating but can be run as often as you like as it only updates data.
* `application:load:divisions[from_date,to_date]` load division[s]. `to_date` is
optional and if omitted, allows you to load a single date.
* `application:cache` this namespace contains cache updating tasks that are
necessary for the site to run. They should be self-explanatory.

Daily updates are carried out by the `application:load:daily` Rake task,
which is run daily at 09:15 by cron.

### Popolo

Countries that use [Popolo](http://www.popoloproject.com/), e.g. Ukraine, only need to know about the `application:load:popolo` Rake task. It will load people or country data, depending on what it finds in the file.

## Search

Search requires [elasticsearch](https://www.elasticsearch.org/). You will need to [download](http://www.elasticsearch.org/download)
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

### Ukraine

#### Server provisioning

Ukraine's server has its configuration management in [another repository](https://github.com/OPORA/publicwhip_server/). Once you've run the server provisioning tasks you can follow the instructions below to deploy the application.

#### Deployment

After provisioning your development server, set up and deploy using [Mina](http://mina-deploy.github.io/mina/):

```
bundle exec mina ukraine_dev setup
bundle exec mina ukraine_dev deploy

# Now you can load people data
bundle exec mina ukraine_dev rake[application:load:popolo[https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Ukraine/Verkhovna_Rada/ep-popolo-v1.0.json]]

# And some vote data
bundle exec mina ukraine_dev rake[application:load:popolo[https://arcane-mountain-8284.herokuapp.com/vote_events/2015-07-14]]

# Setup caches
bundle exec mina ukraine_dev rake[application:cache:all_except_people_distances]

# Then build the index so search works
bundle exec mina ukraine_dev rake[searchkick:reindex:all]
```

To deploy to the **production** server, replace `ukraine_dev` with `ukraine_production` in the above commands.

## Accessing the admin panel

The administration panel, which currently doesn't do a whole lot, can be accessed in development at http://localhost:3000/admin/ and in production at https://theyvoteforyou.org.au/admin. You must be an admin to be able to access that page. Any user that is an admin can make another user and admin too using the admin panel. The first admin user must be created via the rails console:
```
$ bundle exec rails c
irb> User.find_by(email: "matthew@oaf.org.au").update(admin: true)
```

Obviously substitute the email address in the command above.

## Feature flags

Some features that are still in development are enabled via "feature flags". The features can optionally switched on for certain users, block of users or everyone. These flags are administered at https://theyvoteforyou.org.au/admin/flipper/features in production or http://localhost:3000/admin/flipper/features when in development.

The names of the features added in the admin panel need to match those in the code at `config/initializers/flipper.rb`.

To enable a feature for a particular user: Go to the feature on the flipper admin panel. Then click the button "Add an actor". Then add the `flipper_id` which for a user will be of the form `User;<user id>`. So for example it could be `User;3`.

## Other Credits

This project uses some icons from the noun project under under creative commons licenses:

* Check icon by useiconic.com from The Noun Project
http://thenounproject.com/term/check/45904/
* Delete icon by useiconic.com from The Noun Project
http://thenounproject.com/term/delete/45301/
* Speech Icon by Lissette Arias from the Noun Project
http://thenounproject.com/term/lecturer/8076/
* User Icon by Universal Icons from the Noun Project
https://thenounproject.com/icon/user-3692903/