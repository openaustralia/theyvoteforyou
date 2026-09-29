# Known issues in the division summary pipeline

`ARCHITECTURE.md` explains how this pipeline is meant to work. This file records where it does
not, so that the next person to pick it up starts from what is already known rather than
rediscovering it.

Entries are numbered `KI-n` so they can be cited from commits, issues and code comments. Numbers
are never reused. A fixed entry is kept as one line in the index below, naming the spec that
guards the fix, so a citation in the code still resolves. The full write-up of every fixed entry,
with the procedural sources and the reproduction, is in git history, as the lines removed by the
commit that condensed it:

```
git log -p --grep='^Condense the known issues' -- app/services/division_summary_pipeline/KNOWN_ISSUES.md
```

## Where these findings came from

KI-1 to KI-19 came from reading the pipeline against the two official procedural guides in
September 2026:

- **House of Representatives, _Guide to Procedures_, 6th edition 2017** (reprinted September
  2018, amended June 2019), Department of the House of Representatives. Cited below as
  "House Guide" with the guide's own printed page numbers.
- **_Guides to Senate procedure_**, Department of the Senate, the 23 numbered guides, each
  marked "Last reviewed: June 2025". Cited below as "Senate Guide No. _n_".

Both are Commonwealth publications licensed CC BY-NC-ND 3.0 AU, so neither is committed to this
repository. Download them from aph.gov.au if you need to check a citation. Neither guide is the
last word: `House of Representatives Practice` and `Odgers' Australian Senate Practice` are the
definitive texts, and both guides say so. For anything load-bearing, check there before
publishing.

