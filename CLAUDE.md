# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

They Vote For You (theyvoteforyou.org.au) is a Rails 8 app that makes Australian parliamentary voting data
understandable. It's an evolution of the UK Public Whip PHP project, and the same codebase (via the
`php-compatibility` branch) also serves the UK. A parallel Ukraine deployment loads data from morph.io scrapers via
Popolo format instead of the Australian Hansard XML pipeline.

Small team, low-capacity charity (OpenAustralia Foundation). Favour simple, low-maintenance solutions over ones that
need ongoing attention.

This repo is worked on via terminal Claude Code, VS Code, RubyMine, and cloud IDEs alike. Keep guidance and commands in
this file working across all of them, not just one, both when following it and when adding to it.

## Development environment

We provide a devcontainer for local and cloud development (Docker: Ruby, MySQL, Elasticsearch, Mailpit, rails-app), with
notes below on the hybrid option (Ruby on the host, services in the devcontainer). Run `make help` for a full list of
targets; the common ones:

```
make setup                                       # install Docker/Compose/devcontainer CLI on this host
make dev-up                                      # build and start the dev container (leave running)
make dev-exec COMMAND="..."                      # run any command inside the container (default: bash)
make dev-exec COMMAND="bin/setup --skip-server"  # first-time: bundle install, prepare DB, etc.
make dev-rake ARGS="..."                         # run a rake task inside the container (default: spec)
make dev-server                                  # run the Rails server, bound to 0.0.0.0
make dev-console                                 # bin/rails console inside the container
make dev-dbconsole                               # bin/rails dbconsole inside the container
make dev-down                                    # stop containers, keep volumes
make dev-clobber                                 # full reset: remove containers/images/volumes
```

The app runs at http://localhost:3088, Elasticsearch at http://localhost:9288, Mailpit at http://localhost:8088, MySQL
at `localhost:3388` (user `root`, password `password`).

### Running commands as an AI tool

Whether `make dev-exec`/`make dev-rake` wrapping is needed depends on where *this* shell already is, not on the project.
Work through these in order, only moving to the next if the current one doesn't clearly apply:

1. Try `bin/rails runner 'puts User.count'` directly. A number back means commands work directly here, whether that's
   because you're already inside the devcontainer (a VS Code window reopened in it, or a shell reached via
   `make dev-exec`) or on the host with this project's Ruby set up (the hybrid setup, see README's "Using just the other
   services"). Use `bin/rspec ...`, `bin/rails ...` etc. directly from here on; wrapping in `make dev-exec`
   would fail if you're already inside the container.
2. "Command not found" (no local Ruby/bundler)? Wrap instead: `make dev-exec COMMAND="..."` or
   `make dev-rake ARGS="..."`.
3. A database or connection error instead? Don't assume, ask. That could mean the devcontainer isn't running or
   `.envrc` isn't loaded, not "no Ruby available", and guessing wrong here risks running against the wrong database.

### First-time data load

```
bin/rake application:load:members
bin/rake application:load:divisions[2021-07-01,2021-10-31]
bin/rake application:cache:all
bin/rake searchkick:reindex:all
```

## Tests and linting

