# Division Summary Pipeline

This directory contains the 5-stage AI division summary pipeline for They Vote For You.
`ARCHITECTURE.md` (this file) is its single explanation document: what it is, how it works end to
end, how each stage works, how it reuses the rest of the app rather than duplicating it, the
template catalogue, and the constraints and open work that govern future changes.

`KNOWN_ISSUES.md` beside it is the defect register: where the code does not do what this document
describes, each entry checked against the chambers' own procedural guides. Keep the two apart. This
file says how the pipeline is meant to work; that one says where it currently doesn't, and is the
first thing to read before changing routing, a template or the compiler.

**Status: built and reviewed offline; not yet wired to live systems.** The pipeline runs when
someone invokes `rake ai:summarize_division`; it publishes nothing by itself and contacts no live
system at boot or under test. Section 14 explains how to verify it, and section 15 is the wiring
checklist for connecting it to the live systems.

## 1. Problem statement and motivation

Publishing objective, plain-English summaries of Australian parliamentary divisions is essential
for public understanding. Hand-writing them for thousands of divisions is impossible for a small
team, but using off-the-shelf generative AI to draft them introduces serious pitfalls:

1. **The Guillotine Trap**: When the government limits debate under a "Limitation of Debate"
   heading, all subsequent votes on substantive bill amendments fall under that heading. Naive
   models read the heading and misclassify substantive amendments as procedural guillotine motions.
2. **Hallucination and paraphrase**: Generative models invent facts, attribute claims never made,
   and, even when asked to quote, "tidy" what a member said into words the member never used.
3. **Tone and formatting instability**: models drift into partisan adjectives, speculative
   conclusions and inconsistent formatting.

## 2. The core design: the model selects, it never writes

One rule governs everything else (recorded as `docs/adr/0005-ai-summaries-select-never-author.md`):

> The AI may identify, classify and select. It never supplies publication text. Every published
> character is human-written template prose, a database fact, or Hansard's own text retrieved by
> code from a reference.

That gives a hierarchy for every fact a summary needs:

- **The database or a rule already knows it**: never ask the model. Vote counts, times, members,
  bills, the chair's question, who moved the motion, the words they moved it with and its terms.
- **Hansard contains it, but finding it needs understanding**: the model points at it, and code
  retrieves it. The mover's explanation, and the one fact a template names (a committee, a
  regulation, the member a motion targets).
- **Nothing authoritative contains it**: leave it out, and say so in the draft's Reviewer Only
  report. A missing topic is better than an invented one, so there is no topic.

The model's output therefore has two kinds of thing in it, kept apart in the data structures:

- **Semantic decisions** (ExtractionPayload::Interpretation): which template fits, whether a
  second reading amendment declines the bill a second reading, and which kinds of evidence it
  could not find. These steer the program; none of them is published text.
- **Source references** (ExtractionPayload::References): IDs of units of the transcript it was
  shown. Code turns them into Hansard's own words, and a reference that does not resolve is not
  quoted at all.

Provenance is therefore part of the data model rather than a check made afterwards. There is no
"search Hansard for the model's string" step, so a quote cannot be paraphrased, shortened,
re-punctuated or invented, and there is no question of which occurrence of a repeated sentence was
meant. The model is a semantic index over messy Hansard; the router is the guardrail, the
validator the referee, and the compiler the printer.

The model is architecturally swappable: it sits behind a fixed schema, so another foundation
model, an open-weight model or a specialised classifier could replace it without changing the
stages around it.

## 3. How it works: one division through the pipeline

Suppose the pipeline is asked to summarise a Senate division on a second reading amendment.

### Step 1: Gather the facts and the debate (ContextBuilder)

Stage 1 reads the day's ParlParse XML with the app's existing loader (section 5) and assembles a
small packet:

- the database facts (DivisionFacts): chamber, date, time, counts, bills, result;
- the chair's question as the chamber decided it, and the chair's statement putting it, with who
  was in the chair and the time of that statement;
- the speeches leading up to the vote (the subdebate by default), cut into a **Transcript** of
  numbered units: each sentence a member spoke, each paragraph of a motion, the "I move" words, and
  the chair's statement, every one with an ID such as `S3.4`;
