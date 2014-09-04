$ruby_version = 'ruby-2.0.0-p353'

# WARNING: obviously don't use these passwords in production.
$db_root_password = "abc123"
$db_dev = "publicwhip_dev"
$db_dev_password = "abc123"
$db_test = "publicwhip_test"
$db_test_password = "abc123"

# General packages

include apt

package { 'libtext-autoformat-perl':
  ensure => 'latest'
}

package { 'libunicode-string-perl':
  ensure => 'latest'
}

package { 'libxml-twig-perl':
  ensure => 'latest'
}

package { 'wget':
  ensure => 'latest',
}

package { 'libmysqlclient-dev':
    ensure  => 'latest',
}

package { 'php5-mysql':
    ensure  => 'latest',
}

package { 'php5-cli':
    ensure  => 'latest',
}

package { 'tidy':
    ensure  => 'latest',
}

package { 'git-core':
    ensure => 'latest';
}

# Timezone for server must be sydney for now because php app relies on it.
class { 'timezone':
    timezone => 'Australia/Sydney',
}

# Ruby

include rvm

rvm_system_ruby {"$ruby_version":
    ensure => 'present',
    default_use => true;
}

rvm::system_user { 'vagrant': }

rvm_gem { "$ruby_version/bundler":
    ensure  => 'present',
    require => Rvm_system_ruby["$ruby_version"];
}

rvm_gem {"$ruby_version/rake":
    ensure  => 'present',
    require => Rvm_system_ruby["$ruby_version"];
}

exec { 'bundle install':
    require => [
                    Rvm_gem["$ruby_version/bundler"],
                    Rvm_gem["$ruby_version/rake"],
                    Package['libmysqlclient-dev'],
                    Package['git-core'],
                    Class['::mysql::server'],
               ],
    user => 'vagrant',
    cwd => '/vagrant',
    path => ['/usr/local/rvm/wrappers/default', '/usr/bin', '/usr/sbin/', '/bin/'],
    timeout => 1200
}

# mailcatcher
rvm_gemset {"$ruby_version@mailcatcher":
    ensure  => present,
    require => Rvm_system_ruby["$ruby_version"];
}

rvm_gem {"$ruby_version@mailcatcher/mailcatcher":
    ensure  => 'present',
    require => Rvm_gemset["$ruby_version@mailcatcher"];
}

rvm_wrapper {'mailcatcher':
    target_ruby => "$ruby_version@mailcatcher",
    ensure => present,
    require => Rvm_gem["$ruby_version@mailcatcher/mailcatcher"];
}

file { '/etc/init.d/mailcatcher':
    require => [ Rvm_wrapper['mailcatcher'] ],
    source => '/vagrant/manifests/mailcatcher'
}

exec {'update-rc.d mailcatcher defaults':
    subscribe => File['/etc/init.d/mailcatcher'],
    path => ['/usr/bin', '/usr/sbin/', '/bin/']
}

exec {'service mailcatcher start':
    subscribe => Exec['update-rc.d mailcatcher defaults'],
    path => ['/usr/bin', '/usr/sbin/', '/bin/']
}

# Databases

class { '::mysql::server':
    root_password => "$::db_root_password",
    restart => true,
    override_options => {
        'mysqld' => { 'default-storage-engine' => 'innodb' }
    }
}

include '::mysql::server'

mysql::db { "$db_dev":
    ensure => 'present',
    user => "$db_dev",
    password => "$db_dev_password",
    host => 'localhost',
    collate => 'utf8_unicode_ci',
    grant => ['ALL']
}

mysql::db { "$db_test":
    ensure => 'present',
    user => "$db_test",
    password => "$db_test_password",
    host => 'localhost',
    collate => 'utf8_unicode_ci',
    grant => ['ALL']
}

# Original PHP code configuration

file { '/vagrant/php/loader/PublicWhip/Config.pm':
    ensure => 'present',
    content => "package PublicWhip::Config;
use vars qw(\$user \$pass \$pwdata \$debatepath \$fileprefix);

\$user   = \"$db_dev\";
\$pass   = \"$db_dev_password\";
\$dbspec = \"DBI:mysql:$db_dev\";

# this is where the XML files come from:
\$pwdata = \"/vagrant/php/loader/data.openaustralia.org/\";
\$debatepath = \$pwdata . \"scrapedxml/representatives_debates/\";
\$fileprefix = \"\";
\$lordsdebatepath = \$pwdata . \"scrapedxml/senate_debates/\";
\$lordsfileprefix = \"\";
\$scotlanddebatepath = \$pwdata . \"scrapedxml/sp/\";
\$scotlandmotionspath = \$pwdata . \"scrapedxml/sp-motions/\";
\$scotlandfileprefix = \"sp\";
\$members_location = \$pwdata . \"members/\";

1;
"
}

## The database is created by Rails now
# exec { "mysql --database=$db_dev -u $db_dev --password=$db_dev_password < /vagrant/php/loader/create.sql":
#     refreshonly => true,
#     subscribe => Mysql::Db["$db_dev"],
#     path => ['/usr/bin', '/usr/sbin/', '/bin/']
# }

