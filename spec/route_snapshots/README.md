# Routing snapshot

What Stages 1 and 2 of the AI division summary pipeline decide for every division from January 2025
to October 2026, one YAML file per year, written by `rake ai:route_snapshot`
(`DivisionSummaryPipeline::RouteSnapshot`). The specs show each routing rule works on the example it
was written for; this shows what the rules do across real divisions, and what else moves when
someone changes one.

The committed files are the expected result. A change to what Stage 1 reads or Stage 2 decides is
committed together with the files it changes, and the pull request explains every changed division.

## Running it

```bash
bin/rake ai:route_snapshot                # every year in settings.yml
bin/rake ai:route_snapshot YEARS=2026     # one year
bin/rake ai:route_snapshot YEARS=2025-2026
```

It reads divisions from your database and Hansard from `tmp/hansard_xml/`, downloading any day it
doesn't have yet from the same place the nightly loader reads, and remembering days with none
(an empty `.missing` file) so it asks about each only once, unless the database has divisions on
that day, which means its Hansard was published after the day was first asked about. It uses no model and writes nothing to
the database. A year outside the range in `settings.yml` is refused: change the range there first,
as a change of its own.

Before writing anything it checks that your database holds every division Hansard records in the
years asked for, walking every day in both houses as the loader does. If any are missing, it stops,
lists the days and prints the loader command that fills them, for example
`bin/rake "application:load:divisions[2025-01-01,2025-12-31]"`. The first check of a year asks about
every day not yet in `tmp/hansard_xml/`, a few hundred requests that take a minute or two.

After writing a year, it lists any day whose Hansard has changed since that year's file was last
written (see "When the files change with no code change").

## The routine for a change to Stage 1 or Stage 2

1. Before changing anything, run the task. `git diff spec/route_snapshots` should show
   nothing. If it shows changes, they come from your Hansard or your database, not the code (see
   below); sort that out first.
2. Make the change and run the task again.
3. Read `git diff spec/route_snapshots`. Every changed division is one the change moved,
   whether or not it was meant to.
4. Commit the new files with the change, and explain each changed division in the pull request.

### Counting the changes (optional)

`git diff` shows every change. When there are many, this counts them by field and by routing
decision, with the divisions under each, ready to paste into the pull request and explain group by
group:

```bash
bin/rake ai:route_snapshot_changes                # the files on disk against the last save
bin/rake ai:route_snapshot_changes AGAINST=main   # against another branch or save
```

What it prints looks like this (an illustration, not a real run):

```
2026: 2 of 910 divisions changed, compared with HEAD
- mover.name changed in 2: senate_2026-07-01_1, senate_2026-09-17_1
- Routing constrained 2, 29 (SECOND_READING_NUANCE) became deterministic 29 (SECOND_READING_QUESTION) in 1: ...
- Hansard changed for 1 day: senate/2026-09-17 (proof, now final)
```

It only reads, and says nothing `git diff` doesn't: use whichever you prefer.

### When the files change with no code change

Two runs of the same code on the same Hansard and database give identical files. A difference with
no code change means one of those changed: Parliament replaced a proof Hansard with the final one,
the parser was updated, or divisions were loaded or reloaded. The task names the Hansard days that
changed, for example `senate/2026-09-17 (proof, now final)`, from the fingerprints at the top of the
file. Commit that rerun on its own, saying why, before any code change, so every change to these
files has one cause.

## The top of each file

`settings.yml`'s `parliaments` lists the first sitting day of each Parliament, which is how each
block gets its Parliament number. `hansard_days`, at the top of each year's file, lists every
sitting day of Hansard that year's divisions read, including earlier days the look-back opened:

| Field | What it is |
|---|---|
| `version` | `final`, `proof` or `unknown`: how the parser marked the day (`proof="0"`, `proof="1"`, or not at all) |
| `fingerprint` | The first 16 characters of the SHA-256 of the day's file as published. Any change to the file changes it |

## Reading a block

Each division is keyed by house, date and number (`senate_2026-09-17_1`), never a database id, so
the keys are the same in every copy of the database.

| Field | What it is |
|---|---|
| `facts` | What Hansard records about the vote: time, result, counts (tellers included), bills |
| `parliament` | The Parliament the division was in, from `settings.yml` |
| `hansard` | The version of the day's Hansard: `final`, `proof` or `unknown` (empty when there is none) |
| `hansard_read` | The sitting days whose Hansard Stage 1 read for this division: its own, and each earlier day the look-back opened. A change to any of them in `hansard_days` can change this block |
| `hansard_division` | The `<division>` element in the ParlParse XML that Stage 1 matched |
| `source` | `hansard_xml`, or `division_record` when no XML matched and the stored motion was used |
| `heading` | The Hansard heading over the division |
| `context_level` | How much debate Stage 1 gathered (`subdebate` unless widened) |
| `route` | Stage 2's decision: `mode` (`deterministic` settled, `constrained` a shortlist, `advisory` only a default), `template`, `allowed`, `forbidden`, the `rule` that matched and its `reason` |
| `question` | The question the division decided: `routed_on` (the sentence Stage 2 routed on), the chair's statement putting it, who put it and when, the parts left out of a divided question, and whether the question only points at a motion (`by_reference`) or is itself the whole motion (`states_motion`) |
| `motion` | The terms the division decided: whether Stage 1 found them, where (`mover_speech` or `chair_statement`), the "I move" words, and the terms |
| `mover` | Who moved it, and how Stage 1 found them (`found_by`), with their speech |
| `circulation` | Amendments the chair put that nobody moved in the chamber, and who circulated them |
| `proposer` | Who proposed a matter of urgency someone else moved |
| `closed_template` | For a closure, the template of the business it cut short |
| `followup` | For a closure, the division that then put the question |
| `speeches` | How many speeches the packet holds, beside the division and from earlier in the debate |
| `earlier_debate` | The earlier sitting days those came from |
| `limitation` | The chair saying a limitation of debate's time had expired, when that is why the question was put |
| `warnings` | Why the speeches beside the division may not be the debate about it |
| `error` | Instead of all the above, when Stages 1 or 2 failed on the division |

Text over 40 words is shown as its first 20 words, its word count, its last 20 words and the start
of a SHA-256 hash of the whole, so a change anywhere in it changes the line. Shorter text is in full.

Facts the database derives later, such as rebellions and turnout, are left out, so a change to them
never shows up as a change in what Stages 1 and 2 decided.
