# They Vote For You

[![Build Status](https://github.com/openaustralia/theyvoteforyou/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/openaustralia/theyvoteforyou/actions/workflows/rubyonrails.yml) [![View performance data on Skylight](https://badges.skylight.io/status/WaEcq22vbGmE.svg?token=vUJxZEeaJsAHAZwuG7jUg1kAynbWf1OKnhhXosl9ibc)](https://www.skylight.io/app/applications/WaEcq22vbGmE)

## Introduction

In our democracy the definitive exercise of the power we give our politicians when we vote them into office is how they
vote in our parliaments on our behalf. Yet you probably don't know how your MP votes. This isn't your fault.

Parliamentary voting information is notoriously difficult to find and analyse. This project changes that by making it
understandable and easy to use.

Over 10 years ago the pioneering [Public Whip](http://www.publicwhip.org.uk/) project was created in the UK. This is an
evolution of that original PHP application into a modern Rails application.

### Process overview

#### Australia

The [OpenAustralia.org](https://www.openaustralia.org.au) project
[parses](https://github.com/openaustralia/openaustralia-parser) the Australian Federal Hansard
into [ParlParse](http://parser.theyworkforyou.com/) format (this due to it's history of being a fork of the UK
[TheyWorkForYou](http://www.theyworkforyou.com/) project). The debates XML files the parser creates, also available on
[data.openaustralia.org](http://data.openaustralia.org.au/), contain voting data and we load this into a Rails
application.

#### UK

The UK Public Whip site still operates from the original PHP codebase however it's very possible for it to be upgraded
to Rails in the future. During the development of [They Vote For You](https://theyvoteforyou.org.au/), the OpenAustralia
Foundation was careful to ensure there is an upgrade path.

To upgrade, checkout the `php-compatibility` branch and point the Rails application at a copy of the UK production
database. Test the site out and fix any bugs - there are likely to be some UK-specific additions needed to the Rails
application.

Once the site is working you can then checkout a more recent version of the codebase and run `rake db:migrate` to
upgrade the database schema. This also is likely to need some UK-specific changes.

The final step is to customise the site language and interface. The best way to achieve this would be to develop some
sort of theming system.

#### Ukraine

People data is collected by a [morph.io scraper](https://morph.io/openaustralia/ukraine_verkhovna_rada_deputies) and fed
into [EveryPolitician](http://everypolitician.org/ukraine/). This
produces [Popolo formatted](http://www.popoloproject.com/) data that is then loaded into TVFY using a Rake task, e.g.:

    bundle exec rake application:load:popolo[https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Ukraine/Verkhovna_Rada/ep-popolo-v1.0.json]

Once the people data has been loaded you can start loading votes. These are scraped
by [another morph.io scraper](https://morph.io/openaustralia/ukraine_verkhovna_rada_votes), that saves data in a flat
format that can easily be converted to Popolo. The conversion is handled by
a [small proxy application](https://github.com/openaustralia/morph_popolo) and the results are imported using another
Rake task, e.g.:

    bundle exec rake application:load:popolo[https://arcane-mountain-8284.herokuapp.com/vote_events/2015-07-14]

## Development

Development uses a [dev container](https://containers.dev/) - a Docker-based environment with Ruby, MySQL, Elasticsearch
and Mailpit already wired together with the rails-app container, so there's nothing to install locally beyond Docker and
your favourite IDE. Open the project in VS Code or RubyMine and either will offer to reopen it in the container
automatically. If you prefer vi or other text editor then install make, and use `make setup` to install the devcontainer
CLI directly. See below for various make targets to assist in development.

Everything here is also available via `make [help]`, which prints a one-line description of each target - the fastest
way to check what's available without re-reading this section.

### Host platforms

Your development system needs to be able to run docker compose and devcontainers. We provide `make setup` as a
convenience to set up the following systems we personally use or can test using the `setup-host-test` manual GitHub action:

* Ubuntu 22.04 LTS (Jammy Jellyfish), 24.04 LTS (Noble Numbat) and 26.04 LTS (Resolute Raccoon)
* Debian 12 (bookworm) and 13 (trixie)
* macOS recent enough to run Docker Desktop (usually the current macOS major release plus the two previous releases)

We have made a best-effort to support the following less used distros, and welcome PRs that will add
support for what you personally use and can test for us:

* WSL2 (Windows Subsystem for Linux) running Ubuntu or Debian - using standard Linux not windows packages
* Other Ubuntu/Debian-derived distros (Mint, Pop!_OS, Zorin, elementary, etc.) may work. They get a clear warning

We are not attempting to support native Microsoft Windows outside WSL2, nor releases that are EOL.
Cloud based development platforms are outside the scope of this document,
but we aim to facilitate their use by standardising on the use of devcontainers.

#### Supported Bundler platforms

The following platforms are specified in Gemfile.lock so the lock file shouldn't change when you do a `bundle install`
on a supported platform. To re-establish run the following command. We have removed specific version numbers so updating
your Operating System release shouldn't cause issues.

```bash
bundle lock --add-platform aarch64-linux arm64-darwin x86_64-darwin x86_64-linux
```
Note: We don't add the generic ruby platform: several native extension gems here (eg ffi, nokogiri, libv8-node) only
ship precompiled binaries for the platforms above, and ruby makes Bundler try to compile them from source instead.

| Platform | Covers |
|---|---|
| `aarch64-linux` | Devcontainer/Docker on an Apple Silicon Mac (the container runs `linux/arm64` regardless of host OS), plus native ARM Linux (Ubuntu/Debian on ARM) and WSL2 on Windows-on-ARM |
| `x86_64-linux` | Devcontainer/Docker on an Intel Mac or x86_64 host, native x86_64 Ubuntu/Debian, and standard WSL2 |
| `arm64-darwin` | Non-container fallback, running `bundle install` directly on an Apple Silicon Mac |
| `x86_64-darwin` | Non-container fallback, running `bundle install` directly on an Intel Mac |


### Getting started

```
make setup     # Install Docker, Compose, and the devcontainer CLI
make dev-up    # Build and start the dev container - leave this running
```

In another terminal:

```
make dev-exec # bash shell running in the rails-app container
make dev-exec COMMAND="bin/setup --skip-server" # already run via postCreateCommand; safe to rerun any time
make dev-server # runs the rails web server (bound to address 0.0.0.0 as needed for port forwarding)
```

### Everyday commands

* `make dev-status` - container status, resource usage, and clickable service URLs
* `make dev-console` - `bin/rails console` inside the container
* `make dev-dbconsole` - `bin/rails dbconsole` inside the container
* `make dev-rake ARGS="db:test:prepare"` - run a rake task inside the container
* `make dev-exec COMMAND="..."` - run any other command inside the container (default: `bash`)

When you are finished, run:
* `make dev-down` - stops containers, but retains data, or
* `make dev-clobber` - full reset: removes containers, images and volumes


### Setting up development data

First run only - loads MPs, divisions, and builds the search index:

```
make dev-exec COMMAND="bin/rake application:load:members"
make dev-exec COMMAND="bin/rake application:load:divisions[2021-07-01,2021-10-31]"
make dev-exec COMMAND="bin/rake application:cache:all"
make dev-exec COMMAND="bin/rake searchkick:reindex:all"
```

### Once it's running

* The app itself: http://localhost:3088 - needs the Rails server actually running and bound to `0.0.0.0` (see
  "Getting started" above)
* Elasticsearch: http://localhost:9288/ gives basic version/cluster info as a quick "is it alive" check. Two other
  useful ones:
  * http://localhost:9288/_cluster/health gives cluster status - should be `"status":"green"` (indices are configured
    with no replicas in development/test, so a single dev/test node has nothing left unassigned)
  * http://localhost:9288/_cat/indices?v lists indices with document counts - useful for confirming a reindex worked
  * See `Rails.application.credentials.elasticsearch.url` on production for its base url
* Mailpit: http://localhost:8088/ - any email the app sends in development lands here instead of a real inbox
* MySQL: connect a client (e.g. MySQL Workbench) to `localhost:3388`, user `root`, password `password`

## Using just the other services

If you want to run rails locally, but use the mysql, elasticsearch and mailpit services, then run:

```bash
make dev-up
```

Then add these to your `.envrc` file (used by `direnv` to set environment):

```
export MAILPIT_HOST=127.0.0.1
export MAILPIT_PORT=1088
export DB_HOST=127.0.0.1
export DB_PORT=3388
export MYSQL_USER=root
export MYSQL_PASSWORD=password
export ELASTICSEARCH_URL=http://localhost:9288
```

Known issue with RubyMine: mise works via the devcontainer CLI but not when RubyMine connects to the `rails-app`
container directly, see #1667.

## Loading data

### Australia

These rake tasks are the ones you're most likely to need to run. You can run them as the `deploy` user in
`/srv/www/production/current`, for instance:

```
deploy@ip-172-31-37-36:/srv/www/production/current$ RAILS_ENV=production bundle exec rake application:load:divisions[2018-10-18]
```

* `application:load:members` loads members, offices and electorates. You always need this to run the site. Strictly
  speaking it only needs to run when details need updating but can be run as often as you like as it only updates data.
* `application:load:divisions[from_date,to_date]` load division[s]. `to_date` is optional and if omitted, allows you to
  load a single date.
* `application:cache` this namespace contains cache updating tasks that are necessary for the site to run. They should
  be self-explanatory.

Daily updates are carried out by the `application:load:daily` Rake task, which is run daily at 09:15 by cron.

### Popolo

Countries that use [Popolo](http://www.popoloproject.com/), e.g. Ukraine, only need to know about the
`application:load:popolo` Rake task. It will load people or country data, depending on what it finds in the file.

## Search

Search requires [elasticsearch](https://www.elasticsearch.org/); the devcontainer (or the hybrid setup above) already
provides it, so you only need to install it separately if you're running fully on the host without either. Homebrew
no longer carries elasticsearch (removed after Elastic's licence change); see the
[download page](http://www.elasticsearch.org/download) for the Linux `.deb` and other options instead.

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

Ukraine's server has its configuration management in [another repository](https://github.com/OPORA/publicwhip_server/).
Once you've run the server provisioning tasks you can follow the instructions below to deploy the application.

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

The administration panel, which currently doesn't do a whole lot, can be accessed in development
at http://localhost:3088/admin/ and in production at https://theyvoteforyou.org.au/admin. You must be an admin to be
able to access that page. Any user that is an admin can make another user and admin too using the admin panel. The first
admin user must be created via the rails console:

```
deploy@hostname:/srv/www/production/current$ RAILS_ENV=production bundle exec rails c
Loading production environment (Rails 8.0.2)
3.4.4 :001 >  User.find_by(email: "matthew@oaf.org.au")
 => #<User id: 13792, created_at: "2021-05-03 10:26:02.000000000 +1000", updated_at: "2025-05-09 10:21:17.000000000 +1000", api_key: "NNabCaw2gQ/Wla4mVeR8", admin: true, staff: true, name: "matthew", email: "matthew@oaf.org.au">
3.4.4 :002 >$ bundle exec rails c
irb> User.find_by(email: "matthew@oaf.org.au").update(admin: true)
```

Obviously substitute the email address in the command above.

## Feature flags

Some features that are still in development are enabled via "feature flags". The features can optionally switched on for
certain users, block of users or everyone. These flags are administered
at https://theyvoteforyou.org.au/admin/flipper/features in production or http://localhost:3088/admin/flipper/features
when in development.

The names of the features added in the admin panel need to match those in the code at `config/initializers/flipper.rb`.

To enable a feature for a particular user: Go to the feature on the flipper admin panel. Then click the button "Add an
actor". Then add the `flipper_id` which for a user will be of the form `User;<user id>`. So for example it could be
`User;3`.

## To run style and coding checks

    bundle exec rubocop

## To check for security updates

Either check [Dependabot alerts](https://github.com/openaustralia/theyvoteforyou/security/dependabot)
for the main branch, taking note of when the last check was run, **or** run manually on current branch:

    bundle exec ruby-audit
    bundle exec bundle-audit

## Other Credits

This project uses some icons from the noun project under creative commons licenses:

* Check icon by useiconic.com from The Noun Project
  http://thenounproject.com/term/check/45904/
* Delete icon by useiconic.com from The Noun Project
  http://thenounproject.com/term/delete/45301/
* Speech Icon by Lissette Arias from the Noun Project
  http://thenounproject.com/term/lecturer/8076/
* User Icon by Universal Icons from the Noun Project
  https://thenounproject.com/icon/user-3692903/