- when the motion was moved somewhere else (a deferred division, a long debate), the moving
  speeches from earlier in the same debate, including earlier sitting days and the same bill's
  other headings;
- when the question was put because a limitation of debate's time had expired, the chair's
  sentence saying so, however many divisions back it is, and in the House, the Speaker putting it
  immediately under a resolution agreed earlier;
- the mover, found by rule (MoverFinder), and so, by rule, the terms moved and the words the mover
  moved them with; or, when the chair put amendments nobody moved, their terms as the chair's
  statement prints them and who circulated them (Circulation);
- for a closure, what the debate it ended was on, and the division that then put that question;
  for a matter of urgency, who proposed it when someone else moved it.

### Step 2: Route the vote (ProceduralRouter)

Before the model is involved, fixed rules read the question. Obvious forms settle the template
("That the question be now put" is Template 22). Guardrails constrain what cannot safely be
inferred: a "Limitation of Debate" heading forbids Template 18 for an amendment question, and a
bill stage narrows the choice to a shortlist. Anything else falls to a default the model may
depart from.

### Step 3: Ask the model to interpret and point (SemanticExtractor)

The model sees the question, the routing contract, Stage 1's warnings, what Stage 1 found by rule
about the motion, and the transcript with its unit IDs. It answers in JSON with the template, the
declines flag for Template 2, any missing evidence from a closed list, the IDs of the sentences in
which the mover explains the motion, and for a few templates the unit where a named fact appears.

If it reports evidence missing, the orchestrator widens the packet to the whole sitting day and the
earlier days of the same debate and asks once more. When the question only refers to a motion and
Stage 1 could not find it, the wider packet is built before the model is asked at all. When the
question is itself the whole motion (`ContextPacket#question_states_motion?`), missing terms are not
a reason to widen, since there are none to find (KI-32). If the retry fails or its reply cannot be
read, the draft is built from the first reply and the Reviewer Only report says so (KI-33).

### Step 4: Resolve and check the references (ProvenanceValidator)

Code turns every reference into Hansard's own text and checks it. An explanation reference that is
not the mover's own words (another member, the chair, the motion itself, or words the mover quoted)
is dropped with a warning. The operative motion, a template's required fact, Template 2's flag and
the routing fence are hard requirements: if any fails, the draft is not compiled.

### Step 5: Compile the summary (TemplateCompiler)

ParliamentaryOutcome decides what the vote meant (carried or not, tied, want of quorum, absolute
majority, the message and closure forms, the bill stage, the inverted stand-as-printed question);
SummaryWording chooses the human-written sentences that say it; EvidenceSections renders the
quotes; TemplateCompiler fills the template. The draft gets a title by rule (DraftTitle) and a
fixed Reviewer Only report (ReviewerReport) at its foot.

Every draft has the same shape:

```
<explainer>

---

<vote sentence>

<limitation of debate>         (bill templates, only when the chair put the question because a
                               guillotine's time had expired, or in the House under an earlier
                               resolution: a fixed sentence and the chair's own words saying so)

<notices>                      (a divided question, rebellions, a tie, want of quorum, absolute
                               majority)

### About the Bill            (bill templates: the Bills Digest section)
### About the Amendment       (or Motion, Report...: "At 1:27 PM, Senator Example said:" + exact
                               sentences, or "No explanatory claims recorded.")
### Motion Introduction       (the mover's "I move ..." words, exactly)
### Amendment Text            (or Motion Text: "Senator Example moved the following amendment:",
                               or for amendments the chair put, "The following amendments,
                               circulated by the Example Party, were put:" + the complete terms)
### Question Put              ("At 1:27 PM, Example MP, in the chair, put the following question:"
                               + the chair's words putting this division's question)

---
## Reviewer Only              (how the draft was made; removed before publishing)
```

Each quote carries the time of the speech it came from, which is not the division's time. House
members are named in the site's own form, "Example MP"; senators, "Senator Example". Nothing
publishes itself: the draft is saved as an `AiDivisionSummary` for human review.

