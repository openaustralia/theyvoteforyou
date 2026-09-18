# Division Summary Pipeline

This directory contains the 5-stage modular AI division summary pipeline for They Vote For You.
`ARCHITECTURE.md` (this file) is its single explanation document: what it is, how each stage works,
how it reuses the rest of the app rather than duplicating it, the template catalogue, and the
history of the port and review passes that produced it.

**Status: first port complete; integration review complete; second review pass complete; harness
hardening and template-consistency pass complete (section 13, third review pass).** The second
review pass ran the pipeline for real against the evaluation fixtures and fixed what that surfaced
(see "Review findings and fixes" below). The remaining unchecked items in the work checklist need a
machine with the full development environment; section 16 explains what can be verified without
one, and section 17 is the checklist for wiring the pipeline to the live systems (Bedrock
credentials, database, Hansard XML source, and the still-empty integration points).

## 1. Problem statement and motivation

Publishing objective, plain-English summaries of Australian parliamentary divisions is essential
for public understanding. Hand-writing them for thousands of divisions is impossible for a small
team, but using off-the-shelf generative AI to draft them introduces serious pitfalls:

1. **The Guillotine Trap**: When the government limits debate under a "Limitation of Debate"
   heading, all subsequent votes on substantive bill amendments fall under that heading. Naive
   models read the heading and misclassify substantive amendments as procedural guillotine motions.
2. **Hallucination & Lack of Provenance**: Generative models frequently invent facts, attribute
   claims never made, or hallucinate voting counts.
3. **Tone and Formatting Instability**: LLMs tend to generate inconsistent markdown formatting,
   partisan adjectives, or speculative conclusions.

## 2. The core design

The pipeline treats the system as a **symbolic program around a probabilistic semantic sensor**:

- **Deterministic code** manages structure, voting data, debate retrieval, procedural trap
  handling, provenance assertions, and template injection.
- **The LLM is a Semantic Extractor**: it reads Hansard context and extracts predefined variables
  into strict JSON with verbatim evidence quotes.
- **The LLM never writes the published summary prose.**

## 3. The five stages

```text
                       EXISTING TVFY / OAF DATA
                                  │
          Division (ActiveRecord)   ──┐
          (id, date, house, number,   │  same identity DataLoader::Debates
           votes, bills, rebellions)  │  used to create this Division row
                                      ▼
                     DataLoader::Debates / DebatesXml / DivisionXml
                     (app/lib/data_loader/ - the existing ParlParse XML
                      loader used nightly by application:load:divisions)
                                  │
                                  ▼
               [1] ContextBuilder
                   Thin adapter, not a second parser: finds the matching
                   DataLoader::DivisionXml by divnumber and reads its
                   #operative_question / #context_speeches / #name
                   (Progressive tiers: Immediate, Subdebate, Sitting Day)
                             │
                             ▼
               [2] ProceduralRouter
                   Procedural State Machine
                   Deterministic procedural traps (closure, member heard, etc.)
                   Guillotine trap lockout & template candidate fencing
                             │
                             ▼
               [3] SemanticExtractor
                   Constrained LLM extraction via Bedrock
                   Strict JSON schema (topic, operative motion, mover claims, evidence)
                   Never writes published prose
                             │
                             ▼
               [4] ProvenanceValidator
                   Zero-hallucination assertion: evidence quote in source text
                   Schema validity & constraint checks
                             │
                             ▼
               [5] TemplateCompiler
                   Injects verified facts & extractions into 1 of 23 templates
                   Produces final publication-ready Markdown
                             │
                             ▼
                     DivisionSummarizer
                     (Orchestrator Result)
                             │
                             ▼
                     AiDivisionSummary
                     (Existing ActiveRecord model)
```

### Stage 1: Context Builder (`DivisionSummaryPipeline::ContextBuilder`)

- Connects the TVFY `Division` record (`date`, `house`, `number`) to the official OpenAustralia
  ParlParse XML **by reusing the existing loader**, not by fetching or parsing it again. See
  "Relationship to the existing Hansard loader" below - this is the single most important design
  constraint on this stage.
- Extracts the operative question (the wording actually being decided, e.g. `"That the question be
  now put."`) immediately preceding the vote.
- Gathers debate speeches at progressive context tiers:
  - **Level A (Immediate)**: Speeches immediately before the division.
  - **Level B (Subdebate)**: The full subdebate leading up to the vote (default).
  - **Level C (Sitting Day)**: Speeches across the sitting day when prior debate context is
    required.

### Stage 2: Procedural Router (`DivisionSummaryPipeline::ProceduralRouter`)

- Evaluates the Speaker's Question against parliamentary rules.
- Catches immediate deterministic procedural traps in code (Member No Longer Heard, Closure of
  Debate, Suspension of Standing Orders, First Reading, Disallowance, Production of Documents,
  Censure, Urgency, etc.).
- Defeats the Guillotine Trap by locking out Template 18 when an amendment or substantive bill vote
  occurs under a "Limitation of Debate" heading.
- Narrows the candidate templates for ambiguous stages.

### Stage 3: Semantic Extractor (`DivisionSummaryPipeline::SemanticExtractor`)

- Prompts AWS Bedrock (or a stubbed client in testing, or an injected `llm_caller`) strictly for
  JSON matching `ExtractionPayload.json_schema`; the orchestrator keeps the raw response so it can
  be stored on the `AiDivisionSummary` record.
- The system prompt (`SemanticExtractor#system_prompt`) carries the full 23-template catalogue, the
  non-partisan neutrality rule, the Australian English constraint and the prototype's "moved
  formally" claims fallback, ported from `LLM_Divisions/tvfy/llm/prompt.md`.
