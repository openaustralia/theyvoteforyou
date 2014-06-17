# Public Whip

## Development setup

Copy `config/database.yml.example` to `config/database.yml` and fill in the
appropriate details. Your username and password for the test and development
database must match for tests to work.

Copy `config/secrets.yml.example` to `config/secrets.yml` and run
`bundle exec rake secret` to generate a `secret_key_base` and
`php_id_hash_salt` for your environments (you'll need to copy/paste the keys in
after generating them).

    # Install bundle
    bundle install

    # Run tests (PHP_SERVER is the address of the local PHP version of the app)
    bundle exec rake PHP_SERVER=localhost

    # Start the server
    bundle exec rails server

