include apt

# Packages

package { 'apache2':
  ensure => 'latest',
}
 
package { 'libapache2-mod-php5':
  ensure => 'latest'
}

package { 'libtext-autoformat-perl':
  ensure => 'latest'
}

package { 'libunicode-string-perl':
  ensure => 'latest'
}

package { 'libxml-twig-perl':
  ensure => 'latest'
}

package { 'ruby-bundler':
  ensure => 'latest'
}

package { 'libmysqlclient-dev':
    ensure  => 'latest',
}

package { 'rake':
  ensure => 'latest',
}

package { 'wget':
  ensure => 'latest',
}

# Databases

$db_root_password = "abc123"
$db_dev = "publicwhip_dev"
$db_dev_password = "abc123"
$db_test = "publicwhip_test"
$db_test_password = "abc123"
#WARNING: obviously don't use the above passwords in production.

# Install mysql
# (Would prefer mariadb but having some problems with that
# and ubuntu + puppet at the moment).

class { '::mysql::server':
    root_password => "$::db_root_password",
    override_options => { 'mysqld' => { 'max_connections' => '1024' } }
}

include '::mysql::server'

mysql::db { "$db_dev":
    ensure => 'present',
    user => "$db_dev",
    password => "$db_dev_password",
    host => 'localhost',
    grant => ['ALL']
}

mysql::db { "$db_test":
    ensure => 'present',
    user => "$db_test",
    password => "$db_test_password",
    host => 'localhost',
    grant => ['ALL']
}

# Required rubygems

exec { 'bundle install':
    require => [
                    Package['ruby-bundler'],
                    Package['rake'],
                    Package['libmysqlclient-dev'],
                    Class['::mysql::server'],
                    Class['::mysql::client'],
               ],
    cwd => '/vagrant/rails/',
    path => ['/usr/bin', '/usr/sbin/', '/bin/'],
    timeout => 600
}

# Original PHP code configuration

file { '/vagrant/loader/PublicWhip/Config.pm':
    ensure => 'present',
    content => "package PublicWhip::Config;
use vars qw(\$user \$pass \$pwdata \$debatepath \$fileprefix);

\$user   = \"$db_dev\";
\$pass   = \"$db_dev_password\";
\$dbspec = \"DBI:mysql:$db_dev\";

# this is where the XML files come from:
\$pwdata = \"/vagrant/loader/data.openaustralia.org/\";
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

exec { "mysql --database=$db_dev -u $db_dev --password=$db_dev_password < /vagrant/loader/create.sql":
    refreshonly => true,
    subscribe => Mysql::Db["$db_dev"],
    path => ['/usr/bin', '/usr/sbin/', '/bin/']
}

# Still undecided if I should really be downloading data and populating the db
# via vagrant/puppet.
exec { '/vagrant/loader/load_openaustralia_xml.sh':
    refreshonly => true,
    subscribe => Exec["mysql --database=$db_dev -u $db_dev --password=$db_dev_password < /vagrant/loader/create.sql"],
    require => [
                    File['/vagrant/loader/PublicWhip/Config.pm'],
                    Package['libtext-autoformat-perl'],
                    Package['libunicode-string-perl'],
                    Package['libxml-twig-perl']
               ],
    cwd => '/vagrant/loader',
    timeout => 1200,
    path => ['/usr/bin', '/usr/sbin/', '/bin/']
}

# Rails port configuration

file { '/vagrant/rails/config/database.yml':
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

file { '/vagrant/rails/config/secrets.yml':
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