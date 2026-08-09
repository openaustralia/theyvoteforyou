# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

They Vote For You (theyvoteforyou.org.au) is a Rails 8 app that makes Australian parliamentary voting data
understandable. It's an evolution of the UK Public Whip PHP project, and the same codebase (via the
`php-compatibility` branch) also serves the UK. A parallel Ukraine deployment loads data from morph.io scrapers via
Popolo format instead of the Australian Hansard XML pipeline.

Small team, low-capacity charity (OpenAustralia Foundation) — favour simple, low-maintenance solutions over ones that
need ongoing attention.

## Development environment

Everything runs in a devcontainer (Docker: Ruby, MySQL, Elasticsearch, Mailpit, rails-app). Run `make help` for a full
list of targets; the common ones:

```
make setup                                              # install Docker/Compose/devcontainer CLI on this host
make dev-up                                              # build and start the dev container (leave running)
make dev-exec COMMAND="bin/setup --skip-server"          # first-time: bundle install, prepare DB, etc.
make dev-server                                          # run the Rails server, bound to 0.0.0.0
make dev-console                                         # bin/rails console inside the container
make dev-dbconsole                                        # bin/rails dbconsole inside the container
make dev-exec COMMAND="..."                              # run any command inside the container (default: bash)
make dev-rake ARGS="..."                                 # run a rake task inside the container (default: spec)
make dev-down                                            # stop containers, keep volumes
make dev-clobber                                         # full reset: remove containers/images/volumes
```

The app runs at http://localhost:3088, Elasticsearch at http://localhost:9288, Mailpit at http://localhost:8088, MySQL
at `localhost:3388` (user `root`, password `password`).

To run Rails locally against the container's MySQL/Elasticsearch/Mailpit instead of the whole thing containerised, see
the "Using just the other services" section of README.md for the `.envrc` variables needed.

### First-time data load

```
make dev-exec COMMAND="bin/rake application:load:members"
make dev-exec COMMAND="bin/rake application:load:divisions[2021-07-01,2021-10-31]"
make dev-exec COMMAND="bin/rake application:cache:all"
make dev-exec COMMAND="bin/rake searchkick:reindex:all"
```

## Tests and linting

Run inside the container (`make dev-exec COMMAND="..."` or `make dev-rake ARGS="..."`):

```
bin/rake                                   # default task: full spec suite (see Rakefile/CI)
bundle exec rspec spec/models/division_spec.rb            # single file
bundle exec rspec spec/models/division_spec.rb:42          # single example by line
bundle exec rubocop                        # style/lint checks (also run with --parallel in CI)
bundle exec ruby-audit                     # check for Ruby security advisories
bundle exec bundle-audit                   # check gems for security advisories
```

CI (`.github/workflows/rubyonrails.yml`) runs the spec suite against MySQL 5.7 and `bin/rubocop --parallel` as a
separate lint job.

Specs use RSpec + Capybara (features), FactoryBot, VCR/WebMock for external HTTP (cassettes in
`spec/vcr_cassettes`), and SimpleCov (admin panel and dashboards excluded from coverage).

## Architecture

### Domain model

The core relational chain, from a single parliamentary vote up to policy analysis:

- **`Person`** — a real individual, persists across time. Has many **`Member`**s (one per stint representing an
  **`Electorate`**/**`Office`** in a **`House`** — `representatives` or `senate`). Delegates most display info
  (name, party, current status) to `latest_member`.
- **`Division`** — a single vote event in parliament (has a motion, a date, a house). Has many **`Vote`**s (one per
  member who voted), and a cached `Whip` per party (aggregate aye/no/tell counts, used for fast tallies instead of
  counting `Vote` rows). `DivisionInfo` holds computed aggregates (turnout, majority) that `Division` delegates to.
- **`WikiMotion`** — user-editable title/description overlay on a `Division`'s raw imported motion text, with
  `PaperTrail` history. `Division#name`/`#motion` prefer the wiki version over the raw imported one when present.
- **`Policy`** — a curated topic (e.g. "climate change") linking a set of `Division`s via `PolicyDivision` (each
  recording whether an aye/no vote counts *for* or *against* the policy). Policies are user-authored/edited content
  (`has_paper_trail`), reviewed via an admin workflow (`private` enum: `published` / `provisional` / legacy).
- **`PolicyPersonDistance`** / **`PeopleDistance`** — precomputed "how closely does this person's voting record align
  with this policy / with this other person" scores, recalculated by background jobs
  (`CalculatePolicyPersonDistancesJob`) rather than on read.
- **`Watch`** — lets a `User` subscribe to a `Policy` or `Division`; `AlertWatchesJob` emails on relevant changes.

### Data loading

`app/lib/data_loader/` ingests data from two distinct sources into the same schema:

- **Australia**: `debates_xml.rb` / `division_xml.rb` parse ParlParse-format debate XML from
  data.openaustralia.org.au (produced by the separate `openaustralia-parser` project) into `Division`/`Vote`/`Whip`
  records. `members.rb`/`offices.rb`/`electorates.rb` load MP/electorate data. Invoked via `application:load:*` rake
  tasks; `application:load:daily` runs nightly via cron in production.
- **Ukraine (and other Popolo countries)**: `popolo.rb` loads people *or* vote data from Popolo-format JSON (produced
  by EveryPolitician / a morph.io scraper + the `morph_popolo` proxy) via `application:load:popolo[url]`. Whichever
  Popolo content the file contains determines what gets loaded — no separate flag needed.

Both paths converge on the same `Person`/`Member`/`Division`/`Vote` models — the rest of the app (policies, distances,
views) doesn't care which country the data came from, aside from `House.australian` gating which house names are
valid and country-specific deployment/theming being out of scope of the codebase itself (see README "UK" section for
what a hypothetical UK Rails migration would still need).

### Authorization and admin

- Pundit policies (`app/policies/`) gate actions like editing divisions/policies; `ApplicationPolicy` is the base.
- `administrate` gem powers a separate admin panel (`app/dashboards/`, `Admin::` namespaced controllers) at `/admin`,
  restricted to `User#admin?`. The first admin must be granted via `rails console` (see README "Accessing the admin
  panel").
- `flipper` feature flags gate in-progress features; flag names in the admin UI
  (`/admin/flipper/features`) must match the symbols used in `config/initializers/flipper.rb` and in code.

### Search

`searchkick`-backed Elasticsearch indices exist on `Division` and `Policy` (index names suffixed with `Rails.env`,
so test/dev/prod don't collide). Reindex with `bin/rake searchkick:reindex:all` after bulk data loads.

### Deployment

- Australia: Capistrano (`make deploy-production` / `make deploy-staging`, or `bundle exec cap production deploy`).
- Ukraine: Mina (`bundle exec mina ukraine_dev deploy` / `ukraine_production`); server provisioning lives in a
  separate repo (`OPORA/publicwhip_server`).

## Conventions worth knowing

- `frozen_string_literal: true` at the top of every Ruby file.
- Double-quoted strings are the house style (`Style/StringLiterals` enforces this), not single quotes.
- `Layout/LineLength` and most `Metrics/*` cops are deliberately disabled — don't wrap lines or split methods just to
  satisfy a cop that isn't enabled. See `.rubocop.yml` for the full set of intentional deviations from rubocop
  defaults, most marked `TODO` for a future tightening pass.
