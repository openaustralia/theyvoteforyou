include apt

# Mysql
# (would prefer mariadb but having some problems with that
# and ubuntu at the moment).

class { '::mysql::server':
    root_password => 'abc123',
    override_options => { 'mysqld' => { 'max_connections' => '1024' } }
        
#WARNING: obviously don't use the above passwords in production.
}

include '::mysql::server'

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

package { 'ruby-bundler':
  ensure => 'latest'
}

package { 'libmysqlclient-dev':
    ensure  => 'latest',
}

package { 'rake':
  ensure => 'latest',
}

# Databases

mysql::db { 'publicwhip_dev':
    ensure => 'present',
    user => 'publicwhip_dev',
    password => 'abc123',
    host => 'localhost',
    grant => ['ALL']
    
#WARNING: obviously don't use the above passwords in production.
}

mysql::db { 'publicwhip_test':
    ensure => 'present',
    user => 'publicwhip_test',
    password => 'abc123',
    host => 'localhost',
    grant => ['ALL']
    
#WARNING: obviously don't use the above passwords in production.
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
# todo

# Rails port configuration

file { '/vagrant/rails/config/database.yml':
    ensure => 'present',
    content => "
development:
  adapter: mysql2
  database: publicwhip_dev
  username: publicwhip_dev
  password: abc123

# Warning: The database defined as 'test' will be erased and
# re-generated from your development database when you run 'rake'.
# Do not set this db to the same as development or production.
test:
  adapter: mysql2
  database: publicwhip_test
  username: publicwhip_test
  password: abc123
"

#WARNING: obviously don't use the above passwords in production.
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