- Extracts:
  - `template_id` (1 to 23, conforming to router candidates)
  - `topic` (concise 2-5 words)
  - `motion_text` (exact operative wording)
  - `mover_claims` (array of functional points, each paired with an `evidence` quote from Hansard)
  - `declines_second_reading` (boolean for Template 2)
  - `sufficient_context` (boolean flag for progressive context fallback)

### Stage 4: Provenance Validator (`DivisionSummaryPipeline::ProvenanceValidator`)

- Mechanically checks that every evidence quote in `mover_claims` exists verbatim in the Hansard
  debate context.
- Enforces schema rules and template-specific constraints.
- Rejects unsupported claims and flags them for human editorial review rather than publishing
  unverified interpretations.

### Stage 5: Template Compiler (`DivisionSummaryPipeline::TemplateCompiler`)

- Injects authoritative TVFY database facts (official vote tallies, rebellions, member links,
  dates, times) and validated extractions into one of 23 human-curated Markdown templates.
- Substitutes variables deterministically without AI involvement.

## 4. Relationship to the existing Hansard loader

**This is the single most important architectural constraint on this feature, so it gets its own
section rather than being buried in Stage 1's bullet points.**

They Vote For You already has a working, nightly-run pipeline that turns Australian Hansard into
`Division` records:

```
rake application:load:divisions[from,to]
  -> DataLoader::Debates.load!(from_date, to_date)
       -> DataLoader::Debates.fetch_xml_document(house, date)
            (HTTP GET #{xml_data_base_url}scrapedxml/#{house}_debates/#{date}.xml - the
             ParlParse-format XML the openaustralia-parser project publishes)
       -> DataLoader::DebatesXml.new(doc, house).divisions
            (XPath search for every <division> element, wrapping each in a DivisionXml)
       -> for each DivisionXml: reads divdate/divnumber/time, walks previous_element
          siblings back to the last <major-heading>/<minor-heading> for the debate title
          and to the last <p pwmotiontext> (or the preceding <speech> elements) for motion text
       -> Division.create!(date:, number:, house:, name:, motion:, debate_url:, debate_gid:, ...)
```

A `Division` row's `date`, `number`, `house`, `name` and `motion`/`original_motion` are **not**
independently-sourced facts - they are the literal output of parsing the same ParlParse
`<division>` element this feature needs wider context around. Two independently-written parsers of
the same fragile, undocumented, sibling-walk-based XML structure (truncation rules, HTML-entity
handling, missing-heading edge cases) would be exactly the kind of thing that drifts silently: a
future change to one has no reason to be mirrored in the other, and a Hansard edge case could be
interpreted two different ways with no test ever catching the mismatch.

So `DivisionSummaryPipeline::ContextBuilder` is a thin adapter, not a second loader:

1. `DataLoader::Debates.fetch_xml_document(house, date)` - the exact method `application:load:
   divisions` itself calls - fetches the day's XML.
2. `DataLoader::DebatesXml.new(doc, house).divisions` - the exact existing parser - turns it into a
   list of `DataLoader::DivisionXml` objects, one per `<division>` element, in document order.
3. `ContextBuilder` finds the one matching this `Division` by `divnumber` (the same identity
   `DataLoader::Debates.load!` itself keys `Division.find_or_initialize_by(date:, number:, house:)`
   on), falling back to clock time or `debate_gid` only if the number is missing or ambiguous. It
   does **not** implement its own weighted or fuzzy matching - a division either is or isn't the one
   with this `divnumber` on this day.
4. It reads three small, additive public methods added to `DataLoader::DivisionXml` for this
   feature - `#operative_question`, `#context_speeches(level)` and the pre-existing `#name` - all
   built from the exact same private sibling-traversal helpers (`pwmotiontexts`,
   `previous_speeches`) `#motion` already uses, plus one Nokogiri `preceding::speech` XPath call
   for the widened sitting-day tier. No new document-walking logic was written; the new methods
   just expose more of what the existing parser can already compute.

If Hansard XML can't be fetched or no `<division>` in it matches (offline tests, a transient fetch
failure, or Hansard XML that's since disappeared from the source for an old division),
`ContextBuilder` falls back to the `Division` record's own `motion`/`original_motion` fields - a
real, database-resident, partial signal, but not a substitute for the day's XML: it's truncated at
15,000 characters, doesn't distinguish context tiers, and never includes headings the way the built
context does.

## 5. Data classification

- **Type 1: Authoritative Structured Facts** (vote counts, member details, rebellions, date,
  time): sourced exclusively from the TVFY database. Zero AI involvement.
