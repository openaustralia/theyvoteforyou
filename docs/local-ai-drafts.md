# Drafting division summaries with a local model

`rake ai:draft_local` drafts AI division summaries with a model running on your own computer instead of Bedrock. It
works newest first, one sitting day at a time, and writes one file per division into `local_runs/`. You zip the
model's folder and hand it to someone at They Vote For You to upload (#1815). Nothing is published from a draft
until an editor has reviewed it in the division edit form.

How the pipeline itself works is in `app/services/division_summary_pipeline/ARCHITECTURE.md`. Why the files are named
the way they are is in `docs/adr/0007-local-drafts-named-after-division-url.md`.

## Before you start

1. Set up the app as the README describes, as far as `bundle exec rake db:setup`. The task itself doesn't need
   Elasticsearch running.
2. Load the members once:

   ```
   bundle exec rake application:load:members
   ```

   You don't need to load any divisions. The task loads each sitting day as it reaches it.

## Choose a model

Use a model and quantisation that have been tested with the pipeline. These are the results for the 10 divisions of
17 September 2026 on 1 October 2026, on the machine they were tested on:

| Model | Quantisation | Drafts saved (of 10) | Average minutes per saved draft |
|-------|--------------|----------------------|---------------------------------|
| Qwen3.6-35B-A3B | UD-Q4_K_M | 9 | 3.0 |
| gemma-4-12B-it-QAT | Q4_0 | 9 | 3.7 |
| Qwen3.5-9B | Q4_K_M | 8 | 3.8 |
| Qwen3.8-Flash-Next | UD-Q2_K_XL | 9 | 16.5 |

"Saved" means the pipeline produced a draft, not that the draft was right. Those drafts were made without the day's
Hansard, from the division records alone. Run again with the Hansard on 12 October 2026, Qwen3.6-35B-A3B drafted 12
of that day's 13 divisions, in about 3 minutes each (1 to 9 minutes).

- **Recommended:** Qwen3.6-35B-A3B at UD-Q4_K_M.
- **Use Q4 or higher.** The one model tested below Q4 was about five times slower.
- **Don't choose by size alone.** Qwen3.6-35B-A3B is a mixture-of-experts model that uses about 3B parameters for
  each token, so a model's total size doesn't predict how well or how fast it drafts.
- **Anything else is untested,** including Qwen3.8-27B. Try it on the 17 September 2026 divisions and compare before
  relying on it.

## Start a model server

Start the server yourself before running the task; the task never starts or stops it. Any server with an
OpenAI-style chat API works: llama.cpp's `llama-server`, Ollama, LM Studio or vLLM.

The setup the recommended model was tested with, using `llama-server`:

```
llama-server \
    -m /path/to/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
    --ctx-size 131072 \
    --cache-type-k q8_0 \
    --cache-type-v q8_0 \
    --reasoning-budget 8192 \
    --reasoning-budget-message "I have thought enough. I will now give my final JSON answer." \
    --host 127.0.0.1 \
    --port 8080
```

Change the model path to suit your machine, and add a `--device` flag if you need to choose a GPU. Long debates need
the large context size.

## Tell the task where your server is

```
cp config/local_model.yml.example config/local_model.yml
```

Then edit `config/local_model.yml`. It's ignored by git, because it describes your own machine. The example file
explains each setting. For `llama-server` on its default port, the example works unchanged.

## Run it

```
bin/rake ai:draft_local                                    # everything, newest first, back to 7 February 2006
bin/rake ai:draft_local HOUSE=senate FROM=2026-08-01 TO=2026-09-30
bin/rake ai:draft_local DIVISION=representatives/2026-09-17/3
```

| Option | What it does |
|--------|--------------|
| `HOUSE=representatives` or `senate` | One house only |
| `FROM=2026-08-01` | Go back to this date, the earliest one drafted. The default is 7 February 2006, the first sitting day in the Hansard data |
| `TO=2026-09-30` | Start at this date and go back from it. The default is today |
| `DIVISION=representatives/2026-09-17/3` | One division. Its full URL works too |
| `FORCE=1` | Draft divisions again even if they already have a file |
| `RETRY_FAILED=1` | Try divisions that failed before |

The task prints a line for each division as it goes, and a total at the end. At about 3 minutes a division, expect
around 20 divisions an hour.

## Stopping and carrying on

Press Ctrl-C at any time, then run the same command again later. Divisions that already have a file are skipped, so
it carries on where it stopped. A draft is only written once it's finished, so stopping never leaves a half-written
file.

If the model server stops answering, or answers that it has no model ready, the task stops too, without writing
anything for the division it was on. Start the server again, let it load its model, and run the same command.

## What you get

```
local_runs/
  local.Qwen3.6-35B-A3B-UD-Q4_K_M/
    representatives/
      2026-09-17/
        representatives_2026-09-17_3.md
  failed/
    local.Qwen3.6-35B-A3B-UD-Q4_K_M/
      senate_2026-09-17_8.md
```

- The top folder is the model's name with `local.` in front. The upload records it as the model that wrote each
  draft.
- Each file is named after its division's URL: swap each `_` for `/` and you have the end of
  `https://theyvoteforyou.org.au/divisions/`.
- Line 1 of each file is the draft's title. The rest is its description, ending with a "Reviewer Only" section that
  records how the draft was made, including the division's URL.
- Drafts that failed go in `failed/`, with the error at the top, so the model's folder only holds finished drafts.
  Every model reply is also kept under `tmp/llm_replies/`, with the prompt beside it.

`local_runs/` is ignored by git. Never commit drafts.

## Hand the drafts over

Zip the model's folder, so the zip's top folder is the model's name:

```
cd local_runs
zip -r ~/local-drafts.zip local.Qwen3.6-35B-A3B-UD-Q4_K_M
```

Send the zip to the person at They Vote For You who uploads drafts. Leave out `failed/`.

## When something goes wrong

| Message | What to do |
|---------|------------|
| Can't reach the model server | Start the server, and check `url` in `config/local_model.yml` |
| model server 503 | The server is still loading its model. Wait until it has finished, then run the same command |
| model server 404 | The server has no model by the name in `model` in `config/local_model.yml` (Ollama answers this way), or `url` ends in `/v1`, which the task adds itself |
| FROM ... is after TO ... | FROM is the earliest date and TO the latest, since the run goes back from TO |
| couldn't load this day's divisions | Usually the members aren't loaded: run `bundle exec rake application:load:members`, then run the task again. The day is tried again next time |
| model wrote 16000 tokens without finishing | The model got stuck on that division. It's in `failed/`; `RETRY_FAILED=1` tries again |

Drafted with AI assistance (Claude Code, claude-opus-5-5).
