# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, GitHub Copilot, Codex, and others) when working with code
in this repository. `CLAUDE.md` and `.github/copilot-instructions.md` point here, so there is one file to keep current
rather than several that drift apart.

## What this is

They Vote For You (theyvoteforyou.org.au) is a Rails 8 app that makes Australian parliamentary voting data
understandable. It's an evolution of the UK Public Whip PHP project, and the same codebase (via the `php-compatibility`
branch) also serves the UK. A parallel Ukraine deployment loads data from morph.io scrapers via Popolo format instead of
the Australian Hansard XML pipeline.

Small team, low-capacity charity (OpenAustralia Foundation). Favour simple, low-maintenance solutions over ones that
need ongoing attention.

This repo is worked on via terminal Claude Code, GitHub Copilot, VS Code, RubyMine, and cloud IDEs alike. Keep guidance
and commands in this file working across all of them, not just one, both when following it and when adding to it.

`design_docs/principles.md`, `design_docs/design_persona.md` and `design_docs/user-questions.md` describe who the site
is for and how it should behave. Read them before changing anything user-facing.

## Contributing

**This repository has no `CONTRIBUTING.md`, issue templates or pull request template of its own.** It inherits them from
[`openaustralia/.github`](https://github.com/openaustralia/.github), which supplies the org-wide defaults to every
repository that doesn't provide its own copy. Fetch and follow them rather than guessing:

- `.github/CONTRIBUTING.md` - GitHub Flow, Conventional Branch naming, DCO sign-off, AI disclosure
- `AGENTS.md` (in that repo's root) - org-wide conventions for working as an agent in any OAF repo
- `.github/PULL_REQUEST_TEMPLATE.md` - the PR description structure to fill in
- `.github/ISSUE_TEMPLATE/bug_report.yml` and `feature_request.yml`

`.github/CODEOWNERS` here is repo-local and does override the org default.

Treat `openaustralia/.github` as the source of truth for process, not this file. Two points from it that matter most
often:

- Branch names follow [Conventional Branch](https://conventionalbranch.org/#summary):
  `feature/123-short-description`, `bugfix/`, `hotfix/`, `chore/`, `doc/`.
- AI involvement is disclosed in **two** places: an `Assisted-by: <tool>:<model-id>` trailer in the commit's trailer
  block, and a note in the PR description. Report the model actually used, not a remembered default.

That guide marks itself as still evolving, with an "Open questions" section at the end. Don't present unsettled points
as decided. In particular, OAF **removed** its contributor licence agreement; whether to reinstate one is open, and
there is no CLA file in `openaustralia/.github` to cite.

## Development environment

Ruby version is pinned in `.ruby-version` (3.4.4). MySQL and HTMLTidy are the system dependencies.

```
brew install tidy-html5 mysql rbenv ruby-build   # macOS
sudo apt-get install tidy mysql-server mysql-client libmysqlclient-dev   # Debian/Ubuntu
```

Then, per the README:

```
bundle install
cp config/database.yml.example config/database.yml   # then edit credentials
bundle exec rake application:config:dev              # writes remaining dev config
bundle exec rake db:setup                            # schema plus seed data
bundle exec rake                                     # full spec suite
bundle exec rails server                             # http://localhost:3000
```

`bin/setup` does a shorter version of the same thing (`bundle check || bundle install`, `bin/rails db:prepare`, clear
logs and tmp) and then execs `bin/dev`, which is just `bin/rails server`. Pass `--skip-server` to stop before that.

`foreman start` uses the `Procfile` to run the server alongside `mailcatcher` (web UI at http://localhost:1080), which
catches confirmation emails in development. Install it separately: `gem install mailcatcher`.

### Makefile targets

`make` has no `help` target. The complete list is:

```
make init-submodules     # git submodule update --init --recursive
make install-ruby        # rbenv install < .ruby-version
make dev-services-up     # MySQL, Elasticsearch and dejavu via docker-stack/dev
make test-services-up    # the same services for the test environment
make deploy-production   # bundle exec cap production deploy
make deploy-staging      # bundle exec cap staging deploy
```

`make dev-services-up` starts services only, not the app. Ruby and the Rails server still run on the host. The compose
file exposes MySQL on 3306, Elasticsearch on 9200/9300 and the dejavu Elasticsearch browser on
http://localhost:1358.

There is no devcontainer and no `make dev-exec`-style wrapper on this branch. If you find yourself reaching for one,
check whether you're on a branch that adds it before assuming it exists.

### First-time data load

```
bundle exec rake application:load:members
bundle exec rake application:load:divisions[2021-07-01,2021-10-31]
bundle exec rake application:cache:all
bundle exec rake searchkick:reindex:all
```

`application:cache:all` recalculates people distances, which takes a long time.
`application:cache:all_except_people_distances` exists for when you don't need them.

## Tests and linting

```
bin/rake                                   # default task: full spec suite (this is what CI runs)
bin/rspec spec/models/division_spec.rb     # single file
bin/rspec spec/models/division_spec.rb:42  # single example by line
bin/rubocop                                # style and lint checks
bin/rubocop --parallel                     # as CI runs it
bundle exec ruby-audit                     # Ruby security advisories
bundle exec bundle-audit                   # gem security advisories
```

CI (`.github/workflows/rubyonrails.yml`) runs two jobs on every push and pull request: `test` (MySQL 5.7 service,
`apt install tidy`, `bin/rails db:schema:load`, then `bin/rake`) and `lint` (`bin/rubocop --parallel`). Brakeman is
commented out pending a Rails upgrade, so `bin/brakeman` exists but isn't a gate.

Specs use RSpec with Capybara (features), FactoryBot, VCR/WebMock for external HTTP (cassettes in
`spec/vcr_cassettes`), and SimpleCov with `app/controllers/admin/` and `app/dashboards/` filtered out of coverage.

### Test gotchas worth knowing before you debug

- **HTMLTidy must be on `PATH`.** `spec/html_compare_helper.rb` shells out to the `tidy` binary to normalise HTML before
  comparing it. Without it, view and feature specs fail in ways that look nothing like a missing system package. On
  macOS it prefers `/usr/local/bin/tidy` (Homebrew) over any other copy.
- **`FactoryBot.lint` runs in `before(:suite)`.** One broken factory fails the whole run before a single example
  executes, so a confusing "nothing ran" failure usually means a factory, not the spec you just wrote.
- **Searchkick callbacks are disabled in tests** (`Searchkick.disable_callbacks`). Code that reindexes must guard on
  `Searchkick.callbacks?`, as `WikiMotion` does, or it will blow up under test.
- **Delayed Job runs inline in tests** (`Delayed::Worker.delay_jobs = false`), so queued work executes synchronously.
- Elasticsearch versions differ between places: `docker-stack/dev` pins `elasticsearch:6.8.23` while the Gemfile has
  `elasticsearch, "~> 7"`. Check what's actually running before attributing a failure to either.

## Architecture

### Domain model

The core relational chain, from a single parliamentary vote up to policy analysis:

- **`Person`**, a real individual, persists across time. Has many **`Member`**s (one per stint representing an
  **`Electorate`**/**`Office`** in a **`House`**, `representatives` or `senate`). Delegates most display info (name,
  party, current status) to `latest_member`.
- **`Division`**, a single vote event in parliament (has a motion, a date, a house). Has many **`Vote`**s (one per
  member who voted), and a cached `Whip` per party (aggregate aye/no/tell counts, used for fast tallies instead of
  counting `Vote` rows). `DivisionInfo` holds computed aggregates (turnout, majority) that `Division` delegates to.
- **`WikiMotion`**, a user-editable title/description overlay on a `Division`'s raw imported motion text, with
  `PaperTrail` history. `Division#name`/`#motion` prefer the wiki version over the raw imported one when present.
- **`Policy`**, a curated topic (e.g. "climate change") linking a set of `Division`s via `PolicyDivision` (each
  recording whether an aye/no vote counts *for* or *against* the policy). Policies are user-authored/edited content
  (`has_paper_trail`), reviewed via an admin workflow (`private` enum: `published` / `provisional` / legacy).
- **`PolicyPersonDistance`** / **`PeopleDistance`**, precomputed "how closely does this person's voting record align
  with this policy / with this other person" scores, recalculated by background jobs
  (`CalculatePolicyPersonDistancesJob`) rather than on read.
- **`Watch`**, lets a `User` subscribe to a `Policy` or `Division`; `AlertWatchesJob` emails on relevant changes.

`House.australian` is the single list of valid house names (`representatives`, `senate`). It's the main place the schema
is Australia-specific.

### Data loading

`app/lib/data_loader/` ingests data from two distinct sources into the same schema:

- **Australia**: `debates_xml.rb` / `division_xml.rb` parse ParlParse-format debate XML from data.openaustralia.org.au
  (produced by the separate `openaustralia-parser` project) into `Division`/`Vote`/`Whip` records.
  `members.rb`/`offices.rb`/`electorates.rb` load MP/electorate data. Invoked via `application:load:*` rake tasks;
  `application:load:daily` runs nightly via cron in production (09:15).
- **Ukraine (and other Popolo countries)**: `popolo.rb` loads people *or* vote data from Popolo-format JSON (produced by
  EveryPolitician / a morph.io scraper plus the `morph_popolo` proxy) via `application:load:popolo[url]`. Whichever
  Popolo content the file contains determines what gets loaded. No separate flag needed.

Both paths converge on the same `Person`/`Member`/`Division`/`Vote` models. The rest of the app (policies, distances,
views) doesn't care which country the data came from.

Rake tasks live in `lib/tasks/application.rake`, grouped into `application:load:`, `application:cache:`,
`application:cards:` (social sharing images, generated by `app/lib/card_screenshotter/`), `application:links_valid:`,
`application:seed:` and `application:config:`.

### Authorization and admin

- Pundit policies (`app/policies/`) gate actions like editing divisions and policies; `ApplicationPolicy` is the base.
- The `administrate` gem powers a separate admin panel (`app/dashboards/`, `Admin::` namespaced controllers) at
  `/admin`, restricted to `User#admin?`. The first admin must be granted via `rails console` (see the README's
  "Accessing the admin panel").
- `flipper` feature flags gate in-progress features. Flag names created in the admin UI
  (`/admin/flipper/features`) must match the symbols used in code, and the description list in
  `config/initializers/flipper.rb` should be kept in step. Nothing checks this for you.
- Devise handles authentication, with `invisible_captcha` on public sign-up forms.

### Search

`searchkick`-backed Elasticsearch indices exist on `Division`, `Policy` and `Member`, with index names of the form
`tvfy_divisions_#{Rails.env}` so test/dev/prod don't collide. `WikiMotion` isn't indexed itself; creating one reindexes
its `Division`. Reindex with `bundle exec rake searchkick:reindex:all` after bulk data loads.

### Deployment

- Australia: Capistrano (`make deploy-production` / `make deploy-staging`, or `bundle exec cap production deploy`).
  Config in `Capfile` and `config/deploy/`.
- Ukraine: Mina (`bundle exec mina ukraine_dev deploy` / `ukraine_production`), config in `Minafile`. Server
  provisioning lives in a separate repo (`OPORA/publicwhip_server`).
- These, and any rake task run with `RAILS_ENV=production` (see the README's "Loading data" section), are reference
  material, not routine commands. **Never run one without an explicit, specific go-ahead for that exact action, right
  now**, regardless of how confident the request sounds.

## Conventions worth knowing

- Use https://rubystyle.guide/ as the baseline Ruby style guide, customised by `.rubocop.yml`. Run `bin/rubocop` rather
  than trying to memorise every rule. A few customisations worth knowing up front:
    - Add `frozen_string_literal: true` at the top of every new Ruby file (RuboCop's own default, not a project
      customisation, but easy to forget).
    - Use double-quoted strings, not single quotes (`Style/StringLiterals`; the community default is single quotes and
      this repo deliberately overrides it).
    - `Layout/LineLength` and most `Metrics/*` cops are deliberately disabled, not because long lines or methods are
      wanted, but because there's existing code to clean up first. Try to keep new lines to a maximum of 120 characters.
    - Likewise, keeping methods to 20 lines and files to 200 lines (400 for specs), and one responsibility per file, are
      guidelines rather than hard limits. Use size as a trigger to ask "would breaking this up make it easier to
      understand and test?", not as a number to enforce.
    - `config/initializers/*`, `config/routes.rb`, `db/migrate/*`, `db/schema.rb`, `bin/*` and `vendor/` are excluded
      from RuboCop entirely, so a clean `bin/rubocop` says nothing about those files.
- Aim to work through and clear `.rubocop_todo.yml` when you're already working on relevant code. It lists specific
  cop/file exclusions still to be fixed, for example `Rails/StrongParametersExpect` across most controllers.
- A spec file 2-3x the size of the file it tests is not unusual; 5x or more is a sign the spec (or the code under it)
  needs restructuring, not just patience. Flag it and ask rather than restructuring anything unprompted.
- Code should be clear in expressing what is being done; comments should explain why, when that isn't self-evident.
  Look at writing clearer code before adding a comment describing what the code does. Target audience: a Ruby developer
  returning after a long gap, so near cold. No need to teach Ruby or Rails basics, but point succinctly to relevant docs
  in the file or class comment to refresh context rather than assuming it's retained.
- Views are HAML, styles are Sass with Bootstrap 3.

## Working with AI tools

- If something here doesn't match what you're consistently seeing in the code, flag the mismatch and ask which needs
  fixing (so it's fixed once and for all), presenting fixing the code as the easy default choice and updating this file
  as the alternative.
- Use Australian spelling and voice in new code (variable and constant names, comments, commit and error messages).
- No em dashes, anywhere: code, docs, commit messages, chat, not just Ruby files. Use a hyphen, comma, or full stop
  instead. This is already an org-wide rule; it's stated here too since this file may be read by tools that don't have
  that context loaded.
- Don't flatter, over-praise, or write to keep the conversation pleasant. Skip stock enthusiasm like "Great question!"
  or "You're absolutely right!" entirely, and focus on what actually helps the decision at hand.
- If the human's premise or approach looks wrong, say so before proceeding. Don't silently go along with it to avoid
  friction; that's the same underlying problem as flattery, agreeing instead of helping.
- Don't add abstractions, refactors, or generality beyond what was asked, but don't be afraid to offer to DRY up
  repetition and refactor code where it will genuinely make it easier to understand and harder to get wrong.
- Keep responses proportional to the question. A simple question gets a direct answer, flagged as a summary with an
  offer to expand if detail is being left out, not a wall of caveats up front.
- Test reality, not mocks, for internal objects. VCR/WebMock cover external calls. (`RSpec/SubjectStub` is disabled in
  RuboCop because of existing debt, not because stubbing internals is the goal.)
- Ask before "cleaning up" working code beyond what was requested. Messiness often reflects a real-world constraint that
  isn't visible from the diff alone; when you do learn the reason, record it in a comment.
- If a request could reasonably expand scope, list the extra ideas as bullets up front, separate from the
  implementation, then wait rather than doing both.
- If a request doesn't narrow the implementation down to one reasonable choice, ask which behaviour is wanted before
  writing code. Don't guess, and don't build for every interpretation. Give a terse list of your top suggestions with
  pros and cons to assist the decision.
- Check `docs/DECISIONS.md` for past cross-cutting decisions before assuming in an unfamiliar area of the codebase, and
  add a new entry there (rather than repeating the same comment in several files) when a decision spans multiple files.
- Stage commits, don't make them. `git add` the files, then write the proposed message (including the `Assisted-by:`
  trailer) wherever your IDE picks up a prepared message, defaulting to `.git/GITGUI_MSG` (used by `git gui`), and
  display it for copy and paste.
    - Check that file first. If it already has content, ask before overwriting rather than clobbering an existing draft.
    - This keeps review and sign-off a deliberate human act, not a rubber stamp. Only a person can make the DCO
      `Signed-off-by` commitment, and org `CONTRIBUTING.md` says so explicitly.
- When a commit message body covers more than one distinct point, use a markdown bullet list rather than one flowing
  paragraph; it's easier to scan and review.
- The rest of the org-wide agent conventions (draft PRs assigned to the human, AI disclosure in both places, no
  `Signed-off-by` or `Co-authored-by` on an agent's behalf, issue drafting rather than creation, standing-approval
  scoping) live in `openaustralia/.github`'s `AGENTS.md`. Fetch it per the Contributing section above rather than
  relying on a copy here that would drift.
- Never commit real personal details, credentials, or secrets. Use fictional placeholders in specs, factories, and test
  data. The Australian Privacy Principles apply to anyone's data, not just OAF's own, and this database holds records
  about real people.
- Keep all copy, comments, and admin text non-partisan. This project never implies endorsement or criticism of any
  party, candidate, vote, or position. Report what the data says and let it speak.
- Don't fabricate citations, figures, or URLs in comments or docs. Say when something is unverified or weakly supported
  rather than guessing. This applies to AI tools at least as much as to human contributors.
