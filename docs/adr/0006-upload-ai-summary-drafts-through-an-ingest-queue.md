# Upload AI summary drafts through an ingest queue

AI drafts of division summaries can be made on computers we don't run, such as a model on a
volunteer's computer, so they can't write to our database directly. Admins upload them as a zip. The
upload is kept, queued, and read in the background, and each file becomes a draft that an editor can
pick from. Nothing is published.

This is an experimental prototype, not a new way of working. It builds on the AI drafts in #1732 and
ADR 0005, and is tracked in #1815. How the zip is laid out was settled in
[a comment on #1815](https://github.com/openaustralia/theyvoteforyou/issues/1815#issuecomment-6120328670).

## The flow

1. In the admin panel, an admin goes to `/admin/ingests/new` and chooses a zip.
2. The zip is saved on the server's disk under `storage/ingests/<id>/` (outside `public/`, so it can't
   be fetched over the web), and an `Ingest` row with `kind = "division-summary"` records it, who
   uploaded it and its status.
3. `ProcessIngestJob` is queued. It runs on Delayed Job through Active Job, as the other jobs here do.
   There is no Sidekiq in this app.
4. The job reads the zip with `DivisionSummaryIngest`, works out which division each file is for, and
   saves an `AiDivisionSummary` against that division, linked back to the `Ingest` it arrived in.
5. An editor opens the division's edit form, picks a draft with "Use this draft", edits it and saves.
   That path already existed. Uploaded drafts appear there labelled with the model and who uploaded them.

## The zip

```
[model-name]/[house]/[yyyy-mm-dd]/[house]_[yyyy-mm-dd]_[n].md
```

- The model folder is who the draft is credited to. It is the folder that holds the house and date folders,
  so a zip made by compressing a parent folder (a researcher's `local_runs/` holding several model folders)
  still reads correctly. The first version took the first folder as the model, and read a whole zip of
  several models as one. A `local.` prefix marks drafts that didn't come from Bedrock.
- The file name alone says which division it is. Swapping `_` for `/` gives its public address. The house
  and date folders are for people browsing the zip and are not read, so one zip can hold both houses and
  the form doesn't ask for one.
- Line 1 is the draft's title, as a Markdown heading. The rest is the description.
- There is no check that the title matches the division's current title. Divisions on one sitting day
  often share a title, so such a check wouldn't catch a wrong number, and the file name already says
  which division it is.

## Rules

- **One bad file fails the whole upload.** A file for a division we don't have, a badly named file, or
  a file with no title or description means nothing is saved. Every problem found is listed on the
  upload's page, so an admin never has half a zip applied.
- **A re-upload replaces.** The same model's draft for the same division is overwritten. Drafts from
  different models sit side by side. Two files in one zip for the same model and division are an error.
- **The zip is read in memory and never unpacked to disk,** so a hostile path inside it can't write
  anywhere. A zip may hold up to 5,000 files, each up to 1 MB.
- **Deleting an upload's drafts** is one button on the upload's page. It removes the drafts and keeps the
  `Ingest` row as a record that the upload happened.
- **`kind`, not `type`.** Rails reserves `type` for single table inheritance. The column is `kind` so other
  kinds of ingest can be added later without a new table.

## In the admin panel

- `/admin/ingests` lists uploads and how each went.

## Open

- **Deploys.** `storage` is added to Capistrano's `linked_dirs` so uploads survive a deploy. This hasn't
  been deployed or tried on staging, and the server needs the folder to be writable.
- **Cleaning up.** Uploaded zips are kept after processing, so they can be examined later. There is no
  limit on how many are kept.
- **Upload size.** There is no limit on the zip's size beyond the web server's own.
- **Is it worth keeping?** If volunteer-run local models don't produce drafts editors use, this should be
  removed rather than maintained.

Decided 2026-10-14. Drafted with AI assistance (Claude Code, claude-sonnet-5-5).