- **Type 2: Deterministic Text** (exact motion text, Speaker's Question, bill names): sourced from
  official Hansard / ParlParse XML.
- **Type 3: Semantic Nuance** (procedural stage selection, mover's arguments, whether an amendment
  declines a second reading): extracted by the LLM as structured JSON with mandatory verbatim
  quotes.

## 6. Provenance enforcement

Every claim made by the mover must have an `evidence` field containing an exact quote from the
Hansard context. The `ProvenanceValidator` mechanically asserts that the evidence appears in the
source: normalised evidence `include?` normalised Hansard context, where normalisation swaps curly
for straight quotes, replaces em/en dashes with hyphens, collapses whitespace and lowercases. For
quotes longer than 80 characters it tolerates minor mid-quote formatting breaks by matching the
first and last 8 words instead of the whole quote. Any claim that fails this mechanical
verification is rejected and flagged for human review rather than published.

## 7. The 23 template catalogue

The templates reside in `app/services/division_summary_pipeline/templates/`. The file name carries
the catalogue number and name; the text of each file is only publishable content (the `### N. Title`
headings the prototype carried over from `TEMPLATES.md` were removed in the second review pass so
they can never leak into compiled output - this table is where the number-to-name mapping lives):

1. `1_first_reading.md` - First Reading
2. `2_second_reading_amendment.md` - Second Reading Amendment
3. `3_in_committee_amendment_senate.md` - In Committee Amendment (Senate)
4. `4_consideration_in_detail.md` - Consideration in Detail (House of Representatives)
5. `5_federation_chamber_report.md` - Federation Chamber Report
6. `6_passing_a_bill.md` - Passing a Bill (Second or Third Reading)
7. `7_agreeing_to_amendments_message.md` - Consideration of a Message
8. `8_production_of_documents.md` - Order for the Production of Documents
9. `9_disallowance_motion.md` - Disallowance Motion
10. `10_censure_motion.md` - Censure Motion
11. `11_estimates_committees.md` - Budget Estimates Committees
12. `12_select_committee.md` - Establishing a Select Committee
13. `13_committee_referral.md` - Committee Referral
14. `14_selection_of_bills_committee.md` - Selection of Bills Committee Report
15. `15_general_motion.md` - General Motion
16. `16_matter_of_urgency.md` - Matter of Urgency (Senate)
17. `17_suspension_of_standing_orders.md` - Suspension of Standing Orders
18. `18_guillotine_motion.md` - Limitation of Debate (Guillotine)
19. `19_rearrangement_of_business.md` - Rearrangement of Business
20. `20_withdrawal_of_business.md` - Withdrawal of Business
21. `21_parliamentary_zone_works.md` - Parliamentary Zone Capital Works
22. `22_closure_of_debate.md` - Closure of Debate ("Question be now put")
23. `23_member_no_longer_heard.md` - Member Be No Longer Heard (House of Representatives)

## 8. Where everything lives

```text
app/services/division_summary_pipeline/     the pipeline itself (ARCHITECTURE.md explains it)
  context_builder.rb          Stage 1: adapts the existing Hansard loader into a ContextPacket
  procedural_router.rb        Stage 2: deterministic routing on the Speaker's Question
  semantic_extractor.rb       Stage 3: LLM prompt + Bedrock call, structured JSON only
  extraction_schema.rb        ExtractionPayload / ClaimEvidence value objects + JSON schema
  provenance_validator.rb     Stage 4: mechanical evidence-in-source assertions
  template_compiler.rb        Stage 5: injects validated data into the Markdown templates
  text_normaliser.rb          shared text cleaning and quote-matching normalisation
  templates/                  the 23 Markdown templates ({{placeholder}} syntax)
  ARCHITECTURE.md             this document
app/services/division_summarizer.rb         orchestrator (existing service, extended)
app/models/ai_division_summary.rb           existing output model (unchanged)
app/lib/data_loader/debates.rb              existing loader + fetch_xml_document/xml_url helpers
app/lib/data_loader/division_xml.rb         existing parser + operative_question/context_speeches
lib/tasks/ai_classification.rake            rake ai:summarize_division runs the whole pipeline
spec/services/division_summary_pipeline/    software specs + evaluation corpus
spec/fixtures/division_summaries/           evaluation fixtures (test_1, test_2)
LLM_Divisions/                              the archived Python prototype (reference only)
```

## 9. Testing and evaluation

The feature is covered by two distinct test suites:

1. **Software Tests (`spec/services/division_summary_pipeline/`)**: Unit tests for
   `TextNormaliser`, `ExtractionPayload`, `ProceduralRouter`, `ContextBuilder`,
   `ProvenanceValidator`, `TemplateCompiler`, `SemanticExtractor` and the `DivisionSummarizer`
   orchestrator.
2. **Parliamentary Evaluation Corpus (`spec/services/division_summary_pipeline/evaluation_spec.rb`)**:
   Regression test cases (`spec/fixtures/division_summaries/test_1` and `test_2`) covering a
   second-reading-amendment division and a closure-of-debate division, verifying 100% provenance
   and exact expected markdown output end to end. These use invented people, electorates and bill
   titles (not real MPs or real Hansard quotes) built in the real ParlParse `<debates>` XML shape -
   see the fictional-data note below - so growing this into a genuine corpus of real historical
   divisions, organised by procedural category, is tracked as follow-up work rather than done here.

Both fixtures' `hansard_excerpt.xml` are hand-built ParlParse `<debates>` documents in the same
shape `DebatesXml` and `DataLoader::Debates`'s own specs (`spec/lib/data_loader/`) use, since that
is what `ContextBuilder` actually parses in production - not the `<hansard><chamber.xscript>...`
APH document shape an earlier draft of this fixture set used, which no other part of the app reads.

### A note on the fictional data in these fixtures

The mover names, electorates, party links and bill titles in `test_1`/`test_2` are invented, not
drawn from a real division or a real MP's real words, in line with this repo's convention of using
fictional placeholders in specs and test data (`AGENTS.md`, "Working with AI tools") - even though
the production `Division`/`Vote`/`Member` tables this feature reads from are necessarily about real
people, since that's the whole point of They Vote For You. An earlier draft of these fixtures used
the names of real, currently sitting MPs with invented quotes attributed to them; that was
corrected during integration review rather than carried forward, since attributing invented Hansard
wording to a real named person - even in a test fixture, even for a plausible-sounding recent bill -
is exactly the kind of unverified claim `AGENTS.md`'s "Accuracy" guidance warns against.

## 10. Running it locally

The entry point is the existing rake task (`lib/tasks/ai_classification.rake`):

```bash
rake ai:summarize_division DIVISION_ID=123
```

It runs the full pipeline for one Division against every configured Bedrock model and saves each
result as an `AiDivisionSummary`, skipping models that already have a saved, error-free summary for
that Division (so a failed run can be retried). It needs AWS credentials for Bedrock in
ap-southeast-2 and divisions loaded via `application:load:divisions`. Nothing is published to the
site by this task: `AiDivisionSummary` rows are drafts for human review, like the other AI outputs
from openaustralia/theyvoteforyou#1716.

For a no-LLM dry run of stages 1, 2, 4 and 5 against a fixture, see the parliamentary evaluation
corpus in `spec/services/division_summary_pipeline/evaluation_spec.rb`.

## 11. Port history: terminology and Python-to-Ruby correspondence

The standalone Python prototype in `LLM_Divisions/` is the historical record of how the design was
worked out; it keeps its original working titles on purpose and `LLM_Divisions/ARCHIVED.md`
explains the mapping. Nothing in it is loaded, required, or executed by the Rails app.

Terminology renames applied in the port:

| Prototype working title | Shipped name |
|---|---|
| "Regex 2.0" | Semantic Extractor (`DivisionSummaryPipeline::SemanticExtractor`) |
| "The 100 IF statements" / "Procedural State Machine" | Procedural Router (`DivisionSummaryPipeline::ProceduralRouter`) |
| `HansardTextCleaner` / `clean_hansard.py` | `DivisionSummaryPipeline::TextNormaliser` |
| `DivisionValidator` | `DivisionSummaryPipeline::ProvenanceValidator` |
| `DivisionCompiler` | `DivisionSummaryPipeline::TemplateCompiler` |
| `DivisionPacketBuilder` / `DivisionPacket` | `DivisionSummaryPipeline::ContextBuilder` / `ContextPacket` |
| `ExtractionSchema` | `ExtractionPayload` (with `ClaimEvidence`) |
| `DivisionMatcher` (weighted fuzzy matcher) | deliberately not ported - see section 12 |

Python-to-Ruby correspondence, including what was not ported:

| Python (LLM_Divisions/tvfy) | Ruby (shipped) | Notes |
|---|---|---|
| `sources/hansard.py` (HansardParser) | not ported | replaced by the existing DataLoader parser (constraint 1) |
| `sources/tvfy_api.py` (REST client) | not ported | the pipeline runs inside the app; `Division` records are already here |
| `sources/bills_digest.py` | not ported | `TemplateCompiler` accepts a pre-formatted digest section; live digest sourcing is open follow-up |
| `processing/matcher.py` (DivisionMatcher) | not ported | replaced by `divnumber` identity (constraint 1) |
| `processing/clean_hansard.py` | `text_normaliser.rb` | |
| `processing/prepare_division.py` | `context_builder.rb` | |
| `processing/router.py` | `procedural_router.rb` | same rules, rule names and ordering |
| `llm/schema.py` | `extraction_schema.rb` | plus a legacy title/description payload path for compatibility with the PR #1732 prompt |
| `llm/extractor.py` | `semantic_extractor.rb` | Bedrock `converse` instead of a Python callable; an `llm_caller` lambda is still accepted for tests |
| `llm/prompt.md` | `semantic_extractor.rb#system_prompt` | |
| `validation/validate.py` | `provenance_validator.rb` | |
| `compiler/compile.py` | `template_compiler.rb` | template variables changed from `[SQUARE_BRACKETS]` to `{{mustache}}` |
| `templates/*.md` | `app/services/division_summary_pipeline/templates/*.md` | same wording, placeholder syntax converted |
| `cli.py` (index/match/route/clean/run/eval) | not ported | rake `ai:summarize_division` plus the RSpec evaluation corpus cover the operational needs |
| `tests/fixtures/test_1`, `test_2` | `spec/fixtures/division_summaries/` | rebuilt in the real ParlParse XML shape with fictional people |

## 12. Architectural constraints for future work

These constraints came out of reviewing the original porting plan against how TVFY actually gets
its data. They are the rules any future work on this feature must keep following.

1. **No second Hansard pipeline.** Australian Hansard reaches TVFY as:
   `Hansard -> openaustralia-parser -> ParlParse debates XML -> DataLoader -> Division`.
   The AI feature must consume that, not rebuild it. `ContextBuilder` therefore:
   - fetches the day's XML via `DataLoader::Debates.fetch_xml_document` (the exact method the
     nightly `application:load:divisions` run uses),
   - parses it with the existing `DataLoader::DebatesXml` / `DataLoader::DivisionXml`, and
   - finds the matching `<division>` by `divnumber`, the same identity
     `DataLoader::Debates.load!` keys `Division` records on (`find_or_initialize_by(date:,
     number:, house:)`), falling back to clock time or `debate_gid` only when the number is
     missing. No weighted or fuzzy matching is used anywhere.
   The only new parsing surface is two additive public methods on `DataLoader::DivisionXml`
   (`#operative_question`, `#context_speeches(level)`), built from the same private sibling
   traversal `#motion` already uses.
