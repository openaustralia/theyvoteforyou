# Decisions

Cross-cutting engineering decisions and directives that aren't tied to one file or area, so a code comment alone
wouldn't surface them. A decision local to one file/method belongs as a comment there instead, explaining why.

Append new entries at the top. Don't edit past entries except to mark them superseded (and say by what).

## 2026-08-09 - Boolean ENV var flags use ENV.true?, not a bare truthy check

Ruby only treats `nil`/`false` as falsy, so a bare `if ENV["FOO"]` treats any set value, including `"0"` and
`"false"`, as true; `export FOO=""` in a shell sets an empty string rather than unsetting the variable, so blank
counts as "set" too. `ENV.true?(key)` (`config/initializers/00_env_boolean.rb`, backed by
`ActiveModel::Type::Boolean`) treats nil, blank, and false-like strings ("0", "false", "off", "f", case-insensitive)
as false and everything else as true, matching what a human setting `FOO=0` or `FOO=false` would expect.

Not available in `config/environments/*.rb` (loads before `config/initializers/*.rb`) or `config/puma.rb` (runs
outside the Rails boot sequence); use `ActiveModel::Type::Boolean.new.cast(ENV.fetch(key, nil))` directly there
instead. `config/database.yml.example`'s `DB_HOST`/`DB_PORT` checks and `config/puma.rb`'s `PIDFILE` check are
presence checks for string config values, not boolean flags, and correctly stay as bare truthy checks.

Gotcha for non rubiest: "no" evaluates as true as does "yes", use "false" or "0" or "off" instead

## 2026-08-09 - No Elasticsearch replicas outside development/test

A single-node dev/test Elasticsearch cluster can never satisfy a replica, which leaves cluster health permanently
yellow. `SEARCHKICK_INDEX_SETTINGS` in `config/initializers/elasticsearch.rb` sets `number_of_replicas: 0` when
`Rails.env.local?`; production/staging get no override, so they keep Elasticsearch's own default.

## 2026-08-09 - Australian spelling in new code

New variable/constant names, comments, and commit/error messages use Australian spelling. This is about code
specifically, distinct from prose style conventions elsewhere.