KI-20 to KI-29 came from running the pipeline with seven Bedrock models over eight real divisions
from May and September 2026 (Senate 14 September #7, 16 September #15, 17 September #5 and #10;
House 14 May #1, 28 May #5, 14 September #1, 17 September #2), then replaying each day's
ParlParse XML through Stages 1 and 2 and running Stages 4 and 5 offline.

KI-30 came from restructuring the router in September 2026, when its routes were compared with
the previous router's over 173,880 generated questions.

KI-31 to KI-35 came from running the pipeline against local models through llama.cpp in September
2026 (Senate 20 August #32, a bill passed under a guillotine), then replaying the model's intended
answer, and the router's default, through Stages 4 and 5 with the model call stubbed out.

KI-36 and KI-37 came from checking that same division's draft against Hansard in September 2026,
then replaying the Senate's ParlParse XML for 18 to 20 August 2026 (69 divisions, 47 of them put
under one of five guillotines) through Stage 1.

This register was compiled with AI assistance (Claude Code: claude-opus-5[1m] for KI-1 to KI-19,
claude-opus-5-5 for KI-20 to KI-37 and for condensing the fixed entries). The procedural
citations should be checked against the guides named above.

## How findings were verified

- **Confirmed** means the behaviour was reproduced by running the code, not inferred from
  reading it.
- **Read** means it follows from the source but was not executed.
- **Verify** means it needs checking against a primary source before anyone acts on it.

## Index

| ID | Severity | Status | Summary | Guarded by, and what is still worth knowing |
|---|---|---|---|---|
| KI-1 | High | Fixed | Template 6's closing sentence ignored the vote result, and named a destination chamber the data cannot support. The second reading, which Template 6 then also covered, is now Template 29 | `template_compiler_spec.rb` "Templates 29 and 6, reporting the result of the reading and not just the reading". The destination is stated only when `bill_originating_house` is supplied; nothing supplies it yet. |
| KI-2 | High | Fixed | Template 7 read every message question as "agree to the other chamber's amendments" | `template_compiler_spec.rb` "Template 7, the forms a message question takes". Still open: insisting on an amendment that itself omitted a clause (Odgers', via Senate Guide No. 18) is not told apart from an ordinary insist. |
| KI-3 | High | Fixed | Template 22 contradicted itself for "the business of the day be called on" | `template_compiler_spec.rb` "Template 22, the three questions that arrive as a closure". A template per closure form would be tidier; that is a catalogue decision. |
| KI-4 | High | Partly fixed | Real question forms fall through to Template 15 | See the open entry below. |
| KI-5 | High | Fixed | Absolute-majority questions were reported on a simple-majority test | `template_compiler_spec.rb` "constitutional and parliamentary procedures" and "Template 17, the purpose a suspension states for itself". The pipeline flags the doubt rather than resolving it: the question alone does not say how a suspension was moved. |
| KI-6 | Medium | Fixed | Deferred and successive divisions defeated the context window | `context_builder_spec.rb` "context warnings". The S.O. 133 time windows are this code's own estimate, not a figure from either guide; they only raise a warning. |
| KI-7 | Medium | Fixed | Template 24 stated the wrong suspension period and the House wording in the Senate | `template_compiler_spec.rb` "Template 24, suspension periods and the two chambers' wording". The Senate guide does not state S.O. 204's periods, so none are given. |
| KI-8 | Medium | Fixed | House quorum hardcoded against a 2019 date | `template_compiler_spec.rb` "constitutional and parliamentary procedures". Chamber size comes from the member records on the day; the dated constant is only the fallback. |
| KI-9 | Medium | Fixed | Template 2 overstated what carrying a reasoned amendment does | Template 2's explainer (no spec). |
| KI-10 | Medium | Fixed | Template 17 asserted a purpose the question usually does not support | `template_compiler_spec.rb` "Template 17, the purpose a suspension states for itself". |
| KI-11 | Medium | Fixed | `declines_second_reading` was left to the model when the guides give a closed list of forms | `provenance_validator_spec.rb` "declines_second_reading against the motion text". |
| KI-12 | Low | Fixed | Template copy the guides sharpen (1, 3, 4, 5, 8, 9, 10, 14, 16, 18, 20, 22, 25, 26, 27, 28) | Template text (no spec). Template 23 was checked and is right: the Senate has no gag. |
| KI-13 | Low | Partly fixed | Template 2 described one of the four things a stage amendment can do | See the open entry below. |
| KI-14 | Low | Fixed | `ARCHITECTURE.md` drift: template count, adjournment, Senate quorum | Documentation. |
| KI-15 | High | Fixed | `declines_second_reading` and `sufficient_context` were coerced to true whatever the model returned | `extraction_payload_spec.rb` "boolean fields". |
| KI-16 | High | Fixed | A suspension of standing orders was routed as whatever motion it quoted | `procedural_router_spec.rb` "suspension of standing orders is matched before the motion it would enable". The suspension rule must stay first in the router. |
| KI-17 | Medium | Fixed | The compiler's grammar tidying edited quoted Hansard | `template_compiler_spec.rb` "verbatim quoted text". |
| KI-18 | Medium | Open | A tied House division cannot be resolved from the recorded figures | See the open entry below. |
| KI-19 | Low | Verify | Template 21 cites the Parliament Act 1974, which neither guide mentions | See the open entry below. |
| KI-20 | High | Fixed | Stage 1 misread current ParlParse XML: glued paragraphs, and no motion text | `speech_text_spec.rb`, `division_xml_spec.rb`, `context_builder_spec.rb` "Hansard in the shape current ParlParse produces". Current XML has no `pwmotiontext`; the terms moved are italic paragraphs after "I move". |
| KI-21 | High | Fixed | A deferred division, or a long debate, left the motion out of the packet | `earlier_debate_spec.rb`, `context_builder_spec.rb`, `division_xml_spec.rb`. |
| KI-22 | High | Fixed | Almost every division was called a conscience vote | `template_compiler_spec.rb` "facts the drafts from real divisions got wrong". `Whip#free_vote?`'s list stops at 1 December 2022, so a later conscience vote is not called one until someone adds it. |
| KI-23 | Medium | Fixed | Real question forms routed to the wrong template or too wide a fence | `procedural_router_spec.rb` "routing on the motion as moved" and "questions taken from recent Hansard"; `semantic_extractor_spec.rb`. |
| KI-24 | Medium | Fixed | The mover was whoever the model credited, or "a member" | `mover_finder_spec.rb`, `template_compiler_spec.rb`, `division_summarizer_spec.rb`. |
| KI-25 | Medium | Fixed | Stage 4 rejected genuine quotes over formatting, and let weak evidence through | `provenance_validator_spec.rb`, `text_normaliser_spec.rb`. |
| KI-26 | Low | Fixed | Wording built from verbatim text read badly in Templates 2, 16, 17 and 19 | `template_compiler_spec.rb`. |
| KI-27 | Medium | Fixed | The context retry leaked one model's note and re-routed the division | `context_builder_spec.rb`, `semantic_extractor_spec.rb`, `division_summarizer_spec.rb`. |
| KI-28 | Medium | Fixed | Validator warnings and the review flag were thrown away | `reviewer_report_spec.rb` "lists the fallbacks, the warnings and how the mover was found"; `division_summarizer_spec.rb`. Every draft, a failed one included, ends with a fixed Reviewer Only report carrying Stage 1's context warnings, the validation errors and warnings, and the fallbacks used. |
| KI-29 | Medium | Partly fixed | Findings from the same audit | See the open entry below: one finding is still open, and each fixed one names its spec. |
| KI-30 | Low | Open | The router's bill-title stripping can take a capitalised "Amendment" that is not in a title | See the open entry below. |
| KI-31 | Medium | Fixed | "That the remaining stages of the bill be agreed to, and the bill be now passed" fell to the general motion fallback | `procedural_router_spec.rb` "routes the remaining stages being agreed to and the bill passed to Template 6". A model that took the fallback's default compiled a valid draft that never said the bill passed. |
| KI-32 | Medium | Fixed | A question that is the whole motion sent the pipeline to read the whole sitting day | `extraction_prompt_spec.rb` "tells the model there are no terms to find when the question is the whole motion"; `division_summarizer_spec.rb` "when the question is the whole motion and the model reports its terms missing". The prompt told the model to report the terms missing whatever the question, and the retry read about 70,000 tokens that could not contain them. `ContextPacket::QUESTION_IS_THE_MOTION` lists the templates this applies to. |
| KI-33 | Medium | Fixed | A failed sitting day retry threw away a first reply that would have compiled | `division_summarizer_spec.rb` "when the retry over the whole sitting day fails"; `reviewer_report_spec.rb`. The draft is now built from the first reply and the Reviewer Only report says why. |
| KI-34 | Low | Fixed | Template 6 said "a motion introduced by a member" and "third reading" for the remaining stages question the chair puts | `template_compiler_spec.rb` "names every remaining stage, and no mover, when the question takes the remaining stages together". Its Bill Timeline still explains the third reading, which the remaining stages end with. |
| KI-35 | Medium | Open | A lead-in sentence before the chair's question can decide the route | See the open entry below. |
| KI-36 | Medium | Fixed | A question put once a guillotine's time had expired never said so, so a draft read as an ordinary vote with nobody moving or debating it | `division_xml_spec.rb` "#limitation_of_debate_statement"; `context_builder_spec.rb` "when a guillotine's time has expired"; `template_compiler_spec.rb` "says the question was put under a limitation of debate". Found by rule from the chair's statement, which can be dozens of divisions back under another bill's heading. A senator speaking by leave between the statement and the division stops the search, so the draft then says nothing about it: on 18 August 2026 that left two of the four divisions under the second reading's guillotine unmentioned. |
| KI-37 | Medium | Fixed | Earlier debate was matched by heading alone, so a question put under "; Limitation of Debate" never found the amendment moved under the same bill's "; Second Reading" | `debates_xml_headings_spec.rb`, `division_xml_spec.rb` "finds the same bill's debate under another heading"; `earlier_debate_spec.rb`, `mover_finder_spec.rb`, `context_builder_spec.rb`. Sections are also matched by the bills listed under their headings. Such a move is only kept when the chair names its mover and nothing under the division's own heading was found: an unnamed one, such as a second reading question straight after the amendment, belongs to a different question. |

---

## Open entries

### KI-4

**Real question forms fall through to Template 15.** Severity: High. Status: **Partly fixed**.
**Confirmed** by running each form through `ProceduralRouter.route`.

Template 15 is the fallback. "That the bill be considered urgent" now routes to Template 18, and
Template 15 no longer claims every question it receives "records an opinion ... and has no legal
effect". These forms still land there with no template that fits them:

| Question form | Source | What it actually is |
|---|---|---|
| "That the bill stand as printed" | Senate Guide No. 16 | The final question in committee of the whole when no amendments were agreed to. |
| "That the bill (as amended) be agreed to" | House S.O. 150(c), 153(a), Guide p. 72-73 | End of consideration in detail, or the report stage for a bill from the Federation Chamber. |
| "That the report of the committee be adopted" | Senate Guide No. 16 | Report from committee of the whole; amendments are moved to it. |
| "That the proposed expenditure(s) be agreed to" | House Guide p. 82 | The appropriation bill detail stage. |
| "That the House approves the form of agreement ..." | House Guide p. 94-95 | Approval of a legislative instrument, the mirror of disallowance. |
| "That the words proposed to be omitted stand part of the question" | House S.O. 122(a), 123(c), Guide p. 52 | An inverted question like Template 28; the guide calls the form "no longer used" in the House. |

Each needs its own template, which adds to the catalogue: a decision to agree with a human before
writing, not a change to make unilaterally. New templates are numbered after the last one (as
Template 29, the second reading, was) so that no template already cited by number moves.

### KI-13

**Template 2 describes the four things a stage amendment can do, but not which one this was.**
Severity: Low. Status: **Partly fixed**.

Senate Guide No. 16 gives the closed list: express an opinion, reverse the motion so the bill is
defeated at that point, refer the bill to a committee, or delay further consideration. The
explainer now lists all four. Still open: extracting which one applies, as a closed choice, so the
summary can say which. Worth doing once the evaluation corpus has enough Template 2 divisions to
tell whether the model gets it right. Two things to know while working here: a referral can arrive
as a second reading amendment (Senate S.O. 114(3)), and the second reading amendment on the main
appropriation bill is conventionally cast as a censure of the Budget (House Guide p. 81-82), which
the router handles only because the second reading rules come before Template 10.

### KI-18

**A tied House division cannot be resolved from the recorded figures.** Severity: Medium.
Status: Open.

In the Senate an equally divided question is lost (Constitution s 23, Senate Guide No. 3). In the
House the occupant of the Chair has a casting vote under s 40, which decides the question and is
not in the aye and no counts. The summary now reports a tied House division as "not decided by the
division figures, which were equal" and says the figures do not record the casting vote. Recovering
it means reading the Votes and Proceedings, where S.O. 135(c) requires the Speaker's reasons to be
recorded, and TVFY does not load that.

### KI-19

**Template 21 cites the Parliament Act 1974, which neither guide mentions.** Severity: Low.
Status: **Verify**.

The House guide confirms works in the parliamentary precincts can be subject to parliamentary
approval (p. 117) but names no Act, and the Senate guides do not cover it. The citation is probably
right and was left in, but it has not been checked against a primary source.

### KI-29

**Findings from the same audit.** Severity: Medium. Status: **Partly fixed**. Recorded as
**Read** when found: each was reported with a file reference but not reproduced.

Fixed by the "the model selects, it never writes" redesign (`docs/adr/0005-ai-summaries-select-never-author.md`),
each guarded by the spec named:

- A reply in the old title and description shape was saved without Stage 4. There is now one
  reply schema and no legacy path: `extraction_payload_spec.rb` "does not accept a reply in the
  old title and description shape", `division_summarizer_spec.rb` "when the model answers in the
  old title and description shape".
- "Amendment" in a bill's title triggered the amendment rule: `procedural_router_spec.rb` "a bill
  title that contains the word amendment". What the fix still gets wrong is KI-30.
- An unverifiable `motion_text` was only a warning. The motion is now Stage 1's, or a model
  reference that resolves, and a question that only refers to a motion nobody can find is a hard
  error: `provenance_validator_spec.rb` "the operative motion".
- A draft with no claims published "[No explanatory claims recorded]", and the claim cap was not
  enforced. The section now reads "No explanatory claims recorded.", and at most six sentences are
  quoted: `provenance_validator_spec.rb` "quotes at most six sentences, the first ones spoken",
  `evaluation_spec.rb`.
- Every mover's statement was dated with the division's time. Each quote now carries its own
  speech's time: `template_compiler_spec.rb` "quotes each passage under the time of the speech and
  the mover's name".
- Claims were the model's paraphrase set as quotations. There are no claims any more, only
  Hansard's own sentences retrieved by reference: `provenance_validator_spec.rb`,
  `reviewer_report_spec.rb` "contains nothing the model wrote".
- The draft title was the model's `topic`. It is built by rule from the heading and the template:
  `draft_title_spec.rb`.
- The Senate's Template 2 explainer described only the House: `template_compiler_spec.rb`
  "Template 2's explainer in each chamber".
- "Large majority" meant any majority over half the turnout. The draft now uses the division page's
  thresholds, repeated from `DivisionsHelper` because the helper builds HTML:
  `division_facts_spec.rb` ".majority_strength".

Still open:

- No draft says it was drafted with AI or by which model. The Reviewer Only report records the
  model for reviewers, but that section is removed before publishing. How a published summary
  should say so is a decision for the team, since drafts are meant for the public site.

### KI-30

**The router's bill-title stripping can take a capitalised "Amendment" that is not in a title.**
Severity: Low. Status: Open. **Confirmed** by routing the forms below.

KI-29's fix removes bill titles ("... Amendment Bill 2026") from the question before looking for
amendment wording. A title is recognised by its capitalised words, so a capitalised "Amendment"
just before a bill's name can be taken as part of the title: "That the Opposition Amendment to the
Example Bill 2026 be agreed to" loses the amendment it is about. And "That the Example Amendment
Bill 2026 be disagreed to" now reaches the fallback instead of Template 7, because only the title
said "amendment". No real question in either form has been seen; both came from comparing the old
and new routers over generated questions. `procedural_router_spec.rb` "a bill title that contains
the word amendment" is where a fix would be tested.

### KI-35

**A lead-in sentence before the chair's question can decide the route.**
Severity: Medium. Status: Open. **Confirmed** by routing Senate 20 August 2026 #17.

`DataLoader::DivisionXml#operative_question` (`app/lib/data_loader/division_xml.rb`) returns the
whole of the chair's statement before a division, and everything that reads the question reads all
of it: the router, `ContextPacket#question_by_reference?` and `#question_states_motion?`, and the
prompt's `<speaker_question>`. So when the chair says something before putting the question, those
words are treated as part of it. At Senate 20 August 2026 #17 the statement was:

> As that matter was resolved in the affirmative, the consequential amendment on sheet 3791 will
> not be put. The question now is that the remaining stages of the bill be agreed to and the bill
> be now passed.

Two things go wrong, both from the first sentence:

- Its "amendment", under a "Limitation of Debate" heading, fences the division to Templates 2 and
  3 (`GUILLOTINE_TRAP_AVOIDED`), so Stage 4 would refuse Template 6, the template KI-31 now settles
  this question on. Routed on the second sentence alone, it settles on Template 6
  (`REMAINING_STAGES_PASSING`).
- Its "on sheet 3791" matches `QUESTION_BY_REFERENCE`, so the question is taken to refer to a motion
  it does not need. Stage 1 finds no motion, and the packet is widened to the whole sitting day
  before the model is asked at all, the long call KI-32 removed for this question.

The likely fix is to route on the last "The question is ..." or "The question now is ..." sentence
of the statement. The "Question Put" section of a draft quotes the chair from
`DivisionXml#question_speech`, not from `operative_question`, so it would still quote the whole
statement. Before settling on a fix:

- A statement can also run on past the question: `division_xml_spec.rb` "keeps the paragraph breaks
  of the chair's statement when there is no pwmotiontext" expects "Question negatived." after it.
- A statement can put more than one question in turn, and the division follows the last one put.
- Check the chair's forms of words in current Hansard before choosing the pattern. Only the two
  above were seen here.
- The fix changes the route of every division whose chair statement has a lead-in. How many do is
  not known, since only this division was checked, so compare routes before and after over the
  loaded divisions.

A fix would be tested in `division_xml_spec.rb` "#operative_question" (or `context_builder_spec.rb`,
if it is made there instead) and in `procedural_router_spec.rb` "questions taken from recent
Hansard".