2. **`Division.motion` is not assumed sufficient.** The loader stores only the motion text (and
   truncates at 15,000 characters), so `ContextBuilder` uses the XML for wider context and falls
   back to the `Division`'s own `motion`/`original_motion` only when XML is unavailable, with that
   limitation documented.
3. **The Procedural Router must stay a router, not a second parser.** Deterministic rules catch
   obvious procedural motions and defeat the "Limitation of Debate" heading trap; everything
   genuinely ambiguous is left to the LLM inside candidate fences, and its output is then
   provenance-checked. Do not grow it toward "completely understanding Parliament" in code.
4. **Progressive context stays.** Level A (immediate speeches) -> Level B (subdebate, default) ->
   Level C (sitting day), expanded when the extractor reports `sufficient_context: false`.
5. **Two kinds of tests.** Software specs prove the code behaves as designed; the parliamentary
   evaluation corpus (`spec/fixtures/division_summaries/`) proves real-shaped Hansard flows end to
   end with 100% provenance and exact expected output. The corpus currently covers Templates 2 and
   22 with fictional people and bills (per repo policy on test data); growing it with real
   historical divisions is open follow-up work (section 15).

## 13. Review findings and fixes

### First review pass (integration review)

What was verified against the previous implementer's port:

- [x] Every new and modified Ruby file passes `ruby -c` syntax checks.
- [x] All files carry `frozen_string_literal: true`; no trailing whitespace; double-quoted strings;
      `Layout/LineLength` is disabled repo-wide so long lines are acceptable.
