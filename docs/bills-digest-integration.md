# Bills Digest integration: current state and open questions

Status as at 20 September 2026. Nothing is decided yet. This records what the
`{{digest_section}}` placeholder does today, what was found when we looked into filling it, and
what someone picking this up needs to know before writing any code. Once a decision is made it
should become an ADR in `docs/adr/` and this file should shrink to a pointer.

Drafted with AI assistance (Claude Opus 5) from a working session, then reviewed by hand. The
verification status of each claim is marked below, because some of it could not be checked
directly.

## What happens today

Bill templates 1 to 7 in `app/services/division_summary_pipeline/templates/` carry a
`{{digest_section}}` placeholder under an `### About the Bill` heading.

`DivisionSummaryPipeline::TemplateCompiler` resolves it three ways, in order:

1. A pre-formatted `digest_section` string, passed as a keyword to `TemplateCompiler.compile` or
   present on the division data. Used verbatim.
2. Otherwise, `digest_key_points` (an array) plus `digest_link` on the division data, which it
   formats as `According to the [Bill Digest](LINK):` followed by `> * point` lines.
3. Otherwise, the literal blockquote `> No Bill Digest found.`

**Branch 3 always runs.** `DivisionSummarizer#summarize_with` passes `digest_section: nil`, and
nothing anywhere sets `digest_link` or `digest_key_points`. There is no fetcher, no API client, no
scraper and no database column. Every compiled summary currently renders:

```markdown
### About the Bill

> No Bill Digest found.
```

Branches 1 and 2 are an unused seam, covered by two specs in
`spec/services/division_summary_pipeline/template_compiler_spec.rb` that supply the data by hand.
The wording is fixed by `TEMPLATES.md`, the original template design document.

## Why it is not wired up

Three separate obstacles. Any one of them is enough to stop a naive implementation.

### 1. APH blocks automated clients, and OAF's access is a negotiated arrangement in another repo

*Verified.* Plain automated requests to `www.aph.gov.au` and `parlinfo.aph.gov.au` return HTTP 403,
including for `/robots.txt`. Their terms of use and robots directives could not be read at all by
an ordinary HTTP client.