```
bin/rake                                   # default task: full spec suite (see Rakefile/CI)
bin/rspec spec/models/division_spec.rb     # single file
bin/rspec spec/models/division_spec.rb:42  # single example by line
bin/rubocop                                # style/lint checks (also run with --parallel in CI)
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

- **`Person`**, a real individual, persists across time. Has many **`Member`**s (one per stint representing an **
  `Electorate`**/**`Office`** in a **`House`**, `representatives` or `senate`). Delegates most display info (name,
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

### Data loading

`app/lib/data_loader/` ingests data from two distinct sources into the same schema:

- **Australia**: `debates_xml.rb` / `division_xml.rb` parse ParlParse-format debate XML from data.openaustralia.org.au
  (produced by the separate `openaustralia-parser` project) into `Division`/`Vote`/`Whip`
  records. `members.rb`/`offices.rb`/`electorates.rb` load MP/electorate data. Invoked via `application:load:*` rake
  tasks; `application:load:daily` runs nightly via cron in production.
- **Ukraine (and other Popolo countries)**: `popolo.rb` loads people *or* vote data from Popolo-format JSON (produced by
  EveryPolitician / a morph.io scraper + the `morph_popolo` proxy) via `application:load:popolo[url]`. Whichever Popolo
  content the file contains determines what gets loaded. No separate flag needed.

Both paths converge on the same `Person`/`Member`/`Division`/`Vote` models. The rest of the app (policies, distances,
views) doesn't care which country the data came from, aside from `House.australian` gating which house names are valid
(see README's "UK" section for more).

### Authorization and admin

- Pundit policies (`app/policies/`) gate actions like editing divisions/policies; `ApplicationPolicy` is the base.
- `administrate` gem powers a separate admin panel (`app/dashboards/`, `Admin::` namespaced controllers) at `/admin`,
  restricted to `User#admin?`. The first admin must be granted via `rails console` (see README "Accessing the admin
  panel").
- `flipper` feature flags gate in-progress features; flag names in the admin UI (`/admin/flipper/features`) must match
  the symbols used in `config/initializers/flipper.rb` and in code.

### Search

