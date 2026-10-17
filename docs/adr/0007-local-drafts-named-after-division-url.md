# Local AI drafts are named after the division's URL

Drafts made with a local model (`rake ai:draft_local`) are written one file per division, named after the division's
URL on They Vote For You with `_` in place of `/`:

```
local_runs/<model id>/<house>/<yyyy-mm-dd>/<house>_<yyyy-mm-dd>_<n>.md
```

For example, `representatives_2026-09-17_3.md` is https://theyvoteforyou.org.au/divisions/representatives/2026-09-17/3.
The model id is `local.` and the model's name, e.g. `local.Qwen3.6-35B-A3B-UD-Q4_K_M`. Line 1 of the file is the
draft's title as a markdown heading; the rest is its description.

Why: the drafts are made on volunteers' machines and uploaded to the live site by someone else (#1815), so each file
has to say which division it belongs to without depending on anything else.

- Database row ids differ between machines, so they can't name a file.
- A name like `3.md` only identifies a division together with its folders, and once moved or sent on its own it could
  be any division numbered 3.
- Division titles can't identify a division either: they often repeat within a sitting day. In four end-of-session
  weeks checked (December 2008, June 2012, December 2019, November 2024), 192 of 317 divisions shared their exact title
  with another division in the same house on the same day.
- The URL already names exactly one division, and turning a file name back into it needs no lookup.

`local.` marks a draft as made on someone's own machine, whatever server ran the model. It follows the
"provider.model" style of the Bedrock model ids and can't clash with one.

## Considered options

- **`[model]/[yyyy-mm-dd]/[n].md`, with the house chosen in the upload form** (#1815 as first written). Simpler paths,
  but the house depends on a person picking the right one, one zip can hold only one house, and a file means nothing
  outside its folders.
- **A metadata block at the top of each file** (YAML front matter naming the division and model). Robust to renamed
  files, but a second format for both sides to read, and redundant once the name identifies the division.
- **`r-2026-09-17-3.md`.** Shorter, but "r" needs a lookup that the URL's own house name doesn't.
- **`llamacpp.` as the model prefix** (as first used). Wrong whenever someone runs Ollama, LM Studio or another server.

## Consequences

- Only `LocalDraftFile` knows this format, so a change agreed with the upload side changes that class and its spec.
- The house and date folders are only for browsing. The upload (ADR 0006) takes the division from the file name and
  the model from the folder that holds the house and date folders. In `local_runs/failed/<model id>/` that folder is a
  model id too, so a zip of the whole of `local_runs/` would upload failed drafts as if they were finished. Zip the
  model's folder on its own.
- Failed drafts are written to `local_runs/failed/<model id>/`, outside the folder that is zipped and handed over.
- A run skips divisions whose file already exists, so files left in an older layout would be drafted again after a
  format change unless moved.

Proposed 2026-10-12 on #1815 and agreed there on 2026-10-14; the upload side is ADR 0006. Drafted with AI assistance
(Claude Code, claude-opus-5-5).