## 4. The five stages

```text
   Division (ActiveRecord) ──> DataLoader::Debates / DebatesXml / DivisionXml / SpeechText
                                       │
                         Stage 1  context/      ContextBuilder -> ContextPacket
                                       │        (DivisionFacts, Transcript, MoverFinder, EarlierDebate)
                                       ▼
                         Stage 2  routing/      ProceduralRouter -> RoutingDecision
                                       │
                                       ▼
                         Stage 3  extraction/   SemanticExtractor (+ ExtractionPrompt) -> ExtractionPayload
                                       │        (Interpretation + References)
                                       ▼
                         Stage 4  validation/   ProvenanceValidator -> ValidationResult (Evidence)
                                       │
                                       ▼
                         Stage 5  compilation/  ParliamentaryOutcome, SummaryWording, EvidenceSections,
                                       │        TemplateCompiler, DraftTitle, ReviewerReport
                                       ▼
                         DivisionSummarizer::Result -> AiDivisionSummary (draft)
```

### Stage 1: Context (`context/`)

- `ContextBuilder` matches the TVFY `Division` to its `<division>` element by `divnumber` (section
  5), gathers speeches at progressive tiers (Level A immediate, Level B subdebate, the default and
  capped at 25 speeches with the latest earlier move kept in front, Level C sitting day), and adds
  Level D, the moving speeches from earlier in the same debate (`EarlierDebate`), when the chair
  says the division was deferred, when nothing beside the division moved anything and the question
  refers to something moved, and always on the sitting-day retry.
- A debate is matched by heading and by the bills listed under each heading, because a bill's
  stages sit under different headings: a guillotine's questions are put under "; Limitation of
  Debate" about amendments moved under "; Second Reading". A speech found under another heading
  is marked `:other_heading`, and is only ever a fallback: it does not count against the
  earlier-debate budget or stop the search for this heading's own move, MoverFinder never takes
  it as the unnamed "move just before the question" nor prefers it to the named member's move
  under this heading, and ContextBuilder drops it unless it is the move the chair named (with no
  mover found, the validator cannot tell whose words the model quotes as the explanation). So a
  division whose move was found before gets the same packet as before.
- `ChairStatement` reads the chair's statement putting the division's question, once, for every
  stage that needs it. The division's question is the last question sentence in the chair's own
  words, after any question the statement put and closed on the voices ("Question agreed to."),
  and that sentence is what Stage 2 routes on and the prompt shows as the question. The paragraphs
  that put it are what Question Put quotes and where MoverFinder looks for the mover's name. What
  Hansard prints in italic inside the statement, such as the amendments being put, is never read as
  the chair's words (KI-35, KI-41).
- `DataLoader::DivisionXml#limitation_of_debate_statement` finds the chair saying a guillotine's
  time had expired ("Pursuant to order ..., the time allotted ... has expired"), walking back
  through divisions, the chair's statements and "; Limitation of Debate" sections, and stopping
  at a speech by anyone but the chair, or any other heading. It becomes
  `ContextPacket#limitation_statement` (the one sentence, kept out of the transcript, since the
  rest of the statement usually puts a question on another bill), a context warning, and in
  Stage 4 `Evidence#limitation`.
- `DataLoader::SpeechText.paragraphs` labels every block of a speech as `:move` (the "I move"
  words), `:motion` (the terms moved), `:quotation` or `:prose`. Current ParlParse XML has no
  `pwmotiontext`: the terms moved are `<p class="italic">` after "I move", which is why only
  paragraphs after an "I move" count. Hansard also sets in italic whatever a member quotes or
  reads out, and its own editorial notes, so any other italic paragraph is a `:quotation`, never
  the member's own words (KI-38). The exception is a speech incorporated by leave, which is the
  member's own words however it is set: everything after "The speech read as follows" (in any of
  its spellings) up to the first plain paragraph is `:prose`, and is never searched for a move,
  because a Senate minister's incorporated speech often opens with the House's own "I move"
  (KI-39).