`searchkick`-backed Elasticsearch indices exist on `Division`, `Policy` and `Member` (index names suffixed with
`Rails.env`, so test/dev/prod don't collide). Reindex with `bin/rake searchkick:reindex:all` after bulk data loads.

### Deployment

- Australia: Capistrano (`make deploy-production` / `make deploy-staging`, or `bin/cap production deploy`).
- Ukraine: Mina (`bundle exec mina ukraine_dev deploy` / `ukraine_production`); server provisioning lives in a separate
  repo (`OPORA/publicwhip_server`).
- These, and any rake task run with `RAILS_ENV=production` (see README's "Loading data" section), are reference
  material, not routine commands. Never run one without an explicit, specific go-ahead for that exact action, right now,
  regardless of how confident the request sounds.

## Conventions worth knowing

- Use https://rubystyle.guide/ as the baseline Ruby style guide, customized by `.rubocop.yml`. Run `bin/rubocop`
  rather than trying to memorise every rule; a few customizations worth knowing up front:
    - Add `frozen_string_literal: true` at the top of every new Ruby file (this one's actually RuboCop's own default,
      not a project customization, but easy to forget).
    - Use double-quoted strings, not single quotes (`Style/StringLiterals`; the community default is single quotes, this
      repo deliberately overrides it).
    - `Layout/LineLength` and most `Metrics/*` cops are deliberately disabled, not because long lines or methods are
      wanted, but because there's existing code to clean up first. Try to keep new lines to a max of 120 characters.
    - Likewise, keeping methods to 20 lines and files to 200 lines (400 for specs) and one-responsibility-per-file are a
      guideline, not a hard limit. Use size as a trigger to ask
      "would breaking this up make it easier to understand and test?", not as a number to strictly enforce.
- Aim to work through and clear `.rubocop_todo.yml` when you're already working on relevant code (it lists specific
  cop/file exclusions still to be fixed, e.g. `Rails/StrongParametersExpect` across most controllers).
- A spec file 2-3x the size of the file it tests is not unusual; 5x+ is a sign the spec (or the code under it) needs
  restructuring, not just patience. Flag it and ask rather than restructuring anything unprompted.
- Code should be clear in expressing what is being done, comments should explain why when it is not self-evident. Look
  at writing clearer code before having comments explaining what is being done. Target audience: a Ruby developer
  returning after a long gap, so near cold, no need to teach Ruby/Rails basics, but succinctly point to relevant docs in
  the file/class comment to refresh context rather than assuming it's retained.

## Working with AI tools

- If something here doesn't match what you're consistently seeing in the code, flag the mismatch and ask which needs
  fixing (so it's fixed once and for all), presenting fixing the code as the easy default choice and updating this file
  as the alternative.
- Use Australian spelling and voice in new code (variable/constant names, comments, commit and error messages).
- No em dashes, anywhere: code, docs, commit messages, chat, not just Ruby files. Use a hyphen, comma, or full stop
  instead. This is already an org-wide rule; it's stated here too since this file may be read by tools that don't have
  that context loaded.
- Don't flatter, over-praise, or write to keep the conversation pleasant. Skip stock enthusiasm like "Great question!"
  or "You're absolutely right!" entirely, and focus on what actually helps the decision at hand.
- If the human's premise or approach looks wrong, say so before proceeding. Don't silently go along with it just to
  avoid friction, that's the same underlying problem as flattery, agreeing instead of helping.
- Don't add abstractions, refactors, or generality beyond what was asked, but don't be afraid to offer to DRY up
  repetitions and refactor code if it will make it genuinely easier to understand and avoid mistakes.
- Keep responses proportional to the question. A simple question gets a direct answer, flagged as a summary with an
  offer to expand if I'm leaving detail out, not a wall of caveats up front.
- Test reality, not mocks, for internal objects. VCR/WebMock cover external calls. (`RSpec/SubjectStub` is disabled in
  rubocop because of existing debt, not because stubbing internals is the goal.)
- Ask before "cleaning up" working code beyond what was requested. Messiness often reflects a real-world constraint that
  isn't visible from the diff alone, and explain why in a comment.
- If a request could reasonably expand scope, list the extra ideas as bullets up front, separate from the
  implementation, then wait rather than doing both.
- If a request doesn't narrow the implementation down to one reasonable choice, ask which behaviour is wanted before
  writing code. Don't guess, and don't build for every interpretation.
    - Give a terse list of your top suggestions with pros and cons to assist the decision-making.
- Check `docs/DECISIONS.md` for past cross-cutting decisions before assuming in an unfamiliar area of the codebase; add
  a new entry there (rather than repeating code comments in multiple places) when a decision spans multiple files.
- Stage commits, don't make them. `git add` the files, then write the proposed message (with the `Assisted-by:`
  trailer) to `.git/GITGUI_MSG` (used by `git gui`) and display for copy and paste to an IDE.
    - Check the file first; if it already has content, ask before overwriting rather than clobbering an existing draft.
    - This keeps review and sign-off a deliberate separate human act, not a rubber stamp.
- When a commit message body covers more than one distinct point, use a markdown bullet list rather than one flowing
  paragraph; it's easier to scan and review.
- Check the `openaustralia/.github` repo for the org-wide PR/issue templates and `CONTRIBUTING.md`.
    - there may be a local clone at `../.github`; check there first, it's quicker, but don't assume it's present.
- PRs must disclose material AI involvement per OAF's CLA (`openaustralia/.github` repo, `CLA/CLA.md`): a note in the PR
  description, distinct from the commit `Assisted-by:` trailer.
- PRs I create must be opened as drafts (`gh pr create --draft --assignee <human>`), never ready-for-review directly.
  Taking one out of draft is the human's call, not mine, same as sign-off and co-authorship (no
  `Signed-off-by`/`Co-authored-by` trailer for AI). Assign it to the human, not me: per CONTRIBUTING.md, PRs are
  assigned to whoever is driving the change, which is them. Draft is the right first step regardless of author: per
  CONTRIBUTING.md, checks in `.github/workflows` must be green before leaving draft, and staying in draft is itself the
  flag that a human still needs to review it.
- GitHub issues have no draft state (unlike PRs). Don't create one directly; draft the title/body for the human to file
  themselves, unless they've explicitly asked you to create it this time.
- Never commit real personal details, credentials, or secrets. Use fictional placeholders in specs, factories, and test
  data (Australian Privacy Principles apply to anyone's data, not just OAF's own).
- Keep all copy, comments, and admin text non-partisan! This project doesn't imply endorsement or criticism of any
  party, vote, or position, ever.
- Don't fabricate citations, figures, or URLs in comments or docs. Say when something's unverified or weakly supported
  rather than guessing (this applies to me too, not just contributors).