- [x] The orchestrator's five stages match the required execution flow and finish by saving to
      `AiDivisionSummary` via `save_from_result!` (rake `ai:summarize_division`).
- [x] Schema supports the feature (`ai_division_summaries` columns; `bills.url` used by the
      compiler); `Division` methods used by the compiler (`passed?`, `division_info`,
      `clock_time`, `aye_votes_including_tells`, `rebellions`, `bills`) all exist.
- [x] Evaluation fixtures traced by hand through the router, validator and compiler for test_1
      (Template 2, declines second reading) and test_2 (Template 22 closure): the compiled output
      matches the expected output files, and provenance holds against the fixture XML.
- [x] Template wording preserved from the prototype, with placeholder syntax converted.
- [x] No prototype-only terminology ("Regex 2.0", "100 IF statements") leaks into app/, spec/ or
      docs/.

Issues found and fixed during that pass:

1. `DivisionSummarizer#summarize_with` had a dead `if/elsif/else` (both branches identical) and
   duplicated the Bedrock call that already belongs to `SemanticExtractor`. The orchestrator now
   only orchestrates; the extractor owns the model call (`extract_raw`), and the Stage 2 router
   fallback is a simple `||=`.
2. The extractor's system prompt was a lossy condensation of the prototype's `tvfy/llm/prompt.md`:
   the 23-template catalogue, the "moved formally" claims fallback, the non-partisan neutrality
   rule and the Australian English constraint were missing. All ported in.
3. `TextNormaliser` used `CGI.unescapeHTML`, which decodes only the basic five entities, unlike the
   prototype's `html.unescape` (full HTML entity table). Swapped to the `htmlentities` gem the app
   already depends on, and the spec now asserts named-entity decoding.
4. `ProvenanceValidator` thresholds had drifted from the prototype: the long-quote window check
   used a 16-word cutoff instead of the prototype's 80-character one, and the motion first-line
   check used 25 characters instead of 20. Aligned.
5. `TemplateCompiler` treated `result: "for"` as unsuccessful even though it maps `passed` to `for`
   itself. Result handling consolidated into one list (`passed`, `agreed to`, `for`, `yes`,
   `successful`, `carried` -> "for"/successful, anything else -> "against"/unsuccessful).
6. `SemanticExtractor` had no spec at all. Added one covering the injected `llm_caller` path,
   prompt construction and the system prompt contents.
7. The rake task description still described the naive motion-only summariser; updated.
8. The documentation gained a "Running it locally" section and a pointer to the system prompt
   contents.

### Second review pass (running the pipeline for real)

The first pass could only check syntax and trace fixtures by hand: this machine has no bundle,
MySQL or AWS credentials, so nothing had ever been executed. A standalone offline harness (no
Rails, MySQL or AWS needed: the fixture XML feeds `ContextBuilder` and the fixture extraction JSON
stands in for the Stage 3 LLM response) then ran the real pipeline end to end against the
evaluation fixtures, which surfaced:

9. **`TextNormaliser` froze the shared `HTMLEntities` decoder** (`HTMLEntities.new.freeze`), but the
   gem lazily memoises its decoder instance on the first `#decode` call (`@decoder ||= ...`), so
   every entity decode raised `FrozenError` at runtime. This would have failed the whole
   evaluation suite at Stage 1; static checks could not catch it. Fixed by not freezing the
   constant, with a comment explaining why.
10. **The prototype's `### N. Title` catalogue headings leaked into compiled output.** Every
    template file began with its catalogue heading (e.g. `### 10. Censure Motion`), which flowed
    straight through `TemplateCompiler` into the published markdown. Removed from all 23 templates
    and from the two `expected_output.md` fixtures; the compiler spec and summarizer spec
    assertions were updated to assert output starts with the first content line instead. The
    number-to-name mapping now lives in the file names and the catalogue table (section 7).
11. **The orchestrator rebuilt the Hansard context packet once per model** - with the default three
    Bedrock models that meant fetching and parsing the same day's Hansard XML three times per
    division. `DivisionSummarizer` now builds the packet once per instance and shares it across
    `summarize_with_all_models`; a context expansion to the sitting day is kept for the remaining
    models.

The offline run itself also re-verified the evaluation fixtures against the real code: both
compile to an exact match with their expected output and pass provenance validation.

### Third review pass (handover-guide hardening and template consistency)

This pass worked from the site editor's handover documentation (Mackay's notes and the "Getting
Started" guide) and cross-checked every template file against `TEMPLATES.md`, the original
template document at the repository root. The handover material was used for the harness's logic,
routing and reasoning only - the templates are governed by `TEMPLATES.md`, not by the guide.

Routing (ProceduralRouter):

12. **"Member be no longer heard" was asserted regardless of chamber.** That motion is a House of
    Representatives procedure; the Senate doesn't have it. A match inside the Senate now fences
    the decision (`MEMBER_NO_LONGER_HEARD_CHAMBER_CONFLICT`, non-deterministic, candidate 23) with
    the conflict spelled out in the reason, instead of asserting a House-only template from
    possibly-wrong chamber metadata.
