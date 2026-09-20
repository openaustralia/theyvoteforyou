# Division Summary Pipeline

This directory contains the 5-stage modular AI division summary pipeline for They Vote For You.
`ARCHITECTURE.md` (this file) is its single explanation document: what it is, how it works end to
end, how each stage works in detail, how it reuses the rest of the app rather than duplicating it,
the template catalogue, and the constraints and open work that govern future changes.

**Status: built and reviewed offline; not yet wired to live systems.** The pipeline runs when
someone invokes `rake ai:summarize_division`; it publishes nothing by itself and contacts no live
system at boot or under test. Section 14 explains how to verify it, and section 15 is the wiring
checklist for connecting it to the live systems (Bedrock credentials, database, Hansard XML source,
and the still-empty integration points).

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

## 3. How it works: one division through the pipeline

The five stages form an assembly line, each one handing the next a smaller and cleaner problem.
This section walks a single division through the whole line in plain language; section 4 is the
technical reference for the same stages.

Suppose the pipeline is asked to summarise a Senate division at 12:30 pm on a sitting day, during
a bill's second reading debate.

### Step 1: Gather the facts and the debate (ContextBuilder)

Describing one vote does not require the whole day's Hansard, and sending all of it to the AI model
would be slow, expensive and noisy. So Stage 1 assembles a small, targeted packet instead:

- The authoritative database facts: the division's date, chamber, clock time, aye and no counts,
  turnout and rebellions.
- The Speaker's exact question: the wording actually being decided ("The question is that the
  amendment be agreed to").
- The debate speeches leading up to the vote, starting with those closest to it. By default this
  is the whole subdebate; if that proves not to be enough, the packet is widened to the entire
  sitting day (Step 3).

The packet is built by reusing the app's existing Hansard loader rather than parsing anything a
second time (section 5).

### Step 2: Route the vote (ProceduralRouter)

Before the AI is involved at all, ordinary code looks only at the Speaker's question and applies
fixed parliamentary rules:

- The obvious cases are decided here. "That the question be now put" is a closure of debate:
  Template 22 is chosen outright, and the extractor is held to it.
- The heading traps are defeated in code. A "Limitation of Debate" heading makes every later vote
  that day look like a guillotine, but when the question itself is about a bill amendment, it is an
  amendment vote, not a guillotine, and Template 18 is locked out.
- The nuanced cases are fenced, not set free. "That the bill be read a second time" might be the
  bill passing, or a vote on a second reading amendment. The router passes the packet on to the AI,
  but the AI is only allowed to choose between Template 6 and Template 2.

Divisions with an obvious procedural question are classified here, by code alone. The extractor
is still called for them (it supplies the topic, motion text and claims the template needs), but
it cannot change the classification: Stage 4 rejects a `template_id` outside what this stage
allowed. Skipping the call entirely for a deterministic route would save a model call per obvious
division and is a reasonable future change, but it is not what the code does today.

### Step 3: Extract the meaning (SemanticExtractor)

Now, and only now, the AI is called. It receives the debate packet and the router's instructions,
but it is not asked to write the summary. Its instructions are, in effect: you are an extraction
engine, fill in this form. It reads the debate and returns structured JSON:

- the template that fits, chosen only from the router's allowed candidates;
- a topic in a few words;
- the exact motion being decided;
- the mover's claims, each paired with a verbatim quote from the transcript as evidence;
- for a second reading amendment, whether it declines the bill a second reading.