OAF already fetches from ParlInfo, but not from this application. It happens in
[`openaustralia-parser`](https://github.com/openaustralia/openaustralia-parser), in
`lib/aph_mechanize_agent.rb`, whose comment reads:

> We've been kindly given a special user agent to use so that our traffic isn't blocked by the
> application firewall of aph.gov.au.

That file pins the APH-supplied user agent string, retries 403, 429, 502, 503 and 504 with
exponential backoff starting at 5 seconds over 5 attempts, and `hansard_parser.rb` caches fetched
XML to `origxml/` so re-runs do not re-fetch. The comment links to a Missive thread as the record
of the arrangement. The user agent string is not ours to change or "improve": it is what APH asked
OAF to send.

Two consequences:

- A fetcher in this repo would either be blocked, or would need that user agent copied into a
  second codebase, which silently extends an arrangement made for the Hansard pipeline to a new
  and different use. That is a conversation with APH, not a code change.
- It also matches how this app is built. Every outbound request here goes to an OAF-controlled
  host: `config.xml_data_base_url` is `data.openaustralia.org.au`, and the Mechanize loaders in
  `app/lib/data_loader/` only fetch member images from `openaustralia.org.au`. Nothing in this
  Rails app touches `aph.gov.au`. Scraping belongs in `openaustralia-parser`, which publishes to
  `data.openaustralia.org.au`, which this app loads from.

### 2. The licence is more restrictive than the code comment claims

*Verified by web search, not by reading the APH page directly, which returns 403 to automated
clients. Worth confirming in a browser before anything ships.*

Parliamentary Library publications, including Bills Digests, are published under **Creative Commons
Attribution-NonCommercial-NoDerivatives 3.0 Australia**, with the Commonwealth Coat of Arms and
third-party material excepted. The Library specifies an attribution format: author(s), title,
series name and number, publisher, date.

This makes the comment currently at `template_compiler.rb` (step 5, "Digest section") wrong, and
wrong in the risky direction. It says the digest "can be quoted without attribution problems".
Under BY, attribution is required, and a bare `[Bill Digest](LINK)` link is probably not the
specified format. **This comment should be corrected regardless of what is decided about the
integration.**

The harder part is **NoDerivatives**. Passing digest content through an LLM, or paraphrasing key
points into generated prose, is derivative-shaped. The current design is about the safest possible
shape for this: verbatim key points in a blockquote, under a link, compiled at stage 5 where no AI
runs. But "probably acceptable" is doing real work in that sentence, and ND plus an AI pipeline is
exactly the combination that needs a human decision rather than an assumption.

NonCommercial is likely fine for a registered charity, but it is still a licence call.

### 3. The available feed does not solve the lookup problem

*Inferred from URL parameters, not verified: the feed could not be fetched.*

A candidate discovery source is the ParlInfo RSS feed for the Bills Digest Service, supplied during
the working session:

```
https://parlinfo.aph.gov.au/parlInfo/feeds/rss.w3p;orderBy=date-eFirst;page=0;query=Source%3A%22Bills%20Digest%20Service%22;resCount=Default
```

Individual digests appear at URLs of the form
`.../search/display/display.w3p;query=Id%3A%22legislation%2Fbillsdgs%2F<id>%22`, and swapping
`display` for `displayPrint` gives a cleaner page.

The parameters say `orderBy=date-eFirst` and `page=0`, so this is a feed of *recently published*
digests. The actual problem is "given this division, on this bill, find that bill's digest",
including for divisions from years ago. A recency feed provides neither historical coverage nor a
bill-to-digest mapping. That still needs search queries and fuzzy matching on bill titles, which is
the difficult part and the part that should be done once and cached, not per summary.

So the feed is a reasonable ongoing signal for building and maintaining an index. It is not a
lookup API the summariser can call.

## Recommendation from the working session

Build the real integration in `openaustralia-parser`, publishing a bill-to-digest index to
`data.openaustralia.org.au` that this app loads like any other data. Do not put a live APH fetch
inside `DivisionSummarizer`.

In the meantime, make the gap actionable rather than silent. The pipeline's output is a draft for a
human, so the fallback can carry an instruction to the person reviewing it, roughly:

```markdown
### About the Bill

**[EDITOR TODO: Bills Digests are not yet loaded automatically. Search the
[Bills Digests index](https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Digests)
for "<bill name>". If there is a digest, replace this paragraph with its key points and link. If
there is not, delete this paragraph and the heading above it.]**
```

Points raised about that wording:

- Link the browsable Bills Digests index rather than the RSS feed, since the feed will not contain
  digests for older divisions. A pre-filled ParlInfo search URL carrying the bill name would be
  better, but one needs to be built and tested in a browser first rather than invented.
- Use "Bills Digest", the official APH name, in editor-facing text so the right term gets searched.
  The published wording in `TEMPLATES.md` uses the singular "Bill Digest", which is a separate
  inconsistency already present.
- Say what to do in both outcomes, including deleting the heading, or orphan "About the Bill"
  headings will accumulate.
- Do not print a bill name that came from the LLM. `TemplateCompiler` computes
  `bill_name = raw[:bill_name].presence || extraction.topic`, so when a division has no linked bill
  it falls back to a model-derived topic. Telling an editor to search APH for a model's guess
  reintroduces an unverified claim into the output, which is what stages 3 and 4 exist to prevent.
  Only include the search hint when `raw[:bill_name]` is genuinely present.
- Make it visually unmistakable as scaffolding. Nothing in the pipeline can publish itself, but a
  person copies drafts into the WikiMotion form by hand, and a plain sentence is easier to miss
  than a bold bracketed block.

Changing the fallback also means updating `TEMPLATES.md`, the fallback spec in
`template_compiler_spec.rb`, and the golden fixture
`spec/fixtures/division_summaries/test_1/expected_output.md`. The fixture is the one people forget.

## Needs sign-off before anything ships

Both are outward-facing and are not developer calls:

1. Extending OAF's negotiated APH access to a second codebase and a new use case.
2. Republishing CC BY-NC-ND material through an AI summary pipeline, and what attribution the
   rendered section must carry.

## Still to verify

- The Bills Digest licence and attribution format, read directly from aph.gov.au in a browser.
- What the RSS feed actually returns, and whether a ParlInfo search URL can be constructed that
  reliably finds a digest from a bill title.
- Whether APH would extend the existing user agent arrangement to this use, and who at OAF holds
  that contact.

## Where the code seams are

- `app/services/division_summarizer.rb`, the stage 5 call, marked PLACEHOLDER in a comment. The
  single point where digest data would be passed in.
- `app/services/division_summary_pipeline/template_compiler.rb`, step 5, which turns
  `digest_section` / `digest_key_points` / `digest_link` into markdown.
- `app/services/division_summary_pipeline/ARCHITECTURE.md`, "Placeholders waiting for an
  integration", which describes the same seam from the code's point of view.