13. **The guillotine lockout only covered amendment questions.** Under a "Limitation of Debate"
    heading every later division - substantive bill votes included - shares the heading, so the
    lockout on Template 18 now also applies to the ambiguous second reading decision and to the
    general motion fallback, and the reason strings say the heading triggered it. The question
    itself still routes to Template 18 deterministically when it is about limiting debate.
14. **Production of documents wording.** Senate orders for the production of documents are often
    phrased around "papers" being "laid on/upon the table"; the router now tolerates those
    variants. These votes are about access to documents, never about their subject matter, so a
    missed match misroutes worse than most.
15. **Ordering rationale documented.** The catch-all procedural traps are matched before any
    subject-matter rule, deliberately: a suspension question that mentions a censure ("...as would
    prevent me from moving a censure motion") is a vote about suspending the standing orders - the
    censure division, if it happens, is a separate division. This is `TEMPLATES.md` template 10's
    own instruction ("if the division was actually on suspending standing orders ... use template
    17 instead") implemented in code.

Reasoning (SemanticExtractor system prompt):

16. **Resumed debates.** Debate is frequently adjourned and resumed, so an excerpt can start
    mid-conversation with the mover's opening speech elsewhere in the sitting day or on a previous
    day. Rule 8 now explains this, tells the model to extract only what the excerpt supports and
    to set `sufficient_context: false` with a `missing_context_clue` naming what to look for,
    rather than reconstructing a missing speech.
17. **Per-template claim scoping.** Rule 5 now scopes claims to what each vote decides: Template 8
    claims are about access to documents, never their subject matter; Template 17 claims are about
    why the rules are set aside; Template 18 claims are about the time limit; Template 9 claims
    describe what the regulation does and why it should lose legal force; Templates 22 and 23 make
    no claims about the underlying question. This matches the handover guide's central
    substantive-versus-procedural distinction at the extraction layer, so the compiler's
    deterministic template wording carries the framing instead of the model improvising it.
18. **Headings are not votes.** New rule 9 anchors extraction on the speaker's question and
    reinforces that a "Limitation of Debate" heading doesn't make every division under it a
    guillotine motion - the trap the router already defends against, now also defended in the
    prompt.

Rendering and templates (TemplateCompiler plus two template files, against `TEMPLATES.md` as the
source of truth):

19. **`digest_section` wording fixed to the original.** When a Bills Digest is found the section
    now compiles to start with exactly `According to the [Bill Digest](LINK):` (singular "Bill
    Digest", as `TEMPLATES.md` has it); the compiler had been emitting `[Bills Digest]`. The
    no-digest fallback remains the blockquote `> No Bill Digest found.` - that text comes from
    `TEMPLATES.md`'s own instruction ("If no Bill Digest is found, write here: No Bill Digest
    found."), and the header is omitted there because there is no digest left to link to.
20. **Template 8's explainer line restored to the exact `TEMPLATES.md` wording** ("This is a vote
    about access to the documents. It is not a vote about the subject the documents deal with, and
    the summary should not suggest otherwise."), and **Template 5's extra closing sentence**
    ("This formally accepts the progress made on the bill in the parallel debating chamber."),
    which `TEMPLATES.md` does not have, was removed.
21. **Template 22's follow-up link** ("the [Chamber] then voted on the question itself, which you
    can read about here (LINK to the following division)") is now rendered when a `followup_link`
    attribute is supplied on the division data; output is byte-identical to before when it isn't.
    Resolving the follow-up division is open work (section 15).
22. **Duplicated definite articles are collapsed** ("to the the Selection of Bills Committee"),
    alongside the existing indefinite-article fix; the double "the" was observed in real compiled
    output when a committee name arrived already carrying its article.
23. **Editor-guidance lines in `TEMPLATES.md` stay out of published templates, deliberately and
    consistently**: template 7's "The correct terms are Consideration of Senate Amendments..."
    note, the catch-all policy notes in templates 17, 22 and 23 ("There is an existing catch-all
    policy ... Find it and reuse it"), and template 10's "use template 17 instead" instruction are
    directions to the human editor or the pipeline, not publishable copy. The pipeline implements
    the template 10 instruction in the router (rule above); attaching catch-all policies is the
    existing human workflow, not part of this pipeline. `{{digest_section}}` is different: it is a
    placeholder for published content, not a removed instruction, and its wording contract is
    spelled out in section 17.

## 14. Work checklist

- [x] Read all `LLM_Divisions` documentation and source; understand the objective.
- [x] Review the existing TVFY AI implementation (`DivisionSummarizer`, `AiDivisionSummary`).
- [x] Review the previous implementer's port (code, specs, fixtures, docs, loader changes).
- [x] Verify the architecture constraints in section 12 are honoured.
- [x] Write the plan document (now merged into this file).
- [x] Fix orchestrator dead code; move the LLM call into `SemanticExtractor#extract_raw`.
- [x] Enrich the extractor system prompt (template catalogue, neutrality, Australian English,
      moved-formally fallback).
- [x] Swap `CGI.unescapeHTML` for `HTMLEntities`; strengthen the normaliser spec.
- [x] Align provenance thresholds with the prototype.
- [x] Consolidate result phrasing in `TemplateCompiler`.
- [x] Add `semantic_extractor_spec.rb`.
- [x] Update rake task description and documentation.
- [x] Re-run static checks (syntax, terminology grep, fixture trace).
- [x] Second review pass: fix the frozen `HTMLEntities` decoder; remove the `### N. Title`
      catalogue headings from templates, fixtures and specs; build the Hansard context packet once
      per `DivisionSummarizer` instead of once per model; run the real pipeline offline against the
      evaluation fixtures (stages 1, 2, 4 and 5) and confirm exact-match output and provenance.
- [x] Third review pass: harden routing and extraction reasoning from the editor's handover
      documentation (Senate/House chamber conflict on "no longer heard", guillotine heading lockout
      beyond amendments, production-of-papers wording, resumed-debate and per-template claim
      scoping, headings-are-not-votes rule); cross-check all 23 templates against `TEMPLATES.md`
      (digest section wording, template 5 and 8 wording, template 22 follow-up link, duplicated
      definite articles) and extend the router, compiler and extractor specs to match; re-run the
      offline evaluation fixtures (exact match, full provenance).
- [ ] Run the full test suite on a machine set up for it (see section 16); the machine used for
      this port has no bundle/MySQL, so `rspec` could not be executed here.
- [ ] One real Bedrock call against one known historical division, inspecting every stage's output
      (section 16, step 4).

## 15. Open follow-up work

Not blocking, but worth tracking as separate issues rather than silently forgetting:

- **Growing the evaluation corpus.** Two fixtures cover Templates 2 and 22 only. A fuller corpus -
  organised by procedural category (second reading, closure, amendment, first reading, censure,
  urgency, ...), each with source context, expected routing decision, expected extraction and
  expected output - would need real historical Hansard excerpts per category, hand-verified against
  the actual published Hansard record for each one (not invented, per the note above). That's real,
  ongoing effort for a small team, not a one-off task.
- **Which Bedrock model(s) to default to.** `DivisionSummarizer` currently reuses
  `DivisionPolicyClassifier::MODELS` (three models) and its `summarize_with_all_models` queries all
  three by default. That default was inherited from the classifier spike it was built alongside
  (`openaustralia/theyvoteforyou#1716`) rather than decided for this feature specifically - worth a
  deliberate call on cost/quality trade-offs before this is used to produce user-facing published
  text, rather than carrying the classifier's default forward by default.
- **Bills Digest / Explanatory Memorandum integration.** `TemplateCompiler` accepts an
  already-formatted `digest_section` string, but nothing populates it yet - out of scope unless
  asked for. The wiring contract (what a future integration must supply and the exact compiled
  wording it produces) is written up in section 17.
- **Template 22's follow-up division link.** The compiler renders
  "which you can read about here" with a link when a `followup_link` attribute is supplied on the
  division data, but nothing resolves "the division that put the underlying question" yet.
  Finding it is a deterministic lookup over same-debate divisions - a candidate for a future
  ContextBuilder extension rather than new data plumbing.
- **Template 9's regulation summary.** The template renders `{{regulation_summary}}`, which is
  currently left empty. `TEMPLATES.md` sources it from the regulation's Explanatory Statement on
  legislation.gov.au, attributed rather than neutral because the government writes it - same shape
  as the Bills Digest integration, same section 17 contract.
- **Surfacing `AiDivisionSummary` drafts in the admin panel** for the review workflow.
- **Decide whether `LLM_Divisions/` is committed to this repo as archived reference** (the
  `ARCHIVED.md` in it supports that) or kept untracked; the conversation transcripts in it are
  large and are the only reason to hesitate.
- **Reusing one fetched XML document across a batch of divisions** (observed in the second review
  pass): the orchestrator now builds the packet once per division, but a bulk run over a sitting
  day still fetches and parses the same day's XML once per division. Fine for the current rake
  task; worth revisiting if this ever runs nightly over every division of a day.
- **The extracted `speaker` field is not checked against the speakers in the Hansard context**
  (observed in the second review pass). Evidence quotes are the load-bearing provenance check and
  are verified; the speaker name is optional metadata, currently trusted from the model.

## 16. Verifying on a fully set-up machine

This machine cannot run the suite (no bundle, MySQL or AWS credentials). Run, in stages:

```bash
git status && git diff --stat          # confirm the change set is what this document describes
bundle exec rspec spec/services/division_summary_pipeline/
bundle exec rspec spec/services/division_summarizer_spec.rb
bundle exec rake                       # the full suite, as CI runs it
bundle exec rubocop --parallel
```

The evaluation corpus needs no network and no Bedrock: it injects fixture XML and a fixture
extraction, so `bundle exec rspec spec/services/division_summary_pipeline/` exercises stages 1, 2,
4 and 5 end to end offline. Stage 3 is covered by specs through a stubbed Bedrock client and an
injected `llm_caller`.

Then, only after all of that passes, one real call end to end:

```bash
rake ai:summarize_division DIVISION_ID=123
```

and inspect every stage for that division: the fetched context packet, the routing decision, the
raw model JSON, the provenance result, the compiled Markdown, and the saved `AiDivisionSummary`
row. Do not judge the feature on the final Markdown alone.

## 17. Hooking it up to live systems

The pipeline was built and reviewed on a machine with no bundle, MySQL or AWS credentials, so every
external dependency sits behind an injectable seam and nothing contacts a live system at boot or
under test. This section is the wiring checklist for whoever has the keys. Everything in it
already exists in the codebase - it is collected here because it spans the #1716 spike commits
(`DivisionPolicyClassifier`, `AiPolicySuggestion`, `AiDivisionSummary`) and this port.

### What is already wired

| Piece | Where | Notes |
|---|---|---|
| Bedrock SDK | `Gemfile`: `gem "aws-sdk-bedrockruntime"` | added by the #1716 spike |
| Models and region | `DivisionPolicyClassifier::MODELS`, `DivisionPolicyClassifier::REGION` | three models in ap-southeast-2 (two on-demand, one via the Australia cross-region inference profile); `DivisionSummarizer::MODELS` reuses the same list |
| LLM call | `DivisionSummaryPipeline::SemanticExtractor#call_bedrock` | `Aws::BedrockRuntime::Client#converse` at temperature 0, one call per model per division (plus a re-call when context is expanded to the sitting day) |
| Client construction | `DivisionSummarizer#client`, `SemanticExtractor#bedrock_client` | lazy: nothing contacts AWS until a summarise run happens, so a machine without credentials still boots and runs the offline suites |
| Hansard context | `DivisionSummaryPipeline::ContextBuilder` -> `DataLoader::Debates.fetch_xml_document(house, date)` | GETs `#{Rails.configuration.xml_data_base_url}scrapedxml/#{house}_debates/#{date}.xml`; base URL default is `http://data.openaustralia.org.au/` in `config/application.rb` |
| Database output | `AiDivisionSummary` (and `AiPolicySuggestion` for the classifier) | migrations `20260905003244_create_ai_policy_suggestions.rb` and `20260905041210_create_ai_division_summaries.rb`; unique index on division+model so a failed run can be retried over the errored row |
| Entry points | `lib/tasks/ai_classification.rake` | `rake ai:summarize_division DIVISION_ID=<id>`, plus `ai:classify_division` and `ai:import_policies` from the spike |

### What an operator must supply

1. **AWS credentials for Bedrock in ap-southeast-2.** No keys are stored in this repo. The SDK's
   default credential chain applies: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and optional
   `AWS_SESSION_TOKEN` environment variables, or the instance/task profile on the servers. The
   principal needs `bedrock:InvokeModel` (the action the Converse API operation requires, per AWS's
   API reference) on the foundation-model and inference-profile ARNs listed in `MODELS` - verify
   current action names against AWS documentation rather than trusting this file. The spike's
   comments on `DivisionPolicyClassifier` record how model availability in ap-southeast-2 was
   checked (`aws bedrock list-foundation-models` / `list-inference-profiles`); re-check there if
   the model lineup changes. Both this pipeline and the classifier share the same credentials.
2. **A reachable Hansard XML source.** Production uses the default data.openaustralia.org.au base
   URL; for offline work point `xml_data_base_url` at a local `file://` checkout of the parser's
   `pwdata` directory (see the comment next to the setting in `config/application.rb`).
3. **A migrated database with divisions loaded.** `bin/rails db:migrate` for the two migrations
   above, then `application:load:members` and `application:load:divisions` per the README's
   first-time data load.
4. **Somewhere to review drafts.** `AiDivisionSummary` rows are drafts; nothing publishes them and
   no admin surface exists yet (section 15's open item). Until one does, review in the console
   (`AiDivisionSummary.where(division: division)`) and move an approved summary onto the Division
   through the existing WikiMotion edit form - the same human-in-the-loop the classifier spike
   uses.

### Placeholders waiting for an integration

These are deliberate gaps. Each has a stable seam in the code; none blocks the rest of the
pipeline, and the offline suites all run with them empty.

1. **Bills Digest section (`digest_section`).** This is the `{{digest_section}}` placeholder in the
   bill templates (1 to 7). It is populated two ways, and `DivisionSummarizer` currently passes
   neither, so compiled summaries carry the fallback:
   - Supply `digest_link` (URL to the Bills Digest) and `digest_key_points` (the digest's "Key
     points" list) on the division data. `TemplateCompiler` then builds, word for word per
     `TEMPLATES.md`:
     `According to the [Bill Digest](LINK):` followed by a blockquote of `> * key point` lines.
     Note the singular "Bill Digest" - `TEMPLATES.md`'s wording, which the section must start with.
   - Or supply a pre-formatted `digest_section` string (the `digest_section:` keyword on
     `TemplateCompiler.compile`, or a `digest_section` attribute on the division data). Whoever
     formats it must keep the same opening line, since the section's wording is fixed by
     `TEMPLATES.md`.
   - With neither, the section renders as the blockquote `> No Bill Digest found.` - the fallback
     `TEMPLATES.md` prescribes. It deliberately has no "According to the..." header, because with
     no digest there is nothing to link to.
   A future integration (the prototype had `sources/bills_digest.py`; it was not ported) only has
   to fill those inputs - the seam is the Stage 5 call in `DivisionSummarizer#summarize_with`,
   which is marked PLACEHOLDER in a comment.
2. **Template 9's regulation summary (`regulation_summary`).** Same shape: `TEMPLATES.md` sources
   this section from the regulation's Explanatory Statement on legislation.gov.au, attributed
   rather than neutral because the government writes it. Currently left empty; pass it through the
   division data the same way.
3. **Template 22's follow-up division link (`followup_link`).** `TEMPLATES.md`'s closure template
   links to the division that put the underlying question. The compiler renders
   "The [Chamber] then voted on the question itself, which you can read about [here](...)" when a
   `followup_link` attribute is supplied, and stays byte-identical to the previous output when it
   is not. Resolving the follow-up division is a deterministic lookup over divisions of the same
   debate that nothing does yet.

### Deployment notes

- Nothing runs automatically. There is no cron entry and no flipper flag for this feature: it runs
  when someone invokes `rake ai:summarize_division`. If a batch mode ever lands, revisit section
  15's note about reusing one fetched XML document across a day's divisions first.
- CI (`.github/workflows/rubyonrails.yml`) runs the pipeline's software specs and the offline
  evaluation corpus as part of `bin/rake`; neither needs AWS, network or MySQL beyond what the
  suite already provisions.
- Keep credentials out of the repo, as for the rest of the app. On the Australia deployments
  (Capistrano, `config/deploy/`) that means whatever mechanism already supplies the environment
  the classifier spike's Bedrock calls ran with - the two features share one credential set, one
  region and one model list, so there is nothing new to configure beyond what already works for
  `DivisionPolicyClassifier`.