- `Transcript` cuts the speeches into units with IDs: prose into sentences (conservatively, so
  "No. 3" and "Mr" never end one), an "I move" paragraph into sentences so reasons given before
  the move stay quotable, and motions, quotations and the chair's question into whole paragraphs.
  It keeps raw text for publication and retrieves exact runs of units; `Transcript#anchor` finds a
  short phrase inside one unit and returns Hansard's own characters for it.
- `DivisionFacts` is the one reader of a `Division` record or a Hash of division data.
- `MoverFinder` finds the mover from the chair's "moved by ..." or the latest "I move", and records
  how (`found_by`). An unnamed move counts only when its terms could be what the question puts
  (amendments for a question on amendments, the same reading for a reading), and the chair putting
  other questions in between does not push it out of the window. `MemberResolver` resolves members
  from the database and owns the one name matcher (`same_speaker?`).
- Context warnings flag when the speeches beside a division may not be the debate about it:
  successive divisions (House S.O. 131), deferral read from the chair's words or the House's
  deferral windows (S.O. 133), speeches added from earlier in the debate, no speeches at all, or no
  matching XML.
- `ContextPacket` is immutable. A widened packet is built afresh with the first packet's routing
  passed in, because routing is about this division and was decided on the speeches beside it.

### Stage 2: Routing (`routing/`)

- `ProceduralRouter` rules are an ordered list in three groups: **signatures** that settle a
  template from a form of words, **guardrails** that forbid or narrow (the Limitation of Debate
  lockout, the Senate gag conflict, bill-stage shortlists), and the **fallback**, a default the
  model may leave. First match wins, so order is logic: suspension of standing orders is first of
  all (KI-16), and the catch-all procedures come before any subject-matter rule.
- A question put only by reference is routed again on the motion's first paragraph; that route is
  binding only when the motion opens in a fixed form, and advisory otherwise.
- Bill titles are removed before looking for amendment wording, since "... Amendment Bill 2026"
  says nothing about whether the question is on an amendment (KI-29).
- `RoutingDecision` is the contract (`template_id`, `allowed_templates`, `forbidden_templates`,
  `mode`: `:deterministic`, `:constrained` or `:advisory`); the rule name and reason are a separate
  `diagnostic` for the reviewer, and nothing downstream branches on them.
- Keep this a router, not a model of all of procedure (constraint 3).

### Stage 3: Extraction (`extraction/`)

- `SemanticExtractor` is only the Bedrock call (temperature 0, 300-second read timeout) or an
  injected `llm_caller`; the orchestrator keeps the raw reply on the draft.
- `ExtractionPrompt` builds the system prompt (the catalogue from `TemplateCatalogue`, the
  explanation rules, neutrality, the closed list of reasoned amendment forms for KI-11, the
  guillotine trap, the missing-evidence list) and the user prompt (question, metadata, routing
  contract, context warnings, what Stage 1 found about the motion, the transcript with IDs).
- `ExtractionPayload` is the one current reply schema, `interpretation` plus `references`. There is
  no field for a topic, a claim, a motion or a note, and no legacy title-and-description path.

### Stage 4: Validation (`validation/`)

- `ProvenanceValidator` resolves every reference against the transcript and builds `Evidence`,
  the only thing Stage 5 sees.