class { 'apache':
    mpm_module => 'prefork',
    default_mods => ['php']
}

apache::vhost { 'publicwhip-php.openaustraliafoundation.org.au':
    default_vhost => true,
    port    => '80',
    docroot => '/vagrant/php/website',
    directories => [
      { path => '^(mp-info.xml|dreamquery.xml|mpdream-info.xml)$',
        provider => 'filesmatch',
        addhandlers => [{ handler => 'application/x-httpd-php', extensions => ['.xml']}]
      }
    ]
}

file { '/etc/php5/apache2/php.ini':
    require => [
                    Apache::Vhost['publicwhip-php.openaustraliafoundation.org.au'],
                    Package['php5-mysql']
               ],
    source => '/vagrant/manifests/apache2php.ini'
}

file { '/vagrant/php/website/config.php':
    ensure => 'present',
    content => "<?php
# Server domain
\$domain_name = \"publicwhip-php.openaustraliafoundation.org.au\";

# Public Whip database params, change these
\$pw_host = \"localhost\";
\$pw_user = \"$db_dev\";
\$pw_password = \"$db_dev_password\";
\$pw_database = \"$db_dev\";

# Cache HTML files for speed up rendering
\$pw_cache_enable = false;
\$pw_cache_top = \"/blah/pwcache\";

# Authentication value - only needed for publicwhip.org.uk itself
\$hidden_hash_var='';

define('HIDDEN_HASH_VAR', \$hidden_hash_var);

?>"
}

# Set the PHP_SERVER environment variable that the rspec tests use when testing against PHP
file { '/etc/profile.d/publichwhip_rails_tests.sh':
    ensure => 'present',
    content => 'export PHP_SERVER=localhost',
    mode => 755
}

## Disable data loading since Rails has database seeds for us
# # Downloads a small sample of debate data from data.openaustralia.org and uses
# # it to populate the database.
# exec { '/vagrant/php/loader/load_openaustralia_xml.sh':
#     refreshonly => true,
#     subscribe => Exec["mysql --database=$db_dev -u $db_dev --password=$db_dev_password < /vagrant/php/loader/create.sql"],
#     require => [
#                     File['/vagrant/php/loader/PublicWhip/Config.pm'],
#                     Package['libtext-autoformat-perl'],
#                     Package['libunicode-string-perl'],
#                     Package['libxml-twig-perl'],
#                     Package['php5-cli']
#                ],
#     cwd => '/vagrant/php/loader',
#     timeout => 1200,
#     path => ['/usr/bin', '/usr/sbin/', '/bin/']
# }

# # Copy the dev database to the test database
# exec { "mysqldump -u $db_dev --password=$db_dev_password $db_dev | mysql -u $db_test --password=$db_test_password --database=$db_test":
#     refreshonly => true,
#     subscribe => Exec['/vagrant/php/loader/load_openaustralia_xml.sh'],
#     require => Mysql::Db["$db_test"],
#     path => ['/usr/bin', '/usr/sbin/', '/bin/']
# }

# Rails configuration

file { '/vagrant/config/database.yml':
    ensure => 'present',
    content => "
development:
  adapter: mysql2
  database: $db_dev
  username: $db_dev
  password: $db_dev_password

# Warning: The database defined as 'test' will be erased and
# re-generated from your development database when you run 'rake'.
# Do not set this db to the same as development or production.
test:
  adapter: mysql2
  database: $db_test
  username: $db_test
  password: $db_test_password
"
}

file { '/vagrant/config/secrets.yml':
    ensure => 'present',
    content => "development:
  secret_key_base: bbe2a5f54b941a3bbf00b1d88615a7b2be7f3947aa76d423ebcb55c67f9c88b0b40d450aa34bf31abe3958a825db2d4a396f33ad12d2156811bdff9e73c9b169

test:
  secret_key_base: a34be84480b617fd7878f8d808f6ce66751b081ac394de8e47f64d6dda0d8e316af34b3e619465af628b8d286e9e868ddfc3c4d200d997ee485ff78726f865fc

production:
  secret_key_base: 16eba5b7795160905f7781790f6eaff0d715d21904284eeb81747917a44a52314b9896fa4876ca5159c29b734c70c30bdadc78683f4d8e8b2dea45e47040a15b
"

#WARNING: obviously don't use the above keys in production, generate your own using 'bundle exec rake secret'.
}

# Set up development database
exec { 'bundle exec rake db:setup':
    require => [
                  Exec['bundle install'],
                  Mysql::Db["$db_dev"],
               ],
    user => 'vagrant',
    cwd => '/vagrant/',
    path => ['/usr/local/rvm/wrappers/default', '/usr/bin', '/usr/sbin/', '/bin/'],
    environment => ['HOME=/home/vagrant'] # Fixme: it is very, very weird that
                                          # it fails without this. Investigate.
}

# Migrate test database
exec { 'bundle exec rake db:migrate RAILS_ENV=test':
    require => [
                  Exec['bundle install'],
                  Mysql::Db["$db_test"],
               ],
    user => 'vagrant',
    cwd => '/vagrant/',
    path => ['/usr/local/rvm/wrappers/default', '/usr/bin', '/usr/sbin/', '/bin/']
}