If the model finds the packet does not actually contain what it needs (for example, the mover
explained the bill in an earlier debate and today's speeches only refer back to it), it sets
`sufficient_context` to false and names what is missing. The orchestrator then rebuilds the packet
from the whole sitting day's debate and asks again.

### Step 4: Verify every quote (ProvenanceValidator)

The filled-in form is handed back to ordinary code, which does not trust the model. For every
evidence quote, the validator mechanically searches the Hansard transcript for those exact words:

- If the quote is there, the claim stands.
- If the model paraphrased, embellished or invented it, the claim is rejected and the whole summary
  is flagged for human review instead of being published.

No claim reaches a compiled summary without passing this mechanical check.

### Step 5: Compile the summary (TemplateCompiler)

The AI's work is done. The compiler takes a pre-written, human-approved Markdown template (the 23
in section 8), fills its placeholders with the database facts (12:30 pm, the vote counts, the
rebellions) and the verified extractions (the motion text, the mover's claims), and applies
deterministic tidying: article grammar ("a" becomes "an" where the next word starts with a vowel),
duplicated definite articles collapse, and a Bills Digest section is inserted when a digest is
supplied. (Today nothing supplies one, so the template's fallback line appears; section 15 has the
contract for wiring it up.)

The result is publication-ready Markdown that is fully traceable: every number came from the
database, every quote came from Hansard, and the structure and wording were written and approved
by humans.

Nothing publishes itself. The compiled summary is saved as a draft (an `AiDivisionSummary` row)
for human review (section 11).

## 4. The five stages

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
- Matches the catch-all procedural traps before any subject-matter rule, deliberately: a suspension
  question that mentions a censure ("...as would prevent me from moving a censure motion") is a
  vote about suspending the standing orders; the censure division, if it happens, is a separate
  division. This implements `TEMPLATES.md` template 10's own instruction.
- Treats "Member be no longer heard" as a House of Representatives procedure: a Senate match is
  fenced as ambiguous (`MEMBER_NO_LONGER_HEARD_CHAMBER_CONFLICT`, candidate 23) rather than
  asserting a House-only template from possibly-wrong chamber metadata.
- Tolerates the Senate's "papers laid on/upon the table" wording in production-of-documents
  questions. These votes are about access to documents, never their subject matter, so a missed
  match misroutes worse than most.
- Routes questions that adjourn or postpone debate ("that the debate be adjourned", "the second
  reading be made an order of the day for the next sitting") to Template 19 ahead of the second
  reading and amendment rules, which would otherwise fence them between Templates 2 and 6: these
  votes decide when business is discussed, not the fate of the bill. The end-of-day "that the
  House do now adjourn" is deliberately left unmatched.
- Treats motions of no confidence in a minister or member (worded "no confidence" or the
  traditional "want of confidence") as censure motions (Template 10) when put directly. A
  no-confidence motion moved under a suspension of standing orders is caught first by the
  suspension rule, because the suspension is the division being taken at that point.

### Stage 3: Semantic Extractor (`DivisionSummaryPipeline::SemanticExtractor`)

- Prompts AWS Bedrock (or a stubbed client in testing, or an injected `llm_caller`) strictly for
  JSON matching `ExtractionPayload.json_schema`; the orchestrator keeps the raw response so it can
  be stored on the `AiDivisionSummary` record.
- The system prompt (`SemanticExtractor#system_prompt`) carries the full 23-template catalogue, the
  non-partisan neutrality rule, the Australian English constraint and the "moved formally" claims
  fallback. It also scopes claims to what each vote decides (a production-of-documents claim is
  about access to the documents, never the documents' subject matter; a closure claim is not about
  the underlying question), anchors extraction on the Speaker's question so a "Limitation of
  Debate" heading is never mistaken for a guillotine vote, and covers resumed debates: extract
  only what the excerpt supports and set `sufficient_context: false` with a `missing_context_clue`
  rather than reconstructing a missing speech.
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
- Re-checks Stage 2's fence, which otherwise reaches the model only as a system prompt instruction:
  a `template_id` in the decision's `locked_out_templates` is an error, and so is one outside its
  `candidate_templates`. This is what makes the guillotine lockout a lockout rather than a request.
  The general-motion fallback is exempt (`advisory_candidates`), because reaching it means no rule
  matched, so its single candidate is a default rather than evidence about the question and an
  extractor that recognises the motion is better informed than the fallback.
- Rejects unsupported claims and flags them for human editorial review rather than publishing
  unverified interpretations.

### Stage 5: Template Compiler (`DivisionSummaryPipeline::TemplateCompiler`)

- Injects authoritative TVFY database facts (official vote tallies, rebellions, member links,
  dates, times) and validated extractions into one of 23 human-curated Markdown templates.
- Substitutes variables deterministically without AI involvement, including small grammar fixes
  (indefinite articles, duplicated definite articles) and the database-resolved member facts
  described in sections 6 and 7.

## 5. Relationship to the existing Hansard loader

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

## 6. Data classification

- **Type 1: Authoritative Structured Facts** (vote counts, member details, rebellions, date,
  time): sourced exclusively from the TVFY database. Zero AI involvement.
- **Type 2: Deterministic Text** (exact motion text, Speaker's Question, bill names): sourced from
  official Hansard / ParlParse XML.
- **Type 3: Semantic Nuance** (procedural stage selection, mover's arguments, whether an amendment
  declines a second reading, plus each template's specific fact: the committee, regulation or
  business name, what a rearrangement of business does, and the targeted member's name or
  electorate exactly as the Hansard text states them): extracted by the LLM as structured JSON
  with mandatory verbatim quotes.

The split matters most for the people a motion targets. The extraction may report only what the
Hansard text states (a name or an electorate); the target's party, electorate and profile link are
Type 1 facts that `MemberResolver` looks up in the TVFY database when compiling. The model never
supplies a URL, a party or an electorate it wasn't given.

## 7. Provenance enforcement

Every claim made by the mover must have an `evidence` field containing an exact quote from the
Hansard context. The `ProvenanceValidator` mechanically asserts that the evidence appears in the
source: normalised evidence `include?` normalised Hansard context, where normalisation swaps curly
for straight quotes, replaces em/en dashes with hyphens, collapses whitespace and lowercases. The
whole normalised quote must appear as one substring; there is no partial-match tolerance, since a
fabricated middle between two genuine bookends would otherwise pass. The search is also scoped to
the claimed `speaker`'s own lines (via the `SPEECH:` tagging `ContextBuilder` adds), so a claim
can't be verified against words a different member said. Any claim that fails this mechanical
verification is rejected and flagged for human review rather than published.

The template-specific facts (`target_name`, `target_electorate`, `committee_name`,
`regulation_name`, `business_name`, `rearrangement_description`) are verified the same mechanical
way, since they are published verbatim in the summary sentence. A template whose required fact is
missing altogether (say Template 13 with no committee name) is likewise an error routing the draft
to human review: a blank is never published silently where a name should be.

## 8. The 23 template catalogue

The templates reside in `app/services/division_summary_pipeline/templates/`. The file name carries
the catalogue number and name; the text of each file is only publishable content. Catalogue
headings are deliberately absent from the files so they can never leak into compiled output; this
table is where the number-to-name mapping lives:

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
23. `23_member_no_longer_heard.md` - Member Be No Longer Heard (House of Representatives). Its
    intro sentence carries a single `{{target_clause}}` placeholder that the compiler fills from
    database-resolved member facts, degrading to plain text when the target cannot be resolved.
    Its motion-text blockquote quotes the extracted `{{motion_text}}`, like the other 22 templates.

## 9. Where everything lives

```text
app/services/division_summary_pipeline/     the pipeline itself (ARCHITECTURE.md explains it)
  context_builder.rb          Stage 1: adapts the existing Hansard loader into a ContextPacket
  procedural_router.rb        Stage 2: deterministic routing on the Speaker's Question
  semantic_extractor.rb       Stage 3: LLM prompt + Bedrock call, structured JSON only
  extraction_payload.rb       ExtractionPayload / ClaimEvidence value objects + JSON schema
  provenance_validator.rb     Stage 4: mechanical evidence-in-source assertions
  member_resolver.rb          resolves an extracted name or electorate to TVFY member facts
  template_compiler.rb        Stage 5: injects validated data into the Markdown templates
  text_normaliser.rb          shared text cleaning and quote-matching normalisation
  templates/                  the 23 Markdown templates ({{placeholder}} syntax)
  ARCHITECTURE.md             this document
app/services/division_summarizer.rb         orchestrator that runs the five stages
app/models/ai_division_summary.rb           output model: one saved draft per division and model
app/lib/data_loader/debates.rb              existing loader + fetch_xml_document/xml_url helpers
app/lib/data_loader/division_xml.rb         existing parser + operative_question/context_speeches
lib/tasks/ai_classification.rake            rake ai:summarize_division runs the whole pipeline
spec/services/division_summary_pipeline/    software specs + evaluation corpus
spec/fixtures/division_summaries/           evaluation fixtures (test_1, test_2)
```

## 10. Testing and evaluation

The feature is covered by two distinct test suites:

1. **Software Tests (`spec/services/division_summary_pipeline/`)**: Unit tests for
   `TextNormaliser`, `ExtractionPayload`, `ProceduralRouter`, `ContextBuilder`,
   `ProvenanceValidator`, `TemplateCompiler`, `MemberResolver`, `SemanticExtractor` and the
   `DivisionSummarizer` orchestrator.
2. **Parliamentary Evaluation Corpus (`spec/services/division_summary_pipeline/evaluation_spec.rb`)**:
   Regression test cases (`spec/fixtures/division_summaries/test_1` and `test_2`) covering a
   second-reading-amendment division and a closure-of-debate division, verifying 100% provenance
   and exact expected markdown output end to end. These use invented people, electorates and bill
   titles (not real MPs or real Hansard quotes) built in the real ParlParse `<debates>` XML shape -
   see the fictional-data note below - so growing this into a genuine corpus of real historical
   divisions, organised by procedural category, is tracked as follow-up work rather than done here.

Both fixtures' `hansard_excerpt.xml` are hand-built ParlParse `<debates>` documents in the same
shape `DebatesXml` and `DataLoader::Debates`'s own specs (`spec/lib/data_loader/`) use, since that
is what `ContextBuilder` actually parses in production.

### A note on the fictional data in these fixtures

The mover names, electorates, party links and bill titles in `test_1`/`test_2` are invented, not
drawn from a real division or a real MP's real words, in line with this repo's convention of using
fictional placeholders in specs and test data (`AGENTS.md`, "Working with AI tools"). The
production `Division`/`Vote`/`Member` tables this feature reads from are necessarily about real
people, since that is the whole point of They Vote For You. But attributing invented Hansard
wording to a real named person, even in a test fixture, is exactly the kind of unverified claim
`AGENTS.md`'s "Accuracy" guidance warns against, so the fixtures never do it.

## 11. Running it locally

The entry point is the rake task (`lib/tasks/ai_classification.rake`):

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

## 12. Architectural constraints for future work

These are the rules any future work on this feature must keep following. They exist because of how
TVFY actually gets its data, not because they sounded good in a design document.

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
   historical divisions is open follow-up work (section 13).

## 13. Open follow-up work

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
  wording it produces) is written up in section 15.
- **Template 22's follow-up division link.** The compiler renders
  "which you can read about here" with a link when a `followup_link` attribute is supplied on the
  division data, but nothing resolves "the division that put the underlying question" yet.
  Finding it is a deterministic lookup over same-debate divisions - a candidate for a future
  ContextBuilder extension rather than new data plumbing.
- **The mover's facts are not wired for live divisions.** `TemplateCompiler` reads
  `mover_name`/`mover_title`/`mover_party`/`mover_link` from the division data and the evaluation
  fixtures supply them, but nothing populates them from a real `Division`: `extract_attributes`
  provides none, so the mover name falls back to the division's own name and the link and party
  stay empty. The loader knows the mover (the Hansard XML carries speaker IDs that
  `DataLoader::DivisionXml` already resolves to `Member` records via `Member.find_by(gid:)`), so a
  deterministic mover resolution through `MemberResolver` is the same pattern as the existing
  target resolution.
- **Surfacing `AiDivisionSummary` drafts in the admin panel** for the review workflow.
- **Decide whether `LLM_Divisions/` is committed to this repo as archived reference** (the
  `ARCHIVED.md` in it supports that) or kept untracked; the conversation transcripts in it are
  large and are the only reason to hesitate.
- **Reusing one fetched XML document across a batch of divisions**: the orchestrator builds the
  packet once per division, but a bulk run over a sitting day still fetches and parses the same
  day's XML once per division. Fine for the current rake task; worth revisiting if this ever runs
  nightly over every division of a day.
- **The extracted `speaker` field is not checked against the speakers in the Hansard context.**
  Evidence quotes are the load-bearing provenance check and are verified; the speaker name is
  optional metadata, currently trusted from the model.

## 14. Verifying the pipeline

Everything except the final live call runs offline. Run, in stages:

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

## 15. Hooking it up to live systems

Every external dependency sits behind an injectable seam, so nothing contacts a live system at
boot or under test. This section is the wiring checklist for whoever has the keys. Everything in
it already exists in the codebase - it is collected here because it spans the #1716 spike commits
(`DivisionPolicyClassifier`, `AiPolicySuggestion`, `AiDivisionSummary`) and this pipeline.

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
   no admin surface exists yet (section 13's open item). Until one does, review in the console
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
   Filling those inputs is not just plumbing: APH blocks automated clients, OAF's ParlInfo access
   is a negotiated arrangement living in `openaustralia-parser`, and Bills Digests are
   CC BY-NC-ND licensed. See `docs/bills-digest-integration.md` for the findings, the options and
   what needs sign-off, before writing any fetcher.
   A future integration only has to fill those inputs - the seam is the Stage 5 call in
   `DivisionSummarizer#summarize_with`, which is marked PLACEHOLDER in a comment.
2. **Template 9's regulation summary (`regulation_summary`).** Same shape: `TEMPLATES.md` sources
   this section from the regulation's Explanatory Statement on legislation.gov.au, attributed
   rather than neutral because the government writes it. Currently left empty; pass it through the
   division data the same way.
3. **Template 22's follow-up division link (`followup_link`).** `TEMPLATES.md`'s closure template
   links to the division that put the underlying question. The compiler renders
   "The [Chamber] then voted on the question itself, which you can read about [here](...)" when a
   `followup_link` attribute is supplied, and omits the sentence when it is not. Resolving the
   follow-up division is a deterministic lookup over divisions of the same debate that nothing does
   yet.

### Deployment notes

- Nothing runs automatically. There is no cron entry and no flipper flag for this feature: it runs
  when someone invokes `rake ai:summarize_division`. If a batch mode ever lands, revisit section
  13's note about reusing one fetched XML document across a day's divisions first.
- CI (`.github/workflows/rubyonrails.yml`) runs the pipeline's software specs and the offline
  evaluation corpus as part of `bin/rake`; neither needs AWS, network or MySQL beyond what the
  suite already provisions.
- Keep credentials out of the repo, as for the rest of the app. On the Australia deployments
  (Capistrano, `config/deploy/`) that means whatever mechanism already supplies the environment
  the classifier spike's Bedrock calls ran with - the two features share one credential set, one
  region and one model list, so there is nothing new to configure beyond what already works for
  `DivisionPolicyClassifier`.
