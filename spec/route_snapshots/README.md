# Routing snapshot

They Vote For You's AI summary pipeline starts with two steps that use fixed rules, not AI.
**Stage 1** reads a division's Hansard (the official record of what was said in parliament) and
finds the question that was voted on, the motion and who moved it. **Stage 2** uses what Stage 1
found to decide which summary template fits the vote.

This folder holds a record of what those two steps find and decide for every division: one entry
per division, one file per calendar year (`2025.yml`, `2026.yml`). Each file covers the whole year,
or the current year up to the day it was written. The files are written by
`bin/rake ai:route_snapshot`, and the code is in `app/services/division_summary_pipeline/snapshot/`.

The tests check that each rule works on the example it was written for. These files show what the
rules do across every real division, and so what else moves when someone changes a rule. The files
saved in git are the expected result: a change to Stage 1 or Stage 2 is saved together with the
files it changes, and its pull request explains every division that changed.

## Running it

```bash
bin/rake ai:route_snapshot                  # every year that already has a file here
bin/rake ai:route_snapshot YEARS=2026       # one year
bin/rake ai:route_snapshot YEARS=2024-2025  # several years
```

With no `YEARS=`, it rewrites every year file already in this folder. `YEARS=` writes just those
years, which is also how a new year's file is started; save a new year's file as a change of its own.
A year that hasn't begun is refused. It uses no AI model and never changes the database.

What a run does:

1. **Checks the database is complete.** Before writing anything, it goes through every day of the
   years asked for, in both houses, and checks the database holds every division that day's Hansard
   records. If any are missing, it stops, lists the days and prints the command that loads them, for
   example `bin/rake "application:load:divisions[2025-01-01,2025-12-31]"`. The first check of a year
   asks about every day it hasn't seen yet: a few hundred requests that take a minute or two.
2. **Writes each year's file.** It reads each division from the database and its Hansard from
   `tmp/hansard_xml/`, and runs Stages 1 and 2 on it.
3. **Warns about changed Hansard.** It lists any day whose Hansard has changed since that year's file
   was last written (see "When the files change with no code change").

If any day's Hansard can't be downloaded, for example because the internet connection dropped, it
stops without writing that year's file and names the day. Run it again once the connection is back.

### The local copy of Hansard

Each sitting day's Hansard is downloaded once, from the same place the nightly loader gets it, and
kept in `tmp/hansard_xml/` exactly as published, so every run reads the same Hansard. A day with no
Hansard (parliament didn't sit) is remembered with an empty `.missing` file and not asked about
again, except:

- a day less than 14 days old, whose Hansard may not be published yet, is asked about again on every
  run
- a day the database has divisions on is asked about again, because those divisions were loaded
  from its Hansard

To get a newer version of a day, such as the final version of a day kept as a proof, delete that
day's files from `tmp/hansard_xml/` (or the whole folder) and run again.

The older local drafting tools save a reworded copy of Hansard in the same folder. If you've used
them, delete `tmp/hansard_xml/` before your first run, so the snapshot downloads the files as
published.

## The routine for a change to Stage 1 or Stage 2

1. Before changing anything, run the task. `git diff spec/route_snapshots` should show nothing. If it
   shows changes, they come from your Hansard or your database, not the code (see below); sort that
   out first.
2. Make the change and run the task again.
3. Read `git diff spec/route_snapshots`. Every changed division is one the change moved, whether or
   not it was meant to.
4. Save (commit) the new files with the change, and explain each changed division in the pull
   request.

### When the files change with no code change

Two runs of the same code on the same Hansard and database give identical files. A difference with
no code change means one of those changed:

- **Hansard:** Parliament replaced a proof with the final version, or the program that turns Hansard
  into the files the site reads (the parser) was updated. The task names the days whose Hansard
  changed, for example `senate/2026-09-17 (proof, now final)`, from the fingerprints at the top of
  the file.
- **The database:** divisions were loaded or reloaded, which can change their stored details and the
  vote counts worked out from them, or member records changed, which can change a mover's name or
  party.

Save that rerun on its own, saying why, before any code change, so every change to these files has
one cause.

## The top of each file

`hansard_days`, at the top of each year's file, lists every sitting day of Hansard that year's
divisions read, including earlier days Stage 1 looked back to:

| Field | What it is |
|---|---|
| `version` | `final`, `proof` or `unknown`: how the parser marked the day (`proof="0"`, `proof="1"`, or not at all) |
| `fingerprint` | A short code worked out from every character of the day's file as published (the first 16 characters of its SHA-256 hash). Any change to the file gives a different code |

## Reading an entry

Each division's entry is named by house, date and number (`senate_2026-09-17_1`), never a database id
number, so the names are the same in every copy of the database.

| Field | What it is |
|---|---|
| `facts` | What the database records about the vote, worked out from the votes loaded from Hansard: time, result, whether it was tied, the counts (tellers included) and the bills, in alphabetical order |
| `hansard` | Whether the day's Hansard is `final`, a `proof` or `unknown` (empty when there is none) |
| `hansard_read` | The sitting days whose Hansard Stage 1 read for this division: its own, and each earlier day it looked back to. A change to any of them in `hansard_days` can change this entry |
| `hansard_division` | The id of the division in that day's Hansard file that Stage 1 matched |
| `source` | `hansard_xml`, or `division_record` when no division in the Hansard file matched and the motion stored in the database was used |
| `heading` | The Hansard heading over the division |
| `context_level` | How much of the debate Stage 1 gathered (`subdebate` unless widened) |
| `route` | Stage 2's decision: `mode` (`deterministic`: a rule settled the template; `constrained`: a shortlist the AI picks from; `advisory`: only a default the AI may change), `template`, `allowed`, `forbidden`, the `rule` that matched and its `reason` |
| `question` | The question the division decided: `routed_on` (the sentence Stage 2 based its decision on), the chair's statement putting it, who put it and when, the parts left out when a complicated question was split up (`divided`), and whether the question only points at a motion moved earlier (`by_reference`) or spells out the whole motion itself (`states_motion`) |
| `motion` | The words of the motion the division decided: whether Stage 1 found them, where (`mover_speech` or `chair_statement`), the "I move" words, and the motion itself |
| `mover` | Who moved it (name and party from the database's member records when Stage 1 matched a member, otherwise the name as Hansard gives it), how Stage 1 worked out who it was (`found_by`), and their speech |
| `circulation` | Amendments handed out in writing and put to the vote without being moved in the chamber, and who circulated them |
| `proposer` | Who proposed a matter of urgency that someone else moved |
| `closed_template` | For a closure (a vote to end the debate and vote now), the template of the business it cut short |
| `followup` | For a closure, the division that then put the question |
| `speeches` | How many speeches Stage 1 collected: just before the division, and from earlier in the debate |
| `earlier_debate` | The earlier sitting days those came from |
| `limitation` | The chair saying a time limit on debate had run out, when that is why the question was put |
| `warnings` | Why the speeches just before the division may not be the debate about it |
| `error` | Instead of all the above, when Stages 1 or 2 failed on the division |

Text over 40 words is shown as its first 20 words, its word count, its last 20 words and a hash (a
short code worked out from the whole text), so a change anywhere in it changes the line. Shorter
text is in full.

Figures the site works out later, such as rebellions and turnout, are left out, so a change to them
never shows up as a change in what Stages 1 and 2 decided.
