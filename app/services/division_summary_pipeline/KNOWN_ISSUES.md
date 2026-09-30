# Known issues in the division summary pipeline

`ARCHITECTURE.md` explains how this pipeline is meant to work. This file records where it does
not, so that the next person to pick it up starts from what is already known rather than
rediscovering it.

Entries are numbered `KI-n` so they can be cited from commits, issues and code comments. Numbers
are never reused. A fixed entry is kept as one line in the index below, naming the spec that
guards the fix, so a citation in the code still resolves. The full write-up of every fixed entry,
with the procedural sources and the reproduction, is in git history, as the lines removed by the
commit that condensed it: the first command below for KI-1 to KI-29, and the second for KI-35.

```
git log -p --grep='^Condense the known issues' -- app/services/division_summary_pipeline/KNOWN_ISSUES.md
git log -p --grep='^Read the chair' -- app/services/division_summary_pipeline/KNOWN_ISSUES.md
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

KI-38 and KI-39 came from checking the draft for Senate 20 August 2026 #23 against Hansard in
September 2026, after three local models all quoted the same passage as the mover's explanation,
then comparing Stage 1 before and after the fix over the 3,856 speeches in the ParlParse XML for
Senate 18 to 20 August 2026 and the eight test divisions' sitting days.

KI-40 onwards came from running four local models over ten divisions from 12 to 20 August 2026 on
30 September 2026, reviewing every draft against Hansard, and checking the proposed changes against
the chambers' standing orders and guides. That
check found that some of the pipeline's House procedure had been written from the House Guide
(2017, amended 2019), which predates changes to the House standing orders in 2020, 2022, 2023 and
2025: the standing orders "as at 23 July 2025" outrank it. The Senate standing orders consulted were
the June 2009 edition, so a Senate standing order is cited only where a June 2025 Senate guide says
the same, or after checking the current text.

This register was compiled with AI assistance (Claude Code: claude-opus-5[1m] for KI-1 to KI-19,
claude-opus-5-5 for KI-20 to KI-39 and later, and for condensing the fixed entries). The procedural
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
| KI-5 | High | Fixed | Absolute-majority questions were reported on a simple-majority test | `template_compiler_spec.rb` "constitutional and parliamentary procedures" and "Template 17, the purpose a suspension states for itself". The pipeline flags the doubt rather than resolving it: the question alone does not say how a suspension was moved. Corrected in September 2026 against House S.O. 47 as at 23 July 2025: a House suspension without notice is also carried by a majority of those present if the Leader of the House and the Manager of Opposition Business agree, and "by leave" is said only of the House, where the House Guide (pp. 2-3) supports it; neither Senate source mentions it ("gives each chamber's own ways to carry a suspension on a simple majority"). |
| KI-6 | Medium | Fixed | Deferred and successive divisions defeated the context window | `context_builder_spec.rb` "context warnings". The S.O. 133 time windows are this code's own estimate, not a figure from either guide; they only raise a warning. Corrected in September 2026 against House S.O. 133 as at 23 July 2025: the Tuesday window after the matter of public importance came from the guide and is no rule of S.O. 133 (it was S.O. 55(c), on quorum counts), so it is gone ("does not warn about a Tuesday afternoon"). S.O. 133(b) now defers evening divisions from Monday to Wednesday "until the first opportunity the next sitting day", which fixes no time; a window for it caught only programmed questions, so it rests on the chair's words, as a deferral on another day already did. |
| KI-7 | Medium | Fixed | Template 24 stated the wrong suspension period and the House wording in the Senate | `template_compiler_spec.rb` "Template 24, suspension periods and the two chambers' wording". Corrected again in September 2026 against House S.O. 94(d) as at 23 July 2025: the first suspension is the 24 hours from the time of suspension, and only the second and third leave out the day. The Senate guide does not state S.O. 204's periods, so none are given. The June 2009 standing orders give them (the remainder of that day's sitting, then 7 and 14 sitting days in the same calendar year), and a July 2025 edition exists on aph.gov.au, which refuses automated fetches: **Verify** S.O. 204 in the current edition, and state the periods only then. |
| KI-8 | Medium | Fixed | House quorum hardcoded against a 2019 date | `template_compiler_spec.rb` "constitutional and parliamentary procedures". Chamber size comes from the member records on the day; the dated constant is only the fallback. |
| KI-9 | Medium | Fixed | Template 2 overstated what carrying a reasoned amendment does | Template 2's explainer (no spec). |
| KI-10 | Medium | Fixed | Template 17 asserted a purpose the question usually does not support | `template_compiler_spec.rb` "Template 17, the purpose a suspension states for itself". |
| KI-11 | Medium | Fixed | `declines_second_reading` was left to the model when the guides give a closed list of forms | `provenance_validator_spec.rb` "declines_second_reading against the motion text". Extended in September 2026 (`provenance_validator_spec.rb` "with the forms whose words settle it"): the words also settle it as declining when the amendment rejects the bill (the Senate's usual form) or would finally dispose of it (House S.O. 146, "now" to "not"; Senate S.O. 114(2), "this day 6 months"), and as not declining when a Senate amendment only adds words expressing an opinion. An addition that refers or delays the bill is left to the model (Senate Guide No. 16), and a House amendment that adds words, which S.O. 145(a)(iii) does not allow, is a warning. The House's "disapproves of ... charges" form is no longer listed as not declining: the guide does not classify it. |
| KI-12 | Low | Fixed | Template copy the guides sharpen (1, 3, 4, 5, 8, 9, 10, 14, 16, 18, 20, 22, 25, 26, 27, 28) | Template text (no spec). Template 23 was checked and is right: the Senate has no gag. Checked against the House Guide (2017), which the House standing orders have since overtaken: Template 18's House half was out of date until KI-47. |
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
| KI-24 | Medium | Fixed | The mover was whoever the model credited, or "a member" | `mover_finder_spec.rb`, `template_compiler_spec.rb`, `division_summarizer_spec.rb`. The September 2026 local model run found "a motion introduced by a member" still in Template 12's vote sentence, and House members titled "Representative Kate Chaney", which is not Australian usage. Every template now prints the mover through `{{mover_clause}}`, which is empty with no mover, and House members are named in the site's own form, "Kate Chaney MP" (`Member#full_name_no_electorate`), the member in the chair too (`template_compiler_spec.rb` "naming members of the House"). |
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
| KI-35 | Medium | Fixed | A lead-in sentence before the chair's question could decide the route, and so could the amendments Hansard prints after it, or an earlier question in the same statement | `chair_statement_spec.rb` "#question"; `division_xml_spec.rb` "#operative_question"; `context_builder_spec.rb` "when the chair puts amendments nobody moved in the chamber"; `procedural_router_spec.rb` "routes the chair's question sentence, whatever the rest of the statement said". `ChairStatement` reads the statement once: the division's question is the last question sentence of the chair's own words ("The question is", "now is", "first", "immediate", "next"), after any question closed by "Question agreed to." and the like. Comparing routes over the 121 loaded divisions of May to September 2026 moved 42, every one a correction: seven questions had been settled on words in the chair's lead-in (three as closures because it said "I'll now put the question", one as a guillotine because it said "time allotted") and a dozen statements put and closed one question before putting the division's. MoverFinder reads the paragraphs that put the question, where the chair often names the mover. |
| KI-36 | Medium | Fixed | A question put once a guillotine's time had expired never said so, so a draft read as an ordinary vote with nobody moving or debating it | `division_xml_spec.rb` "#limitation_of_debate_statement"; `context_builder_spec.rb` "when a guillotine's time has expired"; `template_compiler_spec.rb` "says the question was put under a limitation of debate". Found by rule from the chair's statement, which can be dozens of divisions back under another bill's heading. A senator asking by leave or on indulgence to have their position recorded no longer stops the search (`division_xml_spec.rb` "walks past a senator asking by leave or on indulgence to have their position recorded"): on 18 August 2026 that had left two of the four divisions under the second reading's guillotine unmentioned, the second reading itself among them, and both are now found. Any other speech by leave, such as tabling a document, still stops it. |
| KI-37 | Medium | Fixed | Earlier debate was matched by heading alone, so a question put under "; Limitation of Debate" never found the amendment moved under the same bill's "; Second Reading" | `debates_xml_headings_spec.rb`, `division_xml_spec.rb` "finds the same bill's debate under another heading"; `earlier_debate_spec.rb`, `mover_finder_spec.rb`, `context_builder_spec.rb`. Sections are also matched by the bills listed under their headings. Such a move is only kept when the chair names its mover and nothing under the division's own heading was found: an unnamed one, such as a second reading question straight after the amendment, belongs to a different question. |
| KI-38 | High | Fixed | Words a member quoted or read out were quoted as the member's own explanation | `speech_text_spec.rb` "labels an italic paragraph that follows no move as a quotation"; `transcript_spec.rb` "keeps a passage the member quoted whole"; `provenance_validator_spec.rb` "when the mover quotes someone else"; `earlier_debate_spec.rb` "keeps the run round the move when the speech also quotes someone far from it". At Senate 20 August 2026 #23 all three models picked a sentence of the Prime Minister's 2003 words that the mover had read out, and the draft printed it under the mover's name. Hansard sets quoted material in italic, so an italic paragraph that is neither a motion nor part of an incorporated speech is now a `:quotation` unit, which the validator never accepts as an explanation. Still open: a short quote inside a member's own sentence ("they say: 'No worries!'") is not set apart, and neither is a quote inside an incorporated speech, so those rest on the model and the reviewer. |
| KI-39 | Medium | Fixed | An incorporated second reading speech opening with the House's "I move that this Bill be now read a second time." was read as a move, and the whole speech as its terms | `speech_text_spec.rb` "a speech incorporated by leave" and "reads a move made while presenting a report or tabling a document". Three Senate speeches on 19 and 20 August 2026 gave 7,339 to 14,500 characters of speech as the motion moved; none of the sitting days checked has a division on those bills, so none of the drafts checked here used it. Fixing it exposed that "I table ... and move:" was never read as a move either, so one of the three ministers had been found only through the copied line; tabling and presenting forms are now read. |
| KI-41 | High | Fixed | A chair's statement over 1,200 characters was not taken for the chair's, so a draft said the question was never recorded, and quoted all 45,679 characters when it was | `division_xml_spec.rb` "is the chair's statement however many amendments Hansard prints in it"; `transcript_spec.rb` "#question_units"; `provenance_validator_spec.rb` "quotes only the chair's words putting the division's question"; `earlier_debate_spec.rb` "keeps a long statement of the chair's putting another question". The size limit is applied to the plain paragraphs only: the italic ones are the amendments being put. Question Put quotes the chair's words putting the division's question, and the earlier debate keeps only the chair's words from earlier statements. |
| KI-42 | High | Fixed | The validator accepted the chair putting a question as the terms of the motion moved | `provenance_validator_spec.rb` "never takes the chair putting or deciding a question as the terms moved". A model motion reference whose text is a chair's question sentence or "Question agreed to." and the like is refused with a warning, whoever the transcript says spoke it: at Senate 18 August 2026 #16 a draft printed "The question now is that amendments ... be agreed to." as the amendment moved. |
| KI-43 | High | Fixed | Amendments nobody moved were credited to whoever last moved anything: a party's circulated amendments to the minister who had moved the second reading, with the minister's case for the bill offered as the case against it | `mover_finder_spec.rb` "does not credit a move whose terms cannot be what the question puts", "does not guess an unnamed mover for amendments the chair says were circulated"; `chair_statement_spec.rb` "#circulated_by"; `context_builder_spec.rb` "when the chair puts amendments nobody moved in the chamber"; `template_compiler_spec.rb` "amendments the chair put without anyone moving them". An unnamed move counts only when its terms could be what the question puts, and not at all when the chair says the amendments were circulated. Who circulated them is found by rule, from the chair's words or Hansard's heading over them, and the draft says "circulated by the Australian Greens ... were put", never "moved". Every template now prints the mover through `{{mover_clause}}`, so a draft with no mover says nothing rather than "introduced by a member". With no mover, an explanation can only be the circulating member's words. |
| KI-44 | Medium | Fixed | The terms of amendments the chair put under a limitation of debate were left for the model to find, though the chair's statement prints them | `transcript_spec.rb` "takes the amendments printed after the division's question as its terms"; `context_builder_spec.rb` "takes the amendments the chair put as the terms", "keeps the plain headings Hansard sets among the amendments"; `extraction_prompt_spec.rb` "tells the model when the chair put amendments nobody moved"; `division_summarizer_spec.rb` "does not widen for amendments the chair put". The paragraphs after the question sentence, up to the next record or question, are the terms, found by rule, when the question refers to amendments; in the House, unmoved opposition amendments are sometimes printed only for the record (House Guide p. 75), so nothing else is taken. 26 of the 121 loaded divisions now have their terms found by rule, and none of them sends the model to the sitting day for them. |
| KI-45 | Medium | Fixed | Template 28 did not say which parts of the bill were to stand as printed, or whose amendments to omit them the vote decided | `template_compiler_spec.rb` "names the parts the question named, and who circulated the amendments to omit them". The parts are the chair's words between "that" and "stand as printed" in the division's question, quoted, and who circulated the amendments comes from `Circulation`. |
| KI-46 | High | Fixed | Every closure not on a bill said "to end the debate on bill", and one on a bill left out "the" | `template_compiler_spec.rb` "Template 22, a closure on a bill and on anything else"; the evaluation corpus fixture 2. With no bill the sentence ends the debate and names none. `bill_reference` was checked everywhere else it is used: every other use follows "the". |
| KI-47 | Medium-High | Fixed | Template 18 described the House guillotine from the House Guide (2017): a declaration of urgency followed by a motion allotting time. S.O.s 83 and 84 were omitted on 27 July 2022, and there is no allotment of time any more | Template text (no spec). Rewritten from House S.O. 82 and 85 as at 23 July 2025: the declaration of urgency, one evening's second reading debate to 10 pm, the questions then put without debate at the next sitting, circulated amendments treated as moved and put in groups (government, opposition, each crossbench member), and no closure. The catalogue line and the router's reason say the same. The Senate half matches Senate Guide No. 17 and was kept. Checking the other House standing orders the pipeline cites found two more changed since the guide: S.O. 80 (2025) now bars the gag while a member is moving the terms of a motion, which Template 23 now says, and S.O. 122 (July 2019) now puts "That the amendment be agreed to", noted under KI-4. S.O. 47, 94 and 133 changed too (KI-5, KI-7, KI-6). S.O. 31 and 131 were reread and say what the pipeline says of them; S.O. 11, 46, 58, 81, 87, 135, 150, 153, 173, 188 and 202 have not been amended since the guide, so the earlier check against it stands. S.O. 29 was amended in 2022, but only its sitting times. |
| KI-49 | Medium | Fixed | Subject rules outranked the bill-stage rules, so a reasoned amendment read out as the question was settled as whatever it named: a select committee, or a censure | `procedural_router_spec.rb` "routes the form proposing a select committee to Template 2", "routes a Budget amendment worded as a censure to Template 2", "leaves the same form amending an ordinary motion to the other rules". `reasoned_amendment_form` settles Template 2 when the question reads out an amendment's own form in a second reading debate, before any subject rule. None of the 121 loaded divisions changed route; since KI-35, the Senate's questions no longer carry the amendments' words, so this is for a House chair reading an amendment out. KI-13's note that the Budget case already worked was wrong and has been corrected. |
| KI-50 | Medium-High | Fixed | A motion whose first paragraph Hansard sets as "That—" alone was routed on that one word, so the Senate's order fixing a week's hours and guillotines fell to the general motion fallback | `context_builder_spec.rb` "routes a motion whose first paragraph is only \"That\" on the paragraphs after it". `ContextBuilder#operative_paragraph` reads every paragraph after a bare "That", where the order says its parts "operate as limitations of debate under standing order 142", and the existing rule gives Template 18, advisory, since the opening is not a fixed form. Only Senate 18 August 2026 #2 moved in the 121 loaded divisions. |
| KI-51 | Low | Fixed | The plain second reading question ("That the bill be now read a second time") was fenced between Templates 2 and 29 though it names no amendment | `procedural_router_spec.rb` "settles the plain second reading question on Template 29", "fences a second reading question that is not in the plain form". Settled as Template 29 in that form with no amendment wording and not "as amended"; anything else still fenced. Three of the 121 loaded divisions moved from the fence to 29, each a plain second reading. |
| KI-52 | Medium | Fixed | A House question put "immediately" under a resolution agreed earlier read as an ordinary debated vote, though the Senate's equivalent was flagged | `division_xml_spec.rb` "finds the Speaker putting the question immediately under a resolution, across the run of divisions"; `template_compiler_spec.rb` "a question the House put immediately under a resolution agreed earlier". Found by rule like the Senate's statement, walking back through the run of divisions, and kept as its own kind: the House programming a bill by suspending standing orders is not a guillotine (House Guide p. 75), so the draft says "This question was put without further debate, under an arrangement the House of Representatives agreed on 12 August 2026", the date from the Speaker's words, and quotes them. Only three forms have been seen, all on 18 August 2026; what the Speaker says under the House's own guillotine for urgent bills (S.O. 82 and 85) is **Verify** before this is extended to it. |
| KI-53 | Medium | Fixed | A divided question was summarised, and its motion printed, as though the whole motion had been put | `chair_statement_spec.rb` ".divided_parts"; `template_compiler_spec.rb` "a divided question". When the chair's question puts a motion "minus" or "except" some of its parts, the draft says the vote was on the motion without them, in the chair's words, and the Reviewer Only report says the question was divided. Senate forms only: the House, where a member may move that a question be divided (House S.O. 119), had none in its Hansard from May to September 2026, so none is assumed. A divided question put on the separated part itself is not recognised. |
| KI-54 | Medium | Fixed | A closure's draft said only that "the debate" ended, and never linked the division that then put the underlying question | `context_builder_spec.rb` "with a closure"; `template_compiler_spec.rb` "says what the debate it ended was on". Stage 1 routes the move the closure cut short (the last one before the closure's own, in the same debate, by someone else) and keeps the template when that settles one, which the sentence names: "to end the debate on a motion to suspend standing orders". The follow-up division is the next that day in the same debate, unless it is a closure itself, looked up in the database. ARCHITECTURE.md section 15's `followup_link` item is built. |

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
| "That the words proposed to be omitted stand part of the question" | House Guide p. 52; House S.O. 122 before 4 July 2019 | An inverted question like Template 28; the guide calls the form "no longer used" in the House, and since 4 July 2019 S.O. 122 has the Speaker put "That the amendment be agreed to". |

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
appropriation bill is conventionally cast as a censure of the Budget (House Guide p. 81-82). This
entry used to say the router handled that because the second reading rules came before Template 10;
they did not, and such an amendment read out as the question was settled as a censure until
`reasoned_amendment_form` was put before the subject rules in September 2026
(`procedural_router_spec.rb` "routes a Budget amendment worded as a censure to Template 2").

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
