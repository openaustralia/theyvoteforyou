# Decisions

Cross-cutting engineering decisions and directives that aren't tied to one file or area, so a code comment alone
wouldn't surface them. A decision local to one file/method belongs as a comment there instead, explaining why.

Append new entries at the top. Don't edit past entries except to mark them superseded (and say by what).

## 2026-08-09 - No Elasticsearch replicas outside development/test

A single-node dev/test Elasticsearch cluster can never satisfy a replica, which leaves cluster health permanently
yellow. `SEARCHKICK_INDEX_SETTINGS` in `config/initializers/elasticsearch.rb` sets `number_of_replicas: 0` when
`Rails.env.local?`; production/staging get no override, so they keep Elasticsearch's own default.

## 2026-08-09 - Australian spelling in new code

New variable/constant names, comments, and commit/error messages use Australian spelling. This is about code
specifically, distinct from prose style conventions elsewhere.
