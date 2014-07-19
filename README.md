# Public Whip [![Stories in Ready](https://badge.waffle.io/openaustralia/publicwhip.png?label=ready)](https://waffle.io/openaustralia/publicwhip) [![Code Climate](https://codeclimate.com/github/openaustralia/publicwhip.png)](https://codeclimate.com/github/openaustralia/publicwhip)

This is an Australian fork of the UK website [Public Whip](http://www.publicwhip.org.uk/).

We're currently porting the codebase to Rails - see the `rails` directory.
During development both the original PHP code and the Rails port need to be run
side by side to in order to compare them.

The easiest way to get a development environment set up is to use [vagrant][1]
and [virtualbox][2] to bring up a virtual machine. Once you've got them
installed and have the publicwhip source code, `cd` into the source code
directory and run `vagrant up`. This will download the base virtualbox image
and set up the development environment, be prepared for a bit of a wait.

Once that's done, you'll find the original PHP app available at localhost:8080
(vagrant will automatically forward the port from the VM to the host). Run the
rspec tests from inside the VM like this:

* `vagrant ssh`
* `cd /vagrant/rails`
* `bundle exec rake PHP_SERVER=localhost`

Assuming they pass, you can start the rails web server and background job
processing:

* `./server.sh`

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

The Public Whip Source Code (UK README)
---------------------------------------

Hello!  Here's the source code behind the Public Whip website.  To see the end
product go to http://www.publicwhip.org.uk.  If you don't know what this is all
about, have a look at the FAQ there.

To learn how to use the code look at http://www.publicwhip.org.uk/project/code.php
or locally in `webpage/project/code.php`.  You should also check out the
Parliament Parse project at http://ukparse.kforge.net/parlparse, which is the
scraper that made the data Public Whip uses.

A description of the files and folders in this package follows.

* LICENSE.html - Details of open source licensing terms, under the Affero GNU GPL
* loader    - Load XML files from ukparse into the database
* website   - Code for www.publicwhip.org.uk, PHP extracts data from database/XML
* build     - Scripts I use for admin, such as to upload to www.publicwhip.org.uk
* custom    - Various one off scripts and graphics made for special purposes
* artwork   - High resolution graphics relating to Public Whip

If you need any help, please email team@publicwhip.org.uk.