- Hard errors: an invalid template or one the routing fence refuses; no operative motion when the
  question only refers to one (a question that states its own terms, such as the Speaker's "That
  the House do now adjourn", stands in for a motion when none was moved); a required fact missing
  or not found in the unit named; Template 2's flag missing or contradicting the amendment's words.
- Dropped with a warning: explanation references to anything but the mover's own sentences (with
  no mover, the circulating member's, if a member circulated the amendments), more than six
  sentences, model motion references when Stage 1 found the motion or that point at the chair
  putting a question, and fact references that do not resolve.
- Settled by the amendment's own words where they settle it: whether a second reading amendment
  declines the bill (KI-11). And a warning when the model cannot find what a template settled by
  the question is about, since then the route is in doubt (KI-59).
- What it proves: the quoted words were said, where, when and by whom. What it cannot prove: that
  the model chose the most representative sentences. That is why every draft is reviewed by a person.

### Stage 5: Compilation (`compilation/`)

- `ParliamentaryOutcome` decides meaning: success (and the Template 28 inversion), tied votes
  (Constitution ss 23 and 40), want of quorum (House S.O. 58, with the quorum from the member
  records on the day), absolute majorities (section 128, Senate S.O. 87, suspensions), the message
  forms, the three closures, the bill stage, the suspension's stated purpose and the urgency
  matter. It reads the motion Stage 1 found, falling back to the question.
- `SummaryWording` holds the human-authored sentences each outcome chooses.
- `EvidenceSections` renders the quoting sections in the layout in section 3. A section with
  nothing to quote prints a fixed sentence ("No explanatory claims recorded.").
- `TemplateCompiler` loads the template, fills its placeholders, and keeps its tidying passes off
  every placeholder that quotes Hansard (KI-17). It records each fallback it used.
- `DraftTitle` builds the title by rule: `<major heading> - <minor heading without its last "; ..."
  part>; <template's procedure>`.
- `ReviewerReport` is the fixed-form Reviewer Only section (section 7).
- `TemplateCatalogue` is the one table of what the pipeline knows about each template apart from
  its wording: names, the title label, what was moved, whether it prints an explanation, and the
  facts it names and requires.

## 5. Relationship to the existing Hansard loader

**This is the single most important architectural constraint on this feature, so it gets its own
section rather than being buried in Stage 1's bullet points.**

They Vote For You already has a working, nightly-run pipeline that turns Australian Hansard into
`Division` records:

```
rake application:load:divisions[from,to]
  -> DataLoader::Debates.load!(from_date, to_date)
       -> DataLoader::Debates.fetch_xml_document(house, date)
       -> DataLoader::DebatesXml.new(doc, house).divisions
       -> for each DivisionXml: divdate/divnumber/time, headings, motion text
       -> Division.create!(date:, number:, house:, name:, motion:, debate_url:, debate_gid:, ...)
```

A `Division` row's `date`, `number`, `house`, `name` and `motion` are the literal output of parsing
the same ParlParse `<division>` element this feature needs wider context around. Two independently
written parsers of the same fragile, sibling-walk-based XML would drift silently. So
`ContextBuilder` is a thin adapter, not a second loader:

1. `DataLoader::Debates.fetch_xml_document(house, date)`, the method the nightly load calls,
   fetches the day's XML.
2. `DataLoader::DebatesXml.new(doc, house).divisions` turns it into `DataLoader::DivisionXml`
   objects in document order.
3. `ContextBuilder` finds the one matching this `Division` by `divnumber` (the identity
   `DataLoader::Debates.load!` keys records on), falling back to clock time or `debate_gid` only if
   the number is missing. No weighted or fuzzy matching.
4. It reads small additive public methods on `DataLoader::DivisionXml` (`#operative_question`,
   `#question_speech`, `#context_speeches`, `#debate_title`, `#earlier_same_debate_speeches`,
   `#preceded_by_division?`, `#run_statements`, `#bill_ids`, `#limitation_of_debate_statement`) and
   `DebatesXml#speeches_under_minor_heading` (with `.section_heading` and `.section_bill_ids`), built
   on the same sibling traversal `#motion` uses. Speech text goes through `DataLoader::SpeechText`,
   which the nightly loader does not use, so `#motion` keeps its PHP-compatible formatting.

If Hansard XML can't be fetched or no `<division>` matches, `ContextBuilder` falls back to the
`Division` record's own stored motion text as a one-speech transcript. Nothing in it says which
lines are the motion, so the motion can only be quoted if the model points at it there.

## 6. Data classification

- **Type 1: authoritative structured facts** (vote counts, members, rebellions, date, time,
  bills): from the TVFY database (DivisionFacts, MemberResolver). No AI involvement.
- **Type 2: deterministic text** (the chair's question and statement, the mover's "I move" words,
  the terms moved, headings): found in the ParlParse XML by rule. No AI involvement.
- **Type 3: semantic selection** (the template, whether an amendment declines a second reading,
  which of the mover's sentences explain the motion, where a template's named fact appears): the
  model decides or points; code retrieves the text.

For the people a motion targets, the model may only point at where Hansard names them; party,
electorate and profile link are Type 1 facts `MemberResolver` looks up. The model never supplies a
URL, a party or an electorate.

## 7. Provenance and the Reviewer Only report

Every quoted or named piece of Hansard in a draft is an `Evidence::Excerpt`: the exact text, the
unit IDs it came from (none for the limitation of debate sentence, which Stage 1 finds outside the
transcript; the Reviewer Only report gives its speech's XML id instead), the speaker, the speech
time and date, and whether Stage 1 found it by rule or it came from a model reference that
resolved. Normalisation (`TextNormaliser`) is used only to
search, when locating a phrase inside a unit; what is published is always the raw text.

The Reviewer Only section at the foot of every draft, including a failed one, is a fixed form
built from the pipeline's own records: the model, the source (matched XML or the Division record),
the context level and any earlier days added, the question routed on, the title and where it came
from, the routing decision and its reason, the model's decisions and references, every excerpt with
its units, speaker, time and how it was found, how the mover was found, the fallbacks used, and the
validation errors and warnings. It contains nothing the model wrote. The model's reply is kept
untouched on the saved draft's `raw_response`.

## 8. The template catalogue

The templates reside in `templates/`. The file name carries the catalogue number and name; the text
of each file is only publishable content. `TemplateCatalogue` holds everything else about each one
(names, the title label, what the mover moved, whether it prints an explanation, the facts it names)
and `template_catalogue_spec.rb` checks the two agree.

1. `1_first_reading.md` - First Reading
2. `2_second_reading_amendment.md` - Second Reading Amendment
3. `3_in_committee_amendment_senate.md` - In Committee Amendment (Senate)
4. `4_consideration_in_detail.md` - Consideration in Detail (House of Representatives)
5. `5_federation_chamber_report.md` - Federation Chamber Report
6. `6_third_reading.md` - Third Reading
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
24. `24_suspension_of_member.md` - Suspension of a Member (House S.O. 94 / Senate S.O. 203)
25. `25_dissent_from_ruling.md` - Dissent from Ruling of the Chair
26. `26_adjournment.md` - Adjournment of the Chamber (House S.O. 29 and S.O. 31)
27. `27_taking_note.md` - Taking Note
28. `28_stand_as_printed.md` - Question That a Clause or Part Stand As Printed (inverted: defeating
    the question is what omits the part)
29. `29_second_reading.md` - Second Reading (numbered last so that no template already cited by
    number had to be renumbered when the second reading was split from Template 6)

Templates 22, 23, 24 and 26 decide only procedure, so they print no explanation section. Every
template has Motion Introduction, the terms moved and Question Put, and prints the mover through
`{{mover_clause}}`, which is empty when nobody moved anything and says "circulated by ..." for
amendments the chair put.

## 9. Where everything lives

```text
app/services/division_summary_pipeline/   folders are for people; Zeitwerk collapses them
                                          (config/initializers/division_summary_pipeline.rb)
  context/      context_builder.rb, context_packet.rb, transcript.rb, division_facts.rb,
                earlier_debate.rb, mover_finder.rb, member_resolver.rb, chair_statement.rb
  routing/      procedural_router.rb, routing_decision.rb
  extraction/   semantic_extractor.rb, extraction_prompt.rb, extraction_payload.rb
  validation/   provenance_validator.rb, evidence.rb
  compilation/  template_catalogue.rb, parliamentary_outcome.rb, summary_wording.rb,
                evidence_sections.rb, template_compiler.rb, draft_title.rb, reviewer_report.rb
  clock_time.rb, text_normaliser.rb       shared by several stages
  templates/                              the Markdown templates, one per procedure
  ARCHITECTURE.md, KNOWN_ISSUES.md
app/services/division_summarizer.rb       the orchestrator
app/models/ai_division_summary.rb         one saved draft per division and model
app/lib/data_loader/speech_text.rb        one <speech>, its blocks labelled, and what it moved
app/lib/data_loader/division_xml.rb       existing parser + the additive methods in section 5
lib/tasks/ai_classification.rake          rake ai:summarize_division
spec/services/division_summary_pipeline/  one spec per class, plus the evaluation corpus
spec/support/division_summary_helpers.rb  builders for speeches, packets and evidence
spec/fixtures/division_summaries/         evaluation fixtures (test_1, test_2)
```

## 10. Testing and evaluation

1. **Software specs** (`spec/services/division_summary_pipeline/`), one per class. Fixtures copy
   the real ParlParse shape (italic motion paragraphs, a named chair, no `pwmotiontext`) with
   invented members and bills; the earlier fixtures' older shape is why the September 2026 failures
   never showed offline (KI-20).
2. **Evaluation corpus** (`evaluation_spec.rb`, `spec/fixtures/division_summaries/`): Stages 1, 2,
   4 and 5 end to end over fixture XML with the model's reply read from a fixture, comparing the
   compiled Markdown exactly. Fixture 1 is a second reading amendment moved formally, which must
   print "No explanatory claims recorded."; fixture 2 is a closure.

The mover names, electorates and bills in fixtures are invented, never a real member's words, per
`AGENTS.md`. Growing the corpus with real historical divisions is open work (section 13).

## 11. Running it locally

```bash
rake ai:summarize_division DIVISION_ID=123
```

It runs the pipeline for one Division against every configured Bedrock model and saves each result
as an `AiDivisionSummary`, skipping models that already have an error-free draft. It needs AWS
credentials for Bedrock in ap-southeast-2 and divisions loaded via `application:load:divisions`.
Nothing is published by this task.

## 12. Architectural constraints for future work

1. **No second Hansard pipeline.** Consume `Hansard -> openaustralia-parser -> ParlParse XML ->
   DataLoader`, never rebuild it (section 5).
2. **The model selects, it never writes.** No new field may carry model-written text into a draft.
   A new fact a template needs is either found by rule in Stage 1 or pointed at by reference and
   resolved in Stage 4. Semantic decisions (a template, a flag, a closed-list choice) are fine;
   free text is not (ADR 0005).
3. **The Procedural Router must stay a router.** Signatures settle only what a form of words
   settles; guardrails say what cannot be inferred; everything else goes to the model inside a
   fence. Do not grow it toward "completely understanding Parliament" in code.
4. **Progressive context stays, and is evidence-driven.** Level A -> Level B (default) -> Level C,
   widened when the model reports evidence missing, or before asking when the question refers to a
   motion Stage 1 cannot find. Level D adds only moves and the chair's statements, never whole
   earlier debates. A widened packet keeps the routing decided on the speeches beside the division.
5. **Code that prints Markdown does not decide meaning.** Parliamentary logic belongs in
   ParliamentaryOutcome, wording in SummaryWording and the templates, and TemplateCompiler only
   fills placeholders.
6. **Two kinds of tests**, as in section 10.

## 13. Open follow-up work

`KNOWN_ISSUES.md` is the defect register and the more urgent list. This section is work that was
never built.

- **Growing the evaluation corpus** with real historical divisions, hand-verified against the
  published Hansard, organised by procedural category.
- **Which Bedrock model(s) to default to.** `DivisionSummarizer::MODELS` reuses
  `DivisionPolicyClassifier::MODELS`, inherited from the classifier spike rather than decided for
  this feature.
- **Bills Digest / Explanatory Memorandum integration** (section 15).
- **Surfacing `AiDivisionSummary` drafts in the admin panel** for review.
- **Reusing one fetched XML document across a batch of divisions** if this ever runs nightly.
- **Splitting `template_compiler_spec.rb`**, which tests ParliamentaryOutcome, SummaryWording and
  EvidenceSections through the compiler and is about five times the compiler's size.
- **Consolidating the majority wording thresholds**: DivisionFacts repeats
  `DivisionsHelper#majority_strength_in_words`'s thresholds because the helper builds HTML; moving
  them onto the model would give one source for both.

## 14. Verifying the pipeline

```bash
bin/rspec spec/services/division_summary_pipeline spec/services/division_summarizer_spec.rb spec/lib/data_loader
bin/rake                       # the full suite, as CI runs it
bin/rubocop --parallel
bin/rails zeitwerk:check       # the collapsed folders must still eager load
```

Everything runs offline. Stage 3 is covered through a stubbed Bedrock client and an injected
`llm_caller`. Then one real call:

```bash
rake ai:summarize_division DIVISION_ID=123
```

and read the draft's Reviewer Only report against the division's Hansard, then the saved
`raw_response`. Do not judge the feature on the summary alone.

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
| LLM call | `DivisionSummaryPipeline::SemanticExtractor#extract_raw` (the `converse` call itself is private) | `Aws::BedrockRuntime::Client#converse` at temperature 0 with a 300-second read timeout, one call per model per division (plus one more when the model reports evidence missing and the packet is widened to the sitting day) |
| Client construction | `SemanticExtractor.bedrock_client`, called lazily by `DivisionSummarizer#client` | one client, built on first use and shared by every model in a run: nothing contacts AWS until a summarise run happens, so a machine without credentials still boots and runs the offline suites |
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
   bill templates (1 to 7, 28 and 29, the ones with an "About the Bill" section). It is populated
   two ways, and `DivisionSummarizer` currently passes neither, so compiled summaries carry the
   fallback. The wording below comes from `TEMPLATES.md`, the original template design document,
   which is not in this repository; `TemplateCompiler#digest` and its specs in
   `template_compiler_spec.rb` are now where it is fixed.
   - Supply `digest_link` (URL to the Bills Digest) and `digest_key_points` (the digest's "Key
     points" list) on the division data. `TemplateCompiler` then builds
     `According to the [Bill Digest](LINK):` followed by a blockquote of `> * key point` lines.
     Note the singular "Bill Digest", the original design's wording, which the section must start
     with.
   - Or supply a pre-formatted `digest_section` string (the `digest_section:` keyword on
     `TemplateCompiler.compile`, or a `digest_section` attribute on the division data). Whoever
     formats it must keep the same opening line.
   - With neither, the section renders as the blockquote `> No Bill Digest found.`, the original
     design's fallback. It deliberately has no "According to the..." header, because with no
     digest there is nothing to link to.
   Filling those inputs is not just plumbing: APH blocks automated clients, OAF's ParlInfo access
   is a negotiated arrangement living in `openaustralia-parser`, and Bills Digests are
   CC BY-NC-ND licensed. See `docs/bills-digest-integration.md` for the findings, the options and
   what needs sign-off, before writing any fetcher.
   A future integration only has to fill those inputs - the seam is the Stage 5 call in
   `DivisionSummarizer#summarize_with`, which is marked PLACEHOLDER in a comment.
2. **Template 9's regulation summary (`regulation_summary`).** Same shape: the original design
   sources this section from the regulation's Explanatory Statement on legislation.gov.au,
   attributed rather than neutral because the government writes it. Currently left empty; pass it through the
   division data the same way.
3. **Template 6's originating chamber (`bill_originating_house`).** Where a bill goes once it
   passes a chamber depends on where it started, and the `bills` table records only
   `official_id`, `url` and `title`. A bill that started in this chamber goes to the other one; a
   bill that came from the other chamber and passes here unamended goes to the Governor-General
   for assent, and one this chamber amended goes back with a schedule of amendments (House Guide
   to Procedures pp. 87-88). `TemplateCompiler` therefore names the destination only when a
   `bill_originating_house` attribute on the division data settles it outright, and otherwise
   stops at "This means the bill has now passed the [Chamber]." Supplying that attribute is all a
   future integration has to do. Nothing populates it yet.
4. **Template 22's follow-up division link (`followup_link`).** Built: `ContextBuilder#with_followup`
   links the next division that day, in the same debate, when it is not itself a closure and is in
   the database, and the compiler renders "The [Chamber] then voted on the question itself, which you
   can read about [here](...)". A caller can still supply `followup_link`; with neither, the sentence
   stops at "voted on the question itself".

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
