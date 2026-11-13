# Boolean ENV var flags use ENV.true?, not a bare truthy check

Ruby only treats `nil`/`false` as falsy, so a bare `if ENV["FOO"]` treats any set value, including `"0"` and
`"false"`, as true; `export FOO=""` in a shell sets an empty string rather than unsetting the variable, so blank
counts as "set" too. `ENV.true?(key)` (`config/initializers/00_env_boolean.rb`, backed by
`ActiveModel::Type::Boolean`) treats nil, blank, and false-like strings ("0", "false", "off", "f", all lower or all
upper case) as false and everything else as true, matching what a human setting `FOO=0` or `FOO=false` would
expect. Mixed case such as "False" counts as true, as `ActiveModel::Type::Boolean` matches an exact list. So does
"no": use "false", "0" or "off".

Not available in `config/environments/*.rb` (loads before `config/initializers/*.rb`) or `config/puma.rb` (runs
outside the Rails boot sequence); use `ActiveModel::Type::Boolean.new.cast(ENV.fetch(key, nil))` directly there
instead. `config/puma.rb`'s `PIDFILE` check is a presence check for a string value, not a boolean flag, and
correctly stays a bare truthy check.

Decided 2026-08-09 in `docs/DECISIONS.md` on the branch for #1656, and moved here when that branch was merged with
main, which had adopted ADRs.
