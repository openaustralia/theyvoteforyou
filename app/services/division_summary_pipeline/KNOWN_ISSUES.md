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

KI-40 to KI-61 came from running four local models over ten divisions from 12 to 20 August 2026 on
30 September 2026, reviewing every draft against Hansard, and checking the proposed changes against
the chambers' standing orders and guides. That check found that some of the pipeline's House
procedure had been written from the House Guide (2017, amended June 2019), which predates every
change to the House standing orders from 4 July 2019 to 23 July 2025: the standing orders "as at 23
July 2025" outrank it. The Senate standing orders consulted then were the June 2009 edition. The
July 2025 edition replaced them on 1 October 2026, and every Senate standing order the pipeline
cites kept its number and substance.

KI-62 to KI-65 came from the first run of `rake ai:draft_local`, with Qwen3.6-35B-A3B (UD-Q4_K_M)
through llama.cpp, over the 13 divisions of 17 September 2026 on 12 October 2026, comparing each
draft's mover and motion with the day's ParlParse XML.

KI-67 and KI-79 came from the same task's run over 16 September 2026 on 13 October 2026: the draft
for House 16 September 2026 #6, and the prompt and reply saved for its sitting-day retry.

KI-68 to KI-78, and the changes to KI-4, KI-5, KI-6, KI-7, KI-13, KI-44, KI-47, KI-50, KI-52 and
KI-58, came from a second local model run on 1 October 2026, four models over the same ten
divisions from 12 to 20 August 2026 with every draft checked against Hansard, and from checking
about 190 of the pipeline's procedural claims against the House standing orders as at 23 July
2025, the House Guide, the Senate standing orders of July 2025 and the June 2025 Senate guides.
Every rule those entries cite, and the Hansard each one quotes, was checked again on 13 October
2026.

KI-80 onwards, and the changes to existing entries made with them, came from a review, begun on
15 October 2026, of the drafts from `rake ai:draft_local`'s run over the 910 divisions from 19
January to 17 September 2026 (712 Senate, 198 House). The drafts were made with Qwen3.6-35B-A3B
(UD-Q4_K_M) through llama.cpp between 12 and 15 October 2026: 867 compiled, and the 43 that failed
were reviewed as failures, without a retry. The review first studied each kind of vote in each
chamber from the House standing orders as at 23 July 2025, the House Guide, the Senate standing
orders of July 2025 and the June 2025 Senate guides, and then, for each division, worked out from
the day's ParlParse XML and those rules what a correct draft would say before comparing the draft,
and the pipeline's route to it, with that.

This register was compiled with AI assistance (Claude Code: claude-opus-5[1m] for KI-1 to KI-19,
claude-opus-5-5 for KI-20 onwards and for condensing the fixed entries; the 1 October 2026 review
behind KI-68 to KI-78 also used helper agents on claude-opus-5-5 and claude-sonnet-5, and the
review behind KI-80 onwards used helper agents on claude-opus-5-5). The procedural citations should
be checked against the documents named above.

## How findings were verified

- **Confirmed** means the behaviour was reproduced by running the code, not inferred from
  reading it.
- **Read** means it follows from the source but was not executed.
- **Inferred** means it is a conclusion drawn from the evidence rather than observed, and the
  entry says what it rests on.
- **Verify** means it needs checking against a primary source before anyone acts on it.

## Index

**Kind** says what it takes to tell whether a draft is right. **Rules**: a standing order or
procedural guide is needed. **Pipeline**: the code, the prompt, the drafts and Hansard are enough.
Every entry has one kind, so every issue has one place, and the open entries are grouped by it.

| ID | Kind | Severity | Status | Summary | Guarded by, and what is still worth knowing |
|---|---|---|---|---|---|
| KI-1 | Pipeline | High | Fixed | Template 6's closing sentence ignored the vote result, and named a destination chamber the data cannot support. The second reading, which Template 6 then also covered, is now Template 29 | `template_compiler_spec.rb` "Templates 29 and 6, reporting the result of the reading and not just the reading". The destination is stated only when `bill_originating_house` is supplied; nothing supplies it yet. |
| KI-2 | Rules | High | Fixed | Template 7 read every message question as "agree to the other chamber's amendments" | `template_compiler_spec.rb` "Template 7, the forms a message question takes". Still open: insisting on an amendment that itself omitted a clause (Odgers', via Senate Guide No. 18) is not told apart from an ordinary insist. The same goes for a tie: on "does not insist", `SummaryWording#not_insist_effect_clause` says the amendments are not insisted on, but where the amendment was one to omit a clause, an equal vote means "the amendment to omit the clause is insisted on" (Senate Guide No. 18, p. 56). |
| KI-3 | Pipeline | High | Fixed | Template 22 contradicted itself for "the business of the day be called on" | `template_compiler_spec.rb` "Template 22, the three questions that arrive as a closure". A template per closure form would be tidier; that is a catalogue decision. |
| KI-4 | Rules | High | Partly fixed | Real question forms fall through to Template 15 | See the open entry below. |
| KI-5 | Rules | High | Fixed | Absolute-majority questions were reported on a simple-majority test | `template_compiler_spec.rb` "constitutional and parliamentary procedures" and "Template 17, the purpose a suspension states for itself". The pipeline flags the doubt rather than resolving it: the question alone does not say how a suspension was moved. Corrected in September 2026 against House S.O. 47 as at 23 July 2025: a House suspension without notice is also carried by a majority of those present if the Leader of the House and the Manager of Opposition Business agree, and "by leave" is said only of the House, where the House Guide (p. 2) supports it; neither Senate source mentions it ("gives each chamber's own ways to carry a suspension on a simple majority"). The House Guide (2019) predates S.O. 47's amendments of 23 March 2020 and 27 July 2022, and the current S.O. 47 (p. 33) does not mention leave: **Verify** that a House suspension moved by leave still needs only a majority. S.O. 47(c)(ii)'s alternative is "a majority of Members present", where the notice says "a majority of those voting". |
| KI-6 | Rules | Medium | Fixed | Deferred and successive divisions defeated the context window | `context_builder_spec.rb` "context warnings". The S.O. 133 time windows are this code's own estimate, not a figure from either guide; they only raise a warning. Corrected in September 2026 against House S.O. 133 as at 23 July 2025: the Tuesday window after the matter of public importance was S.O. 133's own rule when the House Guide was written (p. 58) and is not in the current S.O. 133, so it is gone ("does not warn about a Tuesday afternoon"). S.O. 133(b) now defers evening divisions from Monday to Wednesday "until the first opportunity the next sitting day", which fixes no time; a window for it caught only programmed questions, so it rests on the chair's words, as a deferral on another day already did. The Senate's half is open: the chair's words are read both too narrowly and too widely there (KI-81). |
| KI-7 | Rules | Medium | Partly fixed | Template 24 stated the wrong suspension period and the House wording in the Senate | See the open entry below: the House is fixed, the Senate is not. |
| KI-8 | Rules | Medium | Fixed | House quorum hardcoded against a 2019 date | `template_compiler_spec.rb` "constitutional and parliamentary procedures". Chamber size comes from the member records on the day; the dated constant is only the fallback. |
| KI-9 | Rules | Medium | Fixed | Template 2 overstated what carrying a reasoned amendment does | Template 2's explainer (no spec). |
| KI-10 | Rules | Medium | Fixed | Template 17 asserted a purpose the question usually does not support | `template_compiler_spec.rb` "Template 17, the purpose a suspension states for itself". |
| KI-11 | Rules | Medium | Fixed | `declines_second_reading` was left to the model when the guides give a closed list of forms | `provenance_validator_spec.rb` "declines_second_reading against the motion text". Extended in September 2026 (`provenance_validator_spec.rb` "with the forms whose words settle it"): the words also settle it as declining when the amendment rejects the bill (the Senate's usual form) or would finally dispose of it (House S.O. 146, "now" to "not"; Senate S.O. 114(2), "this day 6 months"), and as not declining when a Senate amendment only adds words expressing an opinion. An addition that refers or delays the bill is left to the model (Senate Guide No. 16), and a House amendment that adds words, which S.O. 145(a)(iii) does not allow, is a warning. The House's "disapproves of ... charges" form is no longer listed as not declining: the guide does not classify it. The pattern for a referral or delay matches those words anywhere in the added words, so an amendment that only mentions a delay or a committee is left to the model too (KI-87). |
| KI-12 | Rules | Low | Fixed | Template copy the guides sharpen (1, 3, 4, 5, 8, 9, 10, 14, 16, 18, 20, 22, 25, 26, 27, 28) | Template text (no spec). Template 23 was checked and is right: the Senate has no gag. Checked against the House Guide (2017), which the House standing orders have since overtaken: Template 18's House half was out of date until KI-47. |
| KI-13 | Rules | Low | Partly fixed | Template 2 described one of the four things a stage amendment can do | See the open entry below. |
| KI-14 | Pipeline | Low | Fixed | `ARCHITECTURE.md` drift: template count, adjournment, Senate quorum | Documentation. |
| KI-15 | Pipeline | High | Fixed | `declines_second_reading` and `sufficient_context` were coerced to true whatever the model returned | `extraction_payload_spec.rb` "boolean fields". |
| KI-16 | Rules | High | Fixed | A suspension of standing orders was routed as whatever motion it quoted | `procedural_router_spec.rb` "suspension of standing orders is matched before the motion it would enable". The suspension rule must stay first in the router. |
| KI-17 | Pipeline | Medium | Fixed | The compiler's grammar tidying edited quoted Hansard | `template_compiler_spec.rb` "verbatim quoted text". |
| KI-18 | Rules | Medium | Open | A tied House division cannot be resolved from the recorded figures | See the open entry below. |
| KI-19 | Rules | Low | Verify | Template 21 cites the Parliament Act 1974, which neither guide mentions | See the open entry below. |
| KI-20 | Pipeline | High | Fixed | Stage 1 misread current ParlParse XML: glued paragraphs, and no motion text | `speech_text_spec.rb`, `division_xml_spec.rb`, `context_builder_spec.rb` "Hansard in the shape current ParlParse produces". Current XML has no `pwmotiontext`; the terms moved are italic paragraphs after "I move". |
| KI-21 | Pipeline | High | Fixed | A deferred division, or a long debate, left the motion out of the packet | `earlier_debate_spec.rb`, `context_builder_spec.rb`, `division_xml_spec.rb`. |
| KI-22 | Pipeline | High | Fixed | Almost every division was called a conscience vote | `template_compiler_spec.rb` "facts the drafts from real divisions got wrong". `Whip#free_vote?`'s list stops at 1 December 2022, so a later conscience vote is not called one until someone adds it. |
| KI-23 | Rules | Medium | Fixed | Real question forms routed to the wrong template or too wide a fence | `procedural_router_spec.rb` "routing on the motion as moved" and "questions taken from recent Hansard"; `semantic_extractor_spec.rb`. |
| KI-24 | Pipeline | Medium | Fixed | The mover was whoever the model credited, or "a member" | `mover_finder_spec.rb`, `template_compiler_spec.rb`, `division_summarizer_spec.rb`. The September 2026 local model run found "a motion introduced by a member" still in Template 12's vote sentence, and House members titled "Representative Kate Chaney", which is not Australian usage. Every template now prints the mover through `{{mover_clause}}`, which is empty with no mover, and House members are named in the site's own form, "Kate Chaney MP" (`Member#full_name_no_electorate`), the member in the chair too (`template_compiler_spec.rb` "naming members of the House"). |
| KI-25 | Pipeline | Medium | Fixed | Stage 4 rejected genuine quotes over formatting, and let weak evidence through | `provenance_validator_spec.rb`, `text_normaliser_spec.rb`. |
| KI-26 | Pipeline | Low | Fixed | Wording built from verbatim text read badly in Templates 2, 16, 17 and 19 | `template_compiler_spec.rb`. Reopened for Template 17 by the September 2026 local model run and fixed again: the suspension's purpose was spliced into the sentence unquoted, so "prevent me from moving a motion" read as They Vote For You speaking. It is now quoted in the standard form's own words, "as would prevent ..." (`template_compiler_spec.rb` "quotes a purpose the mover states in the first person"). Reopened for Template 19 the same way: "specifically that" spliced in whatever the model pointed at, printing "specifically that That". The description is now quoted, found by rule for a one-paragraph motion, optional, and refused when it is too short or is the chair's question (`template_compiler_spec.rb` "Template 19, what the rearrangement does"; `provenance_validator_spec.rb` "with a rearrangement of business"). |
| KI-27 | Pipeline | Medium | Fixed | The context retry leaked one model's note and re-routed the division | `context_builder_spec.rb`, `semantic_extractor_spec.rb`, `division_summarizer_spec.rb`. |
| KI-28 | Pipeline | Medium | Fixed | Validator warnings and the review flag were thrown away | `reviewer_report_spec.rb` "lists the fallbacks, the warnings and how the mover was found"; `division_summarizer_spec.rb`. Every draft, a failed one included, ends with a fixed Reviewer Only report carrying Stage 1's context warnings, the validation errors and warnings, and the fallbacks used. |
| KI-29 | Pipeline | Medium | Partly fixed | Findings from the same audit | See the open entry below: one finding is still open, and each fixed one names its spec. |
| KI-30 | Pipeline | Low | Open | The router's bill-title stripping can take a capitalised "Amendment" that is not in a title | See the open entry below. |
| KI-31 | Rules | Medium | Fixed | "That the remaining stages of the bill be agreed to, and the bill be now passed" fell to the general motion fallback | `procedural_router_spec.rb` "routes the remaining stages being agreed to and the bill passed to Template 6". A model that took the fallback's default compiled a valid draft that never said the bill passed. |
| KI-32 | Pipeline | Medium | Fixed | A question that is the whole motion sent the pipeline to read the whole sitting day | `extraction_prompt_spec.rb` "tells the model there are no terms to find when the question is the whole motion"; `division_summarizer_spec.rb` "when the question is the whole motion and the model reports its terms missing". The prompt told the model to report the terms missing whatever the question, and the retry read about 70,000 tokens that could not contain them. `ContextPacket::QUESTION_IS_THE_MOTION` lists the templates this applies to. Extended in September 2026, after two models reported the mover's speech missing for such a question and one retry read 78,535 tokens: a mover's speech reported missing is no reason to widen when nobody moved anything (the question is the whole motion, the amendments were circulated and put, or a limitation of debate applies and no mover was found), nor are terms Stage 1 found by rule, and the prompt says so (`division_summarizer_spec.rb` "does not widen for a mover's speech reported missing either"; `extraction_prompt_spec.rb`). |
| KI-33 | Pipeline | Medium | Fixed | A failed sitting day retry threw away a first reply that would have compiled | `division_summarizer_spec.rb` "when the retry over the whole sitting day fails"; `reviewer_report_spec.rb`. The draft is now built from the first reply and the Reviewer Only report says why. |
| KI-34 | Rules | Low | Fixed | Template 6 said "a motion introduced by a member" and "third reading" for the remaining stages question the chair puts | `template_compiler_spec.rb` "names every remaining stage, and no mover, when the question takes the remaining stages together". Its Bill Timeline still explains the third reading, which the remaining stages end with. |
| KI-35 | Pipeline | Medium | Fixed | A lead-in sentence before the chair's question could decide the route, and so could the amendments Hansard prints after it, or an earlier question in the same statement | `chair_statement_spec.rb` "#question"; `division_xml_spec.rb` "#operative_question"; `context_builder_spec.rb` "when the chair puts amendments nobody moved in the chamber"; `procedural_router_spec.rb` "routes the chair's question sentence, whatever the rest of the statement said". `ChairStatement` reads the statement once: the division's question is the last question sentence of the chair's own words ("The question is", "now is", "first", "immediate", "next"), after any question closed by "Question agreed to." and the like. Comparing routes over the 121 loaded divisions of May to September 2026 moved 42, every one a correction: seven questions had been settled on words in the chair's lead-in (three as closures because it said "I'll now put the question", one as a guillotine because it said "time allotted") and a dozen statements put and closed one question before putting the division's. MoverFinder reads the paragraphs that put the question, where the chair often names the mover. |
| KI-36 | Rules | Medium | Fixed | A question put once a guillotine's time had expired never said so, so a draft read as an ordinary vote with nobody moving or debating it | `division_xml_spec.rb` "#limitation_of_debate_statement"; `context_builder_spec.rb` "when a guillotine's time has expired"; `template_compiler_spec.rb` "says the question was put under a limitation of debate". Found by rule from the chair's statement, which can be dozens of divisions back under another bill's heading. A senator asking by leave or on indulgence to have their position recorded no longer stops the search (`division_xml_spec.rb` "walks past a senator asking by leave or on indulgence to have their position recorded"): on 18 August 2026 that had left two of the four divisions under the second reading's guillotine unmentioned, the second reading itself among them, and both are now found. Any other speech by leave, such as tabling a document, still stops it. |
| KI-37 | Pipeline | Medium | Fixed | Earlier debate was matched by heading alone, so a question put under "; Limitation of Debate" never found the amendment moved under the same bill's "; Second Reading" | `debates_xml_headings_spec.rb`, `division_xml_spec.rb` "finds the same bill's debate under another heading"; `earlier_debate_spec.rb`, `mover_finder_spec.rb`, `context_builder_spec.rb`. Sections are also matched by the bills listed under their headings. Such a move is only kept when the chair names its mover and nothing under the division's own heading was found: an unnamed one, such as a second reading question straight after the amendment, belongs to a different question. |
| KI-38 | Pipeline | High | Fixed | Words a member quoted or read out were quoted as the member's own explanation | `speech_text_spec.rb` "labels an italic paragraph that follows no move as a quotation"; `transcript_spec.rb` "keeps a passage the member quoted whole"; `provenance_validator_spec.rb` "when the mover quotes someone else"; `earlier_debate_spec.rb` "keeps the run round the move when the speech also quotes someone far from it". At Senate 20 August 2026 #23 all three models picked a sentence of the Prime Minister's 2003 words that the mover had read out, and the draft printed it under the mover's name. Hansard sets quoted material in italic, so an italic paragraph that is neither a motion nor part of an incorporated speech is now a `:quotation` unit, which the validator never accepts as an explanation. Still open: a short quote inside a member's own sentence ("they say: 'No worries!'") is not set apart, and neither is a quote inside an incorporated speech, so those rest on the model and the reviewer. |
| KI-39 | Pipeline | Medium | Fixed | An incorporated second reading speech opening with the House's "I move that this Bill be now read a second time." was read as a move, and the whole speech as its terms | `speech_text_spec.rb` "a speech incorporated by leave" and "reads a move made while presenting a report or tabling a document". Three Senate speeches on 19 and 20 August 2026 gave 7,339 to 14,500 characters of speech as the motion moved; none of the sitting days checked has a division on those bills, so none of the drafts checked here used it. Fixing it exposed that "I table ... and move:" was never read as a move either, so one of the three ministers had been found only through the copied line; tabling and presenting forms are now read. |
| KI-40 | Pipeline | Medium | Fixed | The prompt a draft was made from was not kept, only the model's reply, and cannot be rebuilt once Hansard or the code has changed | `ai_division_summary_spec.rb` "keeps a prompt and a draft longer than a TEXT column holds"; `division_summarizer_spec.rb` "keeps the prompt the model was sent", "keeps the prompt of the reply the draft was built from". The prompts are on `system_prompt` and `user_prompt`, MEDIUMTEXT like `description` now, because a sitting day prompt ran to 104,305 bytes and a guillotine draft to 50,610, against TEXT's 65,535. Local runs also write each request beside its reply. |
| KI-41 | Pipeline | High | Fixed | A chair's statement over 1,200 characters was not taken for the chair's, so a draft said the question was never recorded, and quoted all 45,679 characters when it was | `division_xml_spec.rb` "is the chair's statement however many amendments Hansard prints in it"; `transcript_spec.rb` "#question_units"; `provenance_validator_spec.rb` "quotes only the chair's words putting the division's question"; `earlier_debate_spec.rb` "keeps a long statement of the chair's putting another question". The size limit is applied to the plain paragraphs only: the italic ones are the amendments being put. Question Put quotes the chair's words putting the division's question, and the earlier debate keeps only the chair's words from earlier statements. |
| KI-42 | Pipeline | High | Fixed | The validator accepted the chair putting a question as the terms of the motion moved | `provenance_validator_spec.rb` "never takes the chair putting or deciding a question as the terms moved". A model motion reference whose text is a chair's question sentence or "Question agreed to." and the like is refused with a warning, whoever the transcript says spoke it: at Senate 18 August 2026 #16 a draft printed "The question now is that amendments ... be agreed to." as the amendment moved. |
| KI-43 | Rules | High | Fixed | Amendments nobody moved were credited to whoever last moved anything: a party's circulated amendments to the minister who had moved the second reading, with the minister's case for the bill offered as the case against it | `mover_finder_spec.rb` "does not credit a move whose terms cannot be what the question puts", "does not guess an unnamed mover for amendments the chair says were circulated"; `chair_statement_spec.rb` "#circulated_by"; `context_builder_spec.rb` "when the chair puts amendments nobody moved in the chamber"; `template_compiler_spec.rb` "amendments the chair put without anyone moving them". An unnamed move counts only when its terms could be what the question puts, and not at all when the chair says the amendments were circulated. Who circulated them is found by rule, from the chair's words or Hansard's heading over them, and the draft says "circulated by the Australian Greens ... were put", never "moved". Every template now prints the mover through `{{mover_clause}}`, so a draft with no mover says nothing rather than "introduced by a member". With no mover, an explanation can only be the circulating member's words. |
| KI-44 | Pipeline | Medium | Fixed | The terms of amendments the chair put under a limitation of debate were left for the model to find, though the chair's statement prints them | `transcript_spec.rb` "takes the amendments printed after the division's question as its terms"; `context_builder_spec.rb` "takes the amendments the chair put as the terms", "keeps the plain headings Hansard sets among the amendments"; `extraction_prompt_spec.rb` "tells the model when the chair put amendments nobody moved"; `division_summarizer_spec.rb` "does not widen for amendments the chair put". The paragraphs after the question sentence, up to the next record or question, are the terms, found by rule, when the question refers to amendments; in the House, unmoved opposition amendments are sometimes printed only for the record (House Guide p. 75), so nothing else is taken. 26 of the 121 loaded divisions now have their terms found by rule, and none of them sends the model to the sitting day for them. The House Guide's note (p. 75) describes the guillotine as it was before S.O.s 83 and 84 were omitted on 27 July 2022; S.O. 85(c) now treats circulated amendments to an urgent bill as moved, so the caution is harmless and was kept. |
| KI-45 | Pipeline | Medium | Fixed | Template 28 did not say which parts of the bill were to stand as printed, or whose amendments to omit them the vote decided | `template_compiler_spec.rb` "names the parts the question named, and who circulated the amendments to omit them". The parts are the chair's words between "that" and "stand as printed" in the division's question, quoted, and who circulated the amendments comes from `Circulation`. |
| KI-46 | Pipeline | High | Fixed | Every closure not on a bill said "to end the debate on bill", and one on a bill left out "the" | `template_compiler_spec.rb` "Template 22, a closure on a bill and on anything else"; the evaluation corpus fixture 2. With no bill the sentence ends the debate and names none. `bill_reference` was checked everywhere else it is used: every other use follows "the". |
| KI-47 | Rules | Medium-High | Fixed | Template 18 described the House guillotine from the House Guide (2017): a declaration of urgency followed by a motion allotting time. S.O.s 83 and 84 were omitted on 27 July 2022, and there is no allotment of time any more | Template text (no spec). Rewritten from House S.O. 82 and 85 as at 23 July 2025: the declaration of urgency, one evening's second reading debate to 10 pm, the questions then put without debate at the next sitting, circulated amendments treated as moved and put in groups (government, opposition, each crossbench member), and no closure. The catalogue line and the router's reason say the same. The Senate half matches Senate Guide No. 17 and was kept. Checking the other House standing orders the pipeline cites found S.O. 122 changed since the guide: since July 2019 it puts "That the amendment be agreed to", noted under KI-68. Template 23 now also says S.O. 80 bars the gag while a member is moving the terms of a motion; that bar is older than S.O. 80's amendment of 23 July 2025, since the House Guide already gives it (p. 48). S.O. 47, 94 and 133 changed too (KI-5, KI-7, KI-6). S.O. 31 and 131 were reread and say what the pipeline says of them; S.O. 11, 46, 58, 81, 87, 135, 150, 153, 173, 188 and 202 have not been amended since the guide, so the earlier check against it stands. S.O. 29 was amended in 2022, but only its sitting times. |
| KI-48 | Pipeline | Low | Fixed | Wording that read as machine output or overstated its source: "1 senator(s)", a Motion Introduction of just "I move:", "decline the bill a second reading", "which means ... This means", "It has happened once, in 2016" stated as current fact from a 2017 guide, "Ndis" for "NDIS" in titles, and "they agreed" for the chamber | `template_compiler_spec.rb` "wording that read as machine output", "Template 2's explainer in each chamber"; `draft_title_spec.rb` "prints a bill's title in the heading as the bills table records it"; the evaluation corpus. A section with nothing left in it is now left out, heading and all, which is how the bare "I move:" goes. `DivisionFacts#bill_titles` carries every bill's own title for `DraftTitle`; `DivisionXml#name` keeps its PHP-compatible casing. |
| KI-49 | Rules | Medium | Fixed | Subject rules outranked the bill-stage rules, so a reasoned amendment read out as the question was settled as whatever it named: a select committee, or a censure | `procedural_router_spec.rb` "routes the form proposing a select committee to Template 2", "routes a Budget amendment worded as a censure to Template 2", "leaves the same form amending an ordinary motion to the other rules". `reasoned_amendment_form` settles Template 2 when the question reads out an amendment's own form in a second reading debate, before any subject rule. None of the 121 loaded divisions changed route; since KI-35, the Senate's questions no longer carry the amendments' words, so this is for a House chair reading an amendment out. KI-13's note that the Budget case already worked was wrong and has been corrected. |
| KI-50 | Rules | Medium-High | Partly fixed | A motion whose first paragraph Hansard sets as "That—" alone was routed on that one word; it is now read whole, but the limitation of debate it sets is routed only as advice | See the open entry below. |
| KI-51 | Rules | Low | Fixed | The plain second reading question ("That the bill be now read a second time") was fenced between Templates 2 and 29 though it names no amendment | `procedural_router_spec.rb` "settles the plain second reading question on Template 29", "fences a second reading question that is not in the plain form". Settled as Template 29 in that form with no amendment wording and not "as amended"; anything else still fenced. Three of the 121 loaded divisions moved from the fence to 29, each a plain second reading. |
| KI-52 | Rules | Medium | Partly fixed | A House question put "immediately" under a resolution agreed earlier read as an ordinary debated vote; two more forms of a question put when allotted time has expired are still missed | See the open entry below. |
| KI-53 | Pipeline | Medium | Fixed | A divided question was summarised, and its motion printed, as though the whole motion had been put | `chair_statement_spec.rb` ".divided_parts"; `template_compiler_spec.rb` "a divided question". When the chair's question puts a motion "minus" or "except" some of its parts, the draft says the vote was on the motion without them, in the chair's words, and the Reviewer Only report says the question was divided. Senate forms only: the House, where a member may move that a question be divided (House S.O. 119), had none in its Hansard from May to September 2026, so none is assumed. A divided question put on the separated part itself is not recognised. |
| KI-54 | Pipeline | Medium | Fixed | A closure's draft said only that "the debate" ended, and never linked the division that then put the underlying question | `context_builder_spec.rb` "with a closure"; `template_compiler_spec.rb` "says what the debate it ended was on". Stage 1 routes the move the closure cut short (the last one before the closure's own, in the same debate, by someone else) and keeps the template when that settles one, which the sentence names: "to end the debate on a motion to suspend standing orders". The follow-up division is the next that day in the same debate, unless it is a closure itself, looked up in the database. ARCHITECTURE.md section 15's `followup_link` item is built. |
| KI-55 | Pipeline | Low | Fixed | A matter of urgency did not say whose proposal it was; words incorporated in Hansard were quoted as "Senator X said:"; and a question the chair put with nobody moving it printed empty Motion Introduction and Motion Text sections | `context_builder_spec.rb` "finds who proposed a matter of urgency someone else moved"; `template_compiler_spec.rb` "what a draft says about who moved what"; `transcript_spec.rb` "marks the words of a speech incorporated by leave"; `provenance_validator_spec.rb` "records when the chair put a question that is the whole motion with nobody moving it". The proposer comes from the chair's "Senator X has submitted a proposal" and a surname is linked only when one senator on the day has it; incorporated words are introduced as "Senator X's speech, incorporated in Hansard, reads:"; and when nobody moved anything the sections are left out, and the Question Put section quotes the question. |
| KI-56 | Pipeline | Medium | Fixed | In Templates 1, 5, 6 and 29 the mover's words sat under "About the Bill" straight after the Bills Digest, so once a digest is wired in a reader could take the mover's case for the Parliamentary Library's | `template_compiler_spec.rb` "gives the mover's words their own heading, apart from the Bills Digest". They are under "### About the Motion", as in the other templates (heading chosen by Blake, 30 September 2026). With nobody moving anything the section is left out. |
| KI-57 | Pipeline | Medium | Fixed | Hansard's records of the chamber inside a member's speech ("Leave not granted.", "(Time expired)", "Opposition senators interjecting—", "Question agreed to.") were the member's own sentences, so the validator would have accepted one as their explanation | `speech_text_spec.rb` "labels Hansard's records of the chamber as records"; `transcript_spec.rb` "marks Hansard's record at the end of a paragraph as a record"; `provenance_validator_spec.rb` "drops Hansard's record of the chamber inside the mover's speech". A paragraph or sentence that is wholly one of a closed list of forms, from House and Senate Hansard of May to September 2026, is a `:record`: shown to the model as "record" and never accepted as an explanation. Not `:quotation`, because in the chair's statement "Question agreed to." closes a question rather than joining the amendments printed after it. The nightly loader's `#motion` is untouched. No draft in the run printed one; the Senate XML for 12 to 20 August alone had "Leave granted." or "Leave not granted." about 45 times. |
| KI-58 | Pipeline | Medium | Partly fixed | The prompt let a model pick remarks aimed at other members as "the mover's case", and left it unclear what Template 17's explanation should hold; some models still pick them | See the open entry below. |
| KI-59 | Pipeline | Low | Fixed | When the question settled a template and the model could not find what that template is about, the pipeline read the whole sitting day again instead of doubting the route | `division_summarizer_spec.rb` "does not widen when the model cannot find what a settled template is about, and says so". `TemplateCatalogue::DEFINING_EVIDENCE` (a committee for 12 and 13, a regulation for 9, a target for 10, 23 and 24): with a settled route, that report is not a reason to widen, and the validator warns the reviewer to check the route. |
| KI-60 | Pipeline | Medium | Fixed | Earlier speeches that moved something else were sent whole even when the chair had named a different mover, though only the mover's sentences can be quoted | `context_builder_spec.rb` "cuts another member's earlier speech to what it moved, once the chair has named the mover". Once the mover is known, another member's earlier speech keeps only its "I move" words and terms. House 18 August 2026 #3's user prompt fell from 33,582 characters to 18,033 with its route and mover unchanged, and no loaded division changed route. |
| KI-61 | Pipeline | Low | Open (deferred) | Sentences left out between quoted ones are not marked | See the open entry below. |
| KI-62 | Pipeline | High | Open | The mover of a closure was taken as the mover of the question it brought on, so a second reading draft quoted "That the question be now put" as its motion | See the open entry below. |
| KI-63 | Pipeline | High | Open | A motion moved in an earlier section of the same debate was not found, so a suspension of standing orders was routed as a censure | See the open entry below. |
| KI-64 | Pipeline | Medium | Open | The model rarely pointed at the mover's reasons, leaving "About the Motion" empty | See the open entry below. |
| KI-65 | Pipeline | Low | Open | A motion moved at another senator's request is described as the mover's own | See the open entry below. |
| KI-66 | Pipeline | Low | Fixed | A motion's lettered and numbered paragraphs were all quoted at one level, so "(i)" under "(a)" read as though it sat beside it | `quote_outline_spec.rb`; `template_compiler_spec.rb` "an outlined motion". Hansard's XML gives every paragraph as a flat `<p>`, so the depth comes from the labels: each new label style is one level further in, and going back to a style already open goes back to its level. "(i)", "(v)" and "(x)" are read as letters or numerals by what they continue. A paragraph without a label stays at the outer level. Only Motion Text is outlined, not the mover's quoted sentences. Checked on Senate 17 September 2026 #8, #9 and #10. |
| KI-67 | Pipeline | Medium | Open | The sitting-day retry has no limit on its size | See the open entry below. |
| KI-68 | Rules | High | Open | Six question forms are routed as their opposites, so a draft would report the reverse of the vote | See the open entry below. |
| KI-69 | Rules | High | Open | A Senate division without a quorum is reported as decided | See the open entry below. |
| KI-70 | Rules | Medium-High | Open | Amendments a senator moved before a guillotine fell are described as moved by nobody, and three parts of the pipeline decide "nobody moved" differently | See the open entry below. |
| KI-71 | Pipeline | Medium | Open | The prompt does not connect a House mover's name with the seat or office the chair calls them by | See the open entry below. |
| KI-72 | Rules | Medium | Open | Senate rescission: the standing order and the guide disagree on the majority, and the code's pattern is too broad | See the open entry below. |
| KI-73 | Rules | Medium | Open | Explainer and vote sentences that state one chamber's rule as general, or say more than the rules do (Templates 5, 7, 14, 25 and 26) | See the open entry below. |
| KI-74 | Rules | Low | Open | Three House rules the pipeline gets wrong in rare cases: a tie on the ballot closure, the quorum fallback, and Template 1 | See the open entry below. |
| KI-75 | Rules | Low | Open | Comments, router reasons and template sentences to correct or verify, none of which changes a route | See the open entry below. |
| KI-76 | Pipeline | Low | Open | The Reviewer Only section leaves out things a reviewer needs | See the open entry below. |
| KI-77 | Pipeline | Low | Open | The local model tools lose or misreport a reply that does not finish | See the open entry below. |
| KI-78 | Rules | Low | Open | Choices the pipeline made are not marked as choices, so they could be defended as rules or "fixed" as errors | See the open entry below. |
| KI-79 | Pipeline | High | Open | A draft said an amendment was agreed to when no amendment was moved or found, and passed validation | See the open entry below. |
| KI-80 | Pipeline | High | Open | A deferred vote the chair put by name, without restating its question, was drafted as a closure | See the open entry below. |
| KI-81 | Pipeline | Low | Open | The deferral warning misses Senate wordings, and in both chambers fires on text that isn't the chair's | See the open entry below. |
| KI-82 | Rules | Low | Open | A draft can't say that its division was deferred from an earlier day, or that it replaced an earlier decision | See the open entry below. |
| KI-83 | Rules | Low | Open | The absolute majority is worked out from the members on the day, not the fixed figure the rules give: 38 in a Senate vacancy, and 75 in the House in March 2026 | See the open entry below. |
| KI-84 | Pipeline | High | Open | A deferred second reading was credited to the mover of a second reading amendment negatived before it, and the amendment was printed as its motion | See the open entry below. |
| KI-85 | Rules | Medium-High | Open | A House division with six or fewer on a side (S.O. 127) may be reported as decided by no one, or the wrong way round | See the open entry below. |
| KI-86 | Pipeline | Low | Open | A unanimous division would read "a large majority" where the division page says "unanimously" | See the open entry below. |
| KI-87 | Pipeline | Medium-High | Open | A word such as "delayed" or "Committee" anywhere in a Senate second reading amendment switches off the validator's check of `declines_second_reading`, so whether the draft says the amendment opposed the bill rests on the model alone | See the open entry below. |
| KI-88 | Pipeline | Low | Open | For a second reading amendment, the quoted reasons can be about the bill rather than the amendment's own terms | See the open entry below. |
| KI-89 | Pipeline | Low | Open | Question Put gives the chair's question the time of the speech before it | See the open entry below. |
| KI-90 | Pipeline | Medium | Open | A mover's reasons given before an earlier division in the same debate never reach the model, so "About the Amendment" says "No explanatory claims recorded." | See the open entry below. |
| KI-91 | Pipeline | Low | Open | Template 2's vote sentence says an amendment "introduced by" a senator "to the" bill, though amendments are moved, and a second reading amendment is to the motion | See the open entry below. |
| KI-92 | Rules | Low | Open | A senator's position on parts of a question, recorded by leave just after its division, never appears in a draft: a decision is needed | See the open entry below. |
| KI-93 | Rules | Low | Open | Template 8's explainer tells the reader what "the summary should not suggest", calls a Senate order a power of "the parliament", and doesn't say the documents become public only when tabled | See the open entry below. |
| KI-94 | Pipeline | Low | Open | "No explanatory claims recorded." prints as a block quote, in the pipeline's own term, whatever the reason there is nothing to quote | See the open entry below. |

---

## Open: rules

### KI-4

**Real question forms fall through to Template 15.** Severity: High. Status: **Partly fixed**.
**Confirmed** by running each form through `ProceduralRouter.route`.

Template 15 is the fallback. "That the bill be considered urgent" now routes to Template 18, and
Template 15 no longer claims every question it receives "records an opinion ... and has no legal
effect". These forms still land there with no template that fits them:

| Question form | Source | What it actually is |
|---|---|---|
| "That the bill stand as printed" | Senate Guide No. 16 | The final question in committee of the whole when no amendments were agreed to. |
| "That the bill (as amended) be agreed to" | House S.O. 149(b) and (c), 150(c), 153(a) and (b)(iv); Guide pp. 71-73 | End of consideration in detail when the bill is taken as a whole, or the report stage for a bill from the Federation Chamber. |
| "That the report of the committee be adopted" | Senate Guide No. 16 | Report from committee of the whole; amendments are moved to it. |
| "That the proposed expenditure(s) be agreed to" | House Guide p. 82 | The appropriation bill detail stage. |
| "That the House approves the form of agreement ..." | House Guide p. 94-95 | Approval of a legislative instrument, the mirror of disallowance. |

Each needs its own template, which adds to the catalogue: a decision to agree with a human before
writing, not a change to make unilaterally. New templates are numbered after the last one (as
Template 29, the second reading, was) so that no template already cited by number moves.

This entry also listed "That the words proposed to be omitted stand part of the question". That
form never reaches the fallback: it is settled on Template 2, the opposite of what it decides, so it
is now in KI-68 with the other inverted forms.

What a missing template costs was **confirmed** at House 16 September 2026 #6, where the chair put
"The question is the bill be agreed to." at the end of consideration in detail. The router could
only offer Template 15 as advice, and Qwen3.6-35B-A3B (UD-Q4_K_M) chose Template 4 instead, from the
label the prompt gives it, "Consideration in Detail (House of Representatives)", which does not say
that Template 4 is for amendments. The draft then said an amendment had been agreed to and passed
validation (KI-79). With no settled route, `ContextPacket#question_states_motion?` was false, so the
prompt told the model to report the terms missing if it could not find them, it did, and the
pipeline read the whole sitting day looking for terms this question does not have (KI-67). A
template for this form would have settled the route and avoided both.

### KI-7

**Template 24 states no Senate suspension periods, and uses the House's wording for the Senate.**
Severity: Medium. Status: **Partly fixed**. **Confirmed** against the Senate standing orders of July
2025.

Fixed for the House, against House S.O. 94(d) as at 23 July 2025: the first suspension is the 24
hours from the time of suspension, and only the second and third leave out the day
(`template_compiler_spec.rb` "Template 24, suspension periods and the two chambers' wording").

Still open for the Senate. This entry asked for Senate S.O. 204 to be checked in the current
edition before its periods were stated. The July 2025 edition (p. 102) has them as the June 2009
one did: a suspension "on the first occasion shall be for the remainder of that day's sitting, on
the second occasion for 7 sitting days, and on the third or any subsequent occasion for 14 sitting
days", where they fall in the same calendar year, and a suspended senator may not enter the
chamber (S.O. 204(2)). The Senate sentence in `summary_wording.rb` still says "The Senate names a
senator under standing order 203 and sets the period of suspension under standing order 204; the
Senate's own guide does not state those periods", but under S.O. 203(1) the President "may report
to the Senate that the senator has committed an offence". Template 24's explainer says a member is
suspended after the Chair "has named them for disorderly conduct", which is only one of the five
offences S.O. 203(1) lists. A fix would state all three periods, since the data does not say which
occasion it was, say that the President reports the senator, and not limit the offence to
disorderly conduct. Test in `template_compiler_spec.rb` "Template 24, suspension periods and the
two chambers' wording".

### KI-13

**Template 2 describes the four things a stage amendment can do, but not which one this was.**
Severity: Low. Status: **Partly fixed**.

Senate Guide No. 16 (p. 47) lists four things such an amendment may do: express an opinion,
reverse the motion so the bill is defeated at that point, refer the bill to a committee, or delay
further consideration. The explainer now lists all four. The guide does not say the list is
complete, and Senate S.O. 114(3) allows "Other amendments ... provided that they are relevant to
the bill", so the "closed list" this entry used to describe was its own reading. Still open:
extracting which one applies, as a choice from the four with an "other" answer, so the summary
can say which. Worth doing once the evaluation corpus has enough Template 2 divisions to
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

"The occupant of the Chair" overstates who has the casting vote. House S.O. 3(d), pp. 11 to 12:
"The power to exercise a casting vote (standing order 135) is reserved for the Speaker, Acting
Speaker, Deputy Speaker or Second Deputy Speaker", and the House Guide (p. 58) adds that it "does
not apply to members of the Speaker's panel in the Chair unless specifically appointed by resolution
of the House as Acting Speaker". The same words are in `SummaryWording#result_notice` and the
comment on `ParliamentaryOutcome#tied?`. S.O. 135(c) records the Speaker's reasons, if given; the
decision itself is in the Votes and Proceedings (S.O. 27), and the Chair announces it in the House,
so Hansard after the division may be enough to recover it. **Verify** that, and that a casting vote
is not in TVFY's aye and no counts: no tied House division is in the 2026 data.

### KI-19

**Template 21 cites the Parliament Act 1974, which neither guide mentions.** Severity: Low.
Status: **Verify**.

The House guide confirms works in the parliamentary precincts can be subject to parliamentary
approval (p. 117) but names no Act, and the Senate guides do not cover it. The citation is probably
right and was left in, but it has not been checked against a primary source.

### KI-50

**A motion that says its parts "operate as limitations of debate under standing order 142" is
routed to Template 18 only as advice.** Severity: Medium-High. Status: **Partly fixed**.
**Confirmed** from four local models' drafts on 1 October 2026 and from the code.

Fixed: a motion whose first paragraph Hansard sets as "That—" alone was routed on that one word, so
the Senate's order fixing a week's hours and guillotines fell to the general motion fallback.
`ContextBuilder#operative_paragraph` now reads every paragraph after a bare "That"
(`context_builder_spec.rb` "routes a motion whose first paragraph is only \"That\" on the
paragraphs after it"). Only Senate 18 August 2026 #2 moved in the 121 loaded divisions.

Still open: the route that gives is advisory. That order's paragraph (4) reads "Paragraphs 1(b) and
(c), 2(b) and (c), and 3(c) operate as limitations of debate under standing order 142." A route
taken from the motion text binds only when the motion opens in a fixed form
(`ProceduralRouter.fixed_opening?`), which protects against a misleading first paragraph, and this
one opens with "That" alone. Three of four local models chose Template 19 instead. Both templates
are true of the motion, but only 18 says debate was limited, and only its title reads "; Limitation
of Debate". Senate Guide No. 17 (p. 51) supports 18: "the application of a time limit to the
consideration of a bill is referred to as a guillotine", and "Guillotine motions are often moved as
part of broader motions varying the days and hours of sitting". Whether a motion's own "limitations
of debate under standing order 142" should settle or fence the route, as a named exception to the
rule that motion text is only advice, is a decision for the team. Test in
`procedural_router_spec.rb`, with a route snapshot before and after.

### KI-52

**Two forms of a question put when a debate's allotted time has expired are not recognised.**
Severity: Medium. Status: **Partly fixed**. **Read** (the House form); **Verify** (the Senate form
and the House's urgent-bill wording).

Fixed: a House question put "immediately" under a resolution agreed earlier is found by rule like
the Senate's statement, walking back through the run of divisions (`division_xml_spec.rb` "finds
the Speaker putting the question immediately under a resolution, across the run of divisions";
`template_compiler_spec.rb` "a question the House put immediately under a resolution agreed
earlier"). It is kept as its own kind: the House programming a bill by suspending standing orders
is not a guillotine (House Guide p. 75), so the draft says "This question was put without further
debate, under an arrangement the House of Representatives agreed on 12 August 2026", the date from
the Speaker's words, and quotes them.

Still open:

- At House 24 June 2026 the Speaker said "In accordance with the resolution agreed to on 23 June
  2026, the time allotted for this debate has expired. The question is that the amendment be agreed
  to.", and divisions 1 and 2 (5:35 and 5:43 PM) followed under "; Second Reading".
  `DivisionXml#limitation_expiry?` accepts a statement that matches `PUT_IMMEDIATELY` ("In
  accordance with the resolution agreed to on <date> ... put the question immediately"), or one
  that matches `TIME_EXPIRED` and also cites an order ("pursuant to order", `ORDER_CITED`) or sits
  under a "Limitation of Debate" heading. This statement matches only `TIME_EXPIRED`, so both
  drafts would read as ordinary debated votes. A fix would take "In accordance with the resolution
  agreed to on <date>" followed by the time allotted having expired as the same resolution kind,
  keeping the "not a guillotine" wording, and update the comment above `PUT_IMMEDIATELY` that says
  only the 18 August 2026 forms have been seen. Test in `division_xml_spec.rb` with those two
  divisions.
- In the Senate on 25 June 2026 the chair said "Pursuant to order agreed to on Tuesday ... I'm now
  required to put the questions", with no "time allotted ... has expired". Senate Guide No. 17
  (p. 51) allows a guillotine to set "a set time in a day (e.g. 'all remaining stages to conclude by
  5 pm today')" rather than a duration, so this form is expected. **Verify** it on more sitting days
  before adding it; KI-36 is the Senate statement it would extend.
- What the Speaker says under the House's own guillotine for urgent bills (S.O. 82 and 85) has not
  been seen in any sitting day checked, so it stays **Verify** before this is extended to it.

### KI-68

**Six question forms are routed as their opposites.** Severity: High. Status: Open. **Confirmed**
by running each form through `ProceduralRouter.route` on 1 October 2026.

Each form matches a rule meant for another question, so the draft would report the reverse of what
the vote decided:

| Question form | Rule | Routed to | What the draft would say |
|---|---|---|---|
| "That this question be not now put" (the previous question) | Senate S.O. 94(1) and 95, p. 64: if carried, the original question is disposed of without being put | 22, settled | that debate was ended and the question put |
| "That the bill be read a third time this day 6 months" | Senate S.O. 122(3), p. 74: the only amendment allowed at the third reading, and if carried it "shall finally dispose of the bill" | 6, settled | that the bill passed |
| "That the bill be now passed without requests" | Senate S.O. 140(3), p. 81: a committee question on a bill the Senate may not amend | 6, settled | that the bill passed the Senate |
| "That Senator X be further heard" | Senate S.O. 196, p. 100: a senator told to stop for irrelevance or repetition may require this question | fenced to 23, with the reason "a House of Representatives procedure" | that the senator was stopped from speaking |
| "That [Member] be heard now", "That the Member be further heard" | House S.O. 65(c), p. 40, and 75(b), p. 43 | 23, settled | "be no longer heard" and, if carried, "They were unable to continue speaking" |
| "That the words proposed to be omitted stand part of the question" | House Guide p. 52: if agreed to, "the amendment is disposed of"; p. 72 calls these forms "no longer used" | 2, settled, under a "; Second Reading" heading | that the amendment was carried |

None was found in the divisions or sitting days checked, so they are rare, but each prints the
opposite result, and the guard is small: keep "not now put", "this day 6 months", "without
requests", "heard now" and "further heard" away from the rules that catch them, and send the "stand
part" form to the fallback or invert it as Template 28 does. Search the loaded divisions for any of
these forms before relying on made-up questions. Test in `procedural_router_spec.rb`, with a route
snapshot before and after.

### KI-69

**A Senate division without a quorum is reported as decided.** Severity: High. Status: Open.
**Read**: the code was read, not run, against the rule quoted below.

Senate S.O. 52(1), p. 43: if a division shows "that a quorum is not present ... no decision of the
Senate shall be considered to have been arrived at by such division". S.O. 147(2), p. 84, says the
same in committee of the whole, and the standing orders' front matter gives the quorum as 19.
`ParliamentaryOutcome#quorum_threshold` returns nil for the Senate, and its comment says that is on
purpose because "the Guides to Senate Procedure set out no rule voiding a Senate division for want
of a quorum". The guides are silent, but the standing order is not. A fix would apply the House
logic with the Senate's quorum and cite S.O. 52(1), and would be tested in
`template_compiler_spec.rb` "constitutional and parliamentary procedures". Uncertain: whether the
President, who may vote, counts towards the figure the tellers report. The standing order does not
say, so a division with exactly 18 recorded votes is safer as a reviewer warning than a verdict.
S.O. 101(5), p. 67, narrows this: "Every senator present when the question is stated shall vote,
except the President, or the Chair of Committees in the chair of a committee, for whom voting shall
be optional", so the senators present are the recorded votes, plus the chair if the chair did not
vote. S.O. 147(3), p. 84, says what happens to a committee of the whole interrupted for want of a
quorum: its resumption is "an order of the day for the next day of sitting". The Senate (Quorum)
Act 1991 has not been checked.

### KI-70

**Amendments a senator moved before a guillotine fell are described as moved by nobody, and three
parts of the pipeline decide "nobody moved" differently.** Severity: Medium-High. Status: Open.
**Confirmed** (the prompt, by routing the division and reading the code); **Read** (the
disagreement).

Senate S.O. 142(4), p. 82: when the time expires the chair puts "the question on any amendment or
motion already proposed from the chair", and only then the circulated ones. At Senate 18 August
2026, 8:00 PM, the chair said "I'll first deal with the amendments moved by Senator ... on sheet
3832", and division 14 (8:09 PM, `uk.org.publicwhip/lords/2026-08-18.209.1`) then put "the remaining
amendments on sheet 3832". Stage 1 finds a limitation of debate and no mover for division 14, so
`ExtractionPrompt#no_motion_instruction` tells the model "Under the limitation of debate the chair
put this question with nobody moving it", and the draft would name no mover for amendments a
senator moved.

The same idea is decided in three places, and they already disagree:

- `DivisionSummarizer#nobody_moved?`, which stops the sitting-day retry for a missing mover's
  speech, counts a question that states the whole motion, amendments circulated and put, or a
  limitation of debate with no mover found.
- `ExtractionPrompt#no_motion_instruction` and `#circulated_note` tell the model nobody moved in
  the same three cases.
- `ProvenanceValidator#put_without_mover?`, which decides whether the draft leaves out its Motion
  Introduction and Motion Text sections, counts only the first two. Under a guillotine with no
  mover found, the draft prints "No motion introduction recorded." while the prompt told the model
  nobody moved.

Division 14 supports the validator's narrower test. A fix would decide this once, on
`ContextPacket`, saying "nobody moved" only when the question states its own terms or a circulator
was found, and would look for "moved by" in the earlier statements of the same run of divisions
(`DivisionXml#run_statements`). Test in `extraction_prompt_spec.rb`, `division_summarizer_spec.rb`
and `provenance_validator_spec.rb`, with division 14 as the case.

### KI-72

**Senate rescission: the standing order and the guide disagree on the majority, and the code's
pattern is too broad.** Severity: Medium. Status: Open. **Read** (code); **Verify** (the
threshold).

Senate S.O. 87, p. 62: an order "may be rescinded, but not during the same session unless 7 days'
notice is given and at least one-half of the whole number of senators vote in favour", which is 38
of 76. Senate Guide No. 3, p. 9, says rescission needs an absolute majority, which "is more than
half of all possible votes (39)". The standing order is the rule and the guide explains it, so the
threshold should be 38, and only within the same session. The standing order's exception, "to
correct irregularities or mistakes one day's notice shall be sufficient", shortens the notice and,
on its words, leaves the majority as it is. Separately,
`ParliamentaryOutcome#absolute_majority_requirement` returns `:always` for any Senate motion whose
words include "rescind", "rescinded" or "rescinding", so a motion that calls on the Government to
rescind its own decision is flagged as needing a special majority. A fix would match only a motion
to rescind an order, resolution or vote of the Senate. How the Senate applies S.O. 87 should be
checked in Odgers' Australian Senate Practice before the threshold changes.

### KI-73

**Explainer and vote sentences that state one chamber's rule as general, or say more than the rules
do.** Severity: Medium. Status: Open. **Confirmed** against the rules named, and by running the
router where a route is involved.

Each is a wording change in a template or in `summary_wording.rb`, except where the last column
says a decision is needed:

| Where | What it says | What the rules say | Change |
|---|---|---|---|
| Template 5 (Federation Chamber report) | the questions on the report are "put immediately, without debate or amendment" | House S.O. 153(b)(i), p. 68: on a bill reported with unresolved questions, "A separate question shall be proposed on each unresolved question and each shall be open to amendment or debate". Only 153(a), (b)(ii) and (b)(iv) are decided without | Correct the sentence. An amendment question under a "; Report from Federation Chamber" heading routes to [2, 4], so Template 5 cannot be chosen for the questions that actually divide there: whether to allow it is a catalogue decision |
| Template 26 (adjournment), in the Senate | "At a set time each sitting day the chair proposes that the chamber do now adjourn" | Senate S.O. 54(5), p. 44: "The President shall adjourn the Senate without putting the question"; S.O. 53(2), p. 43: the adjournment may be moved "by or on behalf of a minister", so a Senate adjournment division only comes from a minister's motion | A Senate sentence citing both |
| Template 25 (dissent) | "Dissent can only be moved against a ruling", with no chamber named | That is the House (House Guide p. 42: decisions "at the Speaker's discretion are not rulings and cannot be dissented from"). Senate S.O. 198(1), p. 101: an objection may be taken "to a ruling or decision of the President", and S.O. 198(2) adjourns its debate to the next sitting day unless the Senate decides otherwise | Label the sentence House-only and add a Senate one, without claiming every decision can be challenged, since Odgers' may limit it |
| Template 14 (Selection of Bills) | the committee "decides which newly introduced bills need to be sent to other committees"; an amendment to the motion adopting its report is settled on 14 and printed as voting on "a motion ... to adopt the report" | Senate S.O. 24A(1), p. 26: the committee reports on bills to be referred; Senate Guide No. 13, p. 34: it "makes recommendations to the Senate about bills to be referred", and adopting the report does the referring | "recommends", and a vote sentence for an amendment |
| Template 7 and `SECTION_53_NOTE` | section 53 "stops the Senate amending a bill at all", naming only tax and ordinary annual services bills | House Guide p. 88 and Senate Guide No. 16, p. 49: the Senate also may not amend a bill "so as to increase any proposed charge or burden on the people", though the House Guide (p. 89) says what that covers has not been "conclusively determined" | Add the limb, carefully |
| Template 7, the effect of a message vote | "goes back to it for further negotiation" and "proceeds without them" | House: a return to the Senate goes through a motion with written reasons and "That the reasons be adopted" (S.O. 161(c), p. 70), and S.O. 162 and 169 (pp. 70 to 72) leave the House other courses, such as further or alternative amendments, laying the bill aside, or insisting. Senate: not insisting "and" making alternative amendments in their place is not "proceeds without them" (Senate Guide No. 18, p. 54), and a bill may be laid aside (S.O. 126(6), p. 75) | Neutral wording for the House until a source says more, and detect the compound "not insist" forms before printing an effect. KI-2's omit-clause case is separate |

### KI-74

**Three House rules the pipeline gets wrong in rare cases.** Severity: Low. Status: Open.

- **A tie on the ballot closure.** During the election of a Speaker, House S.O. 11(h), p. 17, puts
  "That the ballot be taken now", and "If the votes are equal the question shall be negatived";
  until a Speaker is elected "there is no provision for a casting vote" (House Guide p. 5). The
  question routes to Template 22 (**Confirmed**), and a House tie prints the casting-vote notice. A
  House tie on it is lost.
- **The House quorum fallback.** House S.O. 54 (as at 23 July 2025, p. 37) gives "a quorum of 30
  Members", and the House Guide (pp. 16 to 17) says the quorum is one fifth of the House and is not
  reduced by a death or resignation. `HOUSE_OF_151_FROM` gives 31 for any date after 1 July 2019
  when the member count is unknown, and counting members on the day can under-count during a
  vacancy. **Verify** the figure from 2019 to 2025 and the size of the House since the 2025 election
  against House of Representatives Practice or the Votes and Proceedings before changing it, and
  prefer the number of seats to the number of members on the day. KI-8 is the fix this builds on.
  House S.O. 2 (as at 23 July 2025) also contradicts itself: "count out is the adjournment of the
  House because of the lack of a quorum of Members (currently 31 Members)" (p. 7), against "quorum
  of the House is at least one-fifth of the whole number of Members of the House (currently 30
  Members)" (p. 10), and S.O. 54 (p. 37) gives 30. The 31 looks left over from the House of 151.
  The member records give 150 on 35 of the 2026 House division days and 149 on the other 9 (2 March
  to 1 April), so the quorum was 30 either way. KI-83 is the same point for absolute majorities.
- **Template 1 in the House.** House S.O. 141(a), p. 64: a bill is "read a first time without a
  question being put", so no House division is on the first reading itself, but the router settles
  Template 1 on "first reading" in either chamber (**Confirmed**), and the vote sentence says the
  chamber voted on "a motion ... to introduce the [bill] and read it for a first time". A fix would
  fence rather than settle for the House. In the explainer, "which is where most first reading
  divisions come from" (the Senate) has no source, so check it against They Vote For You's own data
  or drop it, and "This vote is about procedure only" should say "in most cases", as Senate Guide
  No. 16 (p. 45) does: "in most cases a purely procedural step".

### KI-75

**Comments, router reasons and template sentences to correct or verify, none of which changes a
route.** Severity: Low. Status: Open. **Confirmed** against the rules named in each line, except
the last, which is **Verify**.

- `ContextBuilder`'s comment on S.O. 133 says the old Tuesday deferral window "was S.O. 55(c), on
  quorum counts". The House Guide (p. 58) gives it as S.O. 133's own rule: "On Tuesdays divisions
  called before 2 pm are deferred until after the discussion of the matter of public importance".
  The guide gives the same window for quorum calls under S.O. 55 (p. 18), which is likely where the
  mix-up came from. Dropping the window was still right, since the current S.O. 133 has none (KI-6).
- The router's comment that an urgency motion "Decides that the debate happens, not the issue" is
  backwards. "The question on an urgency motion shall be put at the expiration of the time for
  debate" (Senate S.O. 75(7), p. 57), and the motion is "That in the opinion of the Senate the
  following is a matter of urgency" (S.O. 75(1)(b)).
- The router's reason for "be considered an urgent bill" names only the House's time limits, but it
  is also the Senate's form (Senate S.O. 142(1), p. 82).
- The router's reason for the House Selection Committee says the question adopts its
  determinations; House S.O. 222(e), p. 92, says they are "treated as having been adopted when they
  are presented".
- A comment in `summary_wording.rb` attributes "even when this question is carried on the voices"
  to House S.O. 173; the words are the House Guide's (p. 77), and S.O. 173 is the absolute majority
  it explains.
- The comment above `SummaryWording#carried_amendment_note` says the Senate guide does not say what
  carrying a reasoned amendment does. The Senate standing orders do say what carrying an amendment
  does: "When amendments have been made the main question shall be put as amended" (S.O. 91(4),
  p. 63), and "this day 6 months" if carried "shall finally dispose of the bill" (S.O. 114(2),
  p. 71). The comment is why the note is empty in the Senate, so a Senate draft never says what its
  result leads to: at Senate 14 September 2026 #7 the draft ends at "The text of the bill is
  unchanged either way.", where "When amendments have been proposed but not made the question shall
  be put as originally proposed" (S.O. 91(5), p. 63).
- The prompt's rule 7 gives "House of Representatives Guide to Procedures; House S.O. 146; Senate
  S.O. 114" as the source of its standard forms for `declines_second_reading`. House S.O. 146
  (p. 65) has only omitting "now" in order to insert "not"; the rule for reasoned amendments is
  House S.O. 145 (p. 65), which isn't cited. Senate S.O. 114 (p. 71) has only "this day 6 months"
  and "Other amendments ... provided that they are relevant to the bill"; the Senate forms the
  prompt lists, such as "the Senate rejects the bill", are in neither S.O. 114 nor Senate Guide
  No. 16.
- Template 2's explainer, in the Senate too, says a second reading amendment is "often called a
  'reasoned amendment' in the House of Representatives". The House Guide (p. 68) gives that name to
  amendments moved under House S.O. 145, which "must not propose the addition of words to the
  question" (S.O. 145(a)(iii), p. 65). A Senate amendment that adds words at the end of the motion,
  as at Senate 14 September 2026 #7, is not what the House means by it, so the aside could go from
  the Senate's explainer.
- The router's comment above `production_of_documents` describes Template 8 as the chamber
  "ordering the government to hand over papers it holds". An order can require a document to be
  created: "There is also no requirement that a document be one that is already in existence"
  (Senate Guide No. 12, p. 30). Template 8's own explainer already says so.
- Template 23 says of the gag that "the Senate has no equivalent, and its own guide says there is no
  ability to gag a senator". That is true of "no longer heard" (Senate Guide No. 2, p. 6), but
  Senate S.O. 196 (p. 100) has "be further heard" (KI-68).
- KI-44 and the code it describes are cautious about House amendments printed in Hansard only for
  the record. The House Guide's note (p. 75) describes the guillotine as it was before S.O.s 83 and
  84 were omitted on 27 July 2022; S.O. 85(c) now treats circulated amendments to an urgent bill as
  moved. The caution is harmless.
- Senate wording: Template 20 should say a Senate order of the day is "discharged" (S.O. 97(4), p.
  65) and a motion once moved "cannot be withdrawn without leave" (S.O. 83(3), p. 61); Template 19
  should allow adjourning a debate "to a later hour of the same day" (S.O. 201(1), p. 101); Template
  13 should drop "permanent"; Template 3's amendment effect is wrong for a request; and the
  suspension effect clause's "immediately" overstates Senate Guide No. 5 (p. 13), which says a
  suspension "allows the senator to take the course of action to which the motion was directed".
- Template 9's notice and disallowance periods (Senate Guide No. 19, pp. 57 to 58) are right for the
  usual case, but the guide notes exempt and unusual instruments (p. 58). A constitution alteration
  bill's "will go to the [other chamber]" depends on where the bill started, the same problem as
  KI-1.
- Deferred and successive divisions are cited from the House's rules only. `earlier_debate.rb` says
  a deferred division is put "often at the start of the next sitting day (House S.O. 133)"; in the
  Senate a division called after the cut-off "shall be taken on the next day of sitting, at a time
  fixed by the Senate" (Senate S.O. 57(3), p. 47), and in 2026 the Senate took some days or weeks
  later. `ARCHITECTURE.md` section 4 gives only House S.O. 131 for successive divisions; the
  Senate's is S.O. 101(3), p. 66. The comment on `ContextBuilder::DEFERRED_STATEMENT` says it reads
  "either chamber's words", which KI-81 shows it doesn't.
- `SummaryWording#constitution_alteration_clause`, for a third reading carried with fewer
  ayes than an absolute majority, says whether the bill passed "does not follow from the division
  figures alone". Senate S.O. 135, p. 79, says what follows: "the bill shall be forthwith laid aside
  without any question being put". The House sentence is the same, and House S.O. 173, p. 73, says
  that if an absolute majority "does not agree to the third reading of a bill which proposes an
  alteration of the Constitution, the bill shall be laid aside immediately and may not be revived
  during the same session of Parliament". The Senate sentence, and the absolute majority notices,
  also say "members" of the Senate where the Senate says senators (Senate Guide No. 3, p. 9).
- **Verify** against House of Representatives Practice, Odgers' or the Act itself, since neither the
  guides nor the standing orders cover them: Template 10's "Neither has any legal effect and neither
  forces anyone to resign", Template 12's account of a select committee's dissolution after its
  final report, the Legislation Act 2003 for Template 9, and the
  House of Representatives (Quorum) Act 1989 and the Senate (Quorum) Act 1991. The Parliament Act
  1974 for Template 21 is KI-19.

### KI-78

**Choices the pipeline made are not marked as choices, so they could be defended as rules or
"fixed" as errors.** Severity: Low. Status: Open. **Confirmed** against the rules named.

None of these is wrong. Each is a decision this project made, not something a standing order or
guide requires, and the code should say so where it makes it:

- Template 17's "not the merits" (KI-58): neither chamber confines debate on a suspension to the
  reasons for suspending. A suspension moved during other business must be relevant to it (Senate
  S.O. 209(3), p. 104; House S.O. 47(c)(i), p. 33), and nothing more.
- "X MP" for House members is the site's own form (KI-24), not something House S.O. 64 requires.
- "an arrangement the House agreed on <date>" (KI-52): Hansard's word is "resolution", and calling
  it "not a guillotine" is an inference from the House Guide (p. 75: "Instead of using the formal
  guillotine procedure outlined above, a Minister may move a motion to suspend standing orders").
- A tied House division is "not decided by the division figures" rather than guessed (KI-18).
- `declines_second_reading` as true or false, and which form is which: the House Guide lists the
  forms without classifying them (pp. 68 to 69), and "carriage of a second reading amendment would
  likely be regarded as preventing further progress on the bill" (p. 70), so `false` does not mean
  the bill can proceed.
- Template 2's four uses are the Senate guide's list (KI-13), applied to both chambers. In the
  House, outright defeat is S.O. 146's "not" amendment, and an amendment "should amount to more
  than a direct negation" (House Guide p. 69).
- Framing sentences with no rule behind them: Template 8's "a vote about access to the documents",
  not "about the subject"; Template 9's "Giving notice matters as much as the vote"; Template 19's
  "not what the parliament decides"; Template 27's "not on whether the chamber agrees"; Template
  10's "same class of vote"; and the closure explainer's "because the timetable has taken its
  place", where House S.O. 85(d) and Senate S.O. 142(5) give no reason.
- Heuristics: `MoverFinder`'s three-speech window, the validator's word lists, the 400-character
  limit on "by leave" position statements, recognising a divided question only by "minus" or
  "except", the Monday 12:00 to 12:59 deferral window, and the fallback constants (39, 76, 30, 31).
- `ContextBuilder#closed_template_id` takes the motion a closure cut short to be the last one moved
  by someone else. Senate S.O. 199(3) (p. 101) bars a senator who has spoken in the debate from
  moving the closure "other than a minister", so a minister can close the debate on their own
  motion, and the code would then pass that motion over.
- Amendments are taken as circulated whenever the chair prints terms or names a circulator and no
  move is found. That held in all 46 Senate cases sampled on 1 October 2026, but the rule behind it
  covers only a limitation of debate (Senate S.O. 142(4)), and KI-70 is the exception.
- "on behalf of" for an urgency motion's proposer (KI-55): Hansard says "at the request of", as
  Senate S.O. 83(1) (p. 61) does for a notice.
- Routing on the chair's question rather than the heading, and quoting only the mover's sentences
  (ADR 0005), are design, resting on Senate Guide No. 17's account of what a guillotine does.

### KI-82

**A draft can't say that its division was deferred from an earlier day, or that it replaced an
earlier decision.** Severity: Low. Status: Open. **Read**, from Hansard and the drafts.

A Senate division called after the cut-off "shall be taken on the next day of sitting, at a time
fixed by the Senate" (Senate S.O. 57(3), p. 47), and in 2026 some were taken weeks later: Senate
4 March 2026 #7 decided a motion moved on 5 February (`uk.org.publicwhip/lords/2026-03-04.142.3`).
A question can also be put again by leave and divided on afresh (Senate Guide No. 3, p. 9, on
divisions "held again by leave"; S.O. 88, p. 62): Senate 16 September 2026 #12 negatived a general
business motion that Hansard records as "Question agreed to." 38 minutes earlier
(`uk.org.publicwhip/lords/2026-09-16.142.2`, recommitted by leave at 165.2 after a party's mistake
in its directions). Both drafts report the right result. Neither says when the motion was moved,
or that an earlier decision was replaced, and no template has a place to, so a reader can take a
month-old motion for that day's. `EarlierDebate` already has the date of the move. Whether drafts
should say so is a catalogue decision.

The House is the same. Its eight deferred divisions of 2026 (10 February #1, 5 March #1, 14 May
#1, 28 May #1 to #4, 19 August #1) were put on the next sitting day "without amendment or further
debate" (House S.O. 133(d), p. 60), and no draft says the vote was deferred. The House also replaces
a division: after "That the House divide again", "the result of the subsequent division shall be the
decision of the House" (S.O. 132(b), p. 60). The division that miscarried stays in TVFY and would be
drafted as a decision. None in 2026.

### KI-83

**The absolute majority is worked out from the members on the day, not the fixed figure the rules
give.** Severity: Low. Status: Open. **Read**; **Verify** before changing anything.

`ParliamentaryOutcome#absolute_majority` is half the senators current in They Vote For You's member
records on the day, plus one, falling back to 39, and its comment says a known member count
"supersedes" the guides' figure. Senate Guide No. 3, p. 9, gives an absolute majority as "more than
half of all possible votes (39)"; the standing orders' front matter, p. vi, gives "Absolute majority
39"; and S.O. 209(1), p. 104, says "an absolute majority of the whole number of senators". During a
vacancy the code would ask for 38. The member records have 76 senators on every Senate division date
of 2026, so no draft was affected: it is right for now only because no seat was vacant. Whether a
vacancy lowers "the whole number of senators" should be checked in Odgers' Australian Senate
Practice first. This is the Senate counterpart of KI-74's House quorum point, where the advice is
the same: prefer the number of seats to the number of members on the day. Test in
`template_compiler_spec.rb` "constitutional and parliamentary procedures".

The House is the same, and there it has happened. The member records have 149 members from 2 March
to 1 April 2026, so the code gives 75 on those nine sitting days, against 76 in a House of 150 (House
Guide pp. 2 and 77; House S.O. 2, p. 7, "a majority of the membership of the House (including the
Speaker)"). No House division in that period had exactly 75 ayes, so no draft was affected.
**Verify** whether a vacancy lowers the figure, in House of Representatives Practice.

### KI-85

**A House division with six or fewer on a side is not handled.** Severity: Medium-High. Status:
Open. **Inferred** from the code and the standing order; **Verify** how such a division reaches
They Vote For You.

House S.O. 127 (amended 23 July 2025, p. 58): "If, after the doors are locked, there are six or
fewer Members on one side in a division, the Speaker shall declare the decision of the House
immediately, without completing the count. The names of the Members who are in the minority shall
be recorded in the Votes and Proceedings." The House Guide (p. 56) still says "four or fewer".
Nothing in the pipeline knows this rule. If the record of such a division lists only the minority,
its turnout is six or fewer, `ParliamentaryOutcome#want_of_quorum?` is true, and the draft says the
question was "not decided, because fewer than a quorum of members voted": a decision the House made,
reported as never made. `Division#passed?` would also read the result from a one-sided count, which
may be the wrong way round. No 2026 House division had six or fewer on a side, but six had seven
(for example House 11 March 2026 #2 and #5, and 4 June 2026 #12). First check how Hansard, the
openaustralia-parser and the loader record one. A fix would treat a one-sided House count of six or
fewer as S.O. 127 rather than want of quorum, take the result from the Chair's declaration after the
division, and say so. Test in `template_compiler_spec.rb` "constitutional and parliamentary
procedures".

### KI-92

**A senator's position on parts of a question, recorded by leave just after its division, never
appears in a draft. Whether it should is a decision for the team.** Severity: Low. Status: Open.
**Read**.

At Senate 14 September 2026 #8 Senator Payman voted no, then said "by leave—In the interest of time,
I ask to have my support recorded for parts (a), (b)(i) and (b)(iv)"
(`uk.org.publicwhip/lords/2026-09-14.41.1`). The draft says "Nobody voted against their party on this
occasion", true by the record, and nothing of her stated support for three of the amendment's five
parts. Senate Guide No. 3, p. 8, provides for a vote recorded by leave instead of a division ("A group
of senators voting against a motion may have their vote recorded in the Journals, by leave, as an
alternative to a division"); a statement after a division, qualifying the senator's own vote in it,
is not described in the standing orders or guides read for this entry. It is not a vote, and must not
be counted or called a rebellion. `DivisionXml::POSITION_RECORDED` already recognises such statements,
but only to walk past them when looking for a guillotine, and the context ends at the division, so
they never reach a draft.

A decision is needed, not a fix: whether a draft should note such a statement, in Hansard's words and
with no count. If it should, the tests belong in `division_xml_spec.rb`, for finding the statement
after the division, and `template_compiler_spec.rb`, for the note.

### KI-93

**Template 8's explainer speaks to the writer, calls a Senate order a power of "the parliament", and
doesn't say that the documents become public only when tabled.** Severity: Low. Status: Open.
**Confirmed** by replaying Senate 14 September 2026 #10 on 15 October 2026; the text is fixed, so it
is in all 107 Template 8 drafts of the 2026 run.

At Senate 14 September 2026 #10, an order for documents on the Intergenerational Trust Fund for the
People of the Republic of Nauru, carried 35 to 19, the explainer reads:

- "This is a vote about access to the documents. It is not a vote about the subject the documents
  deal with, and the summary should not suggest otherwise." The last clause is an instruction to
  whoever writes the summary, printed in the public text. The first two sentences are a choice
  (KI-78).
- "An Order for the Production of Documents is a power the parliament uses to make the government
  hand over papers ...". The order is the Senate's: "Documents may be ordered to be laid on the
  table" (Senate S.O. 164(1), p. 90), a power the Senate has "through section 49 of the
  Constitution" (Senate Guide No. 12, p. 30).
- "hand over": the order is that documents be laid on the table, and "When returned the documents
  shall be laid on the table by the Clerk" (S.O. 164(2), p. 90); tabled documents become public
  (Senate Guide No. 10, p. 26). The explainer says governments "sometimes resist an order", but not
  that the documents become public only once they are tabled, so a reader of "requiring the
  Government to produce documents, which means it was successful" can take them as already
  released.

Nothing in a draft is false, which is why this is Low. A fix belongs in
`templates/8_production_of_documents.md`: drop "and the summary should not suggest otherwise", say
"the Senate", and say that the documents are to be tabled, and so made public, by the date the order
sets. Test in `template_compiler_spec.rb` with a Template 8 compile whose explainer has no "summary"
and says "the Senate".

## Open: pipeline

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

### KI-58

**Models still pick remarks aimed at other members as the mover's case on some divisions.**
Severity: Medium. Status: **Partly fixed**. **Confirmed** from four local models' drafts on
1 October 2026.

Fixed in the prompt: rule 5 asks for sentences about the motion, the bill or the policy, not about
other members or parties or addressed to them, and says an empty list is the usual answer for
Template 17, whose scope the team kept as "why the rules should be set aside, not the merits"
(decided by Blake, 30 September 2026; `extraction_prompt_spec.rb` "asks for the case rather than
remarks aimed at others, and says Template 17 usually has none"). The Reviewer Only report lists
quoted sentences that say "you" or name another member, as a prompt only (`reviewer_report_spec.rb`
"flags a quoted explanation that speaks to someone or names another member").

Still open: the rule worked at Senate 12 August 2026 #4, where no model picked the remark aimed at
others this time, but not at Senate 20 August 2026 #23, where three of four models still picked a
sentence addressed to "you", and one also picked a sentence about another member that names nobody
(KI-76). On Template 17, three of four models followed the rule; the fourth had run out of its
reasoning budget. Whether models choose better can only be judged on real output: **Verify** with a
Bedrock run on those two divisions, compared by a person before and after. KI-64 may be the other
side of the same rule: a model too cautious to quote anything.

### KI-61

**Sentences left out between quoted ones are not marked.** Severity: Low. Status: **Open, deferred
by decision** (Blake, 30 September 2026), to be thought about further and reviewed.

When the explanation quotes sentences that are not consecutive in Hansard, `EvidenceSections` prints
them as separate blockquotes, which is the only sign of a gap. Nothing tells a reader that sentences
between them were left out, and a reader could take them for consecutive: at House 18 August 2026 #3
one model quoted S2.118 to S2.120, S2.122 and S2.124, three of them one paragraph in Hansard. The
options considered were a "[...]" line between non-adjacent passages, "(sentences omitted)", or
leaving them as they are, which was chosen for now. Any of them is template text, so it does not
affect ADR 0005. When this is revisited, the place to change is `EvidenceSections#explanation`, and
`Transcript#passages` already says where one passage ends and the next begins.

### KI-62

**The mover of a closure was taken as the mover of the question it brought on.** Severity: High.
Status: Open. **Confirmed** by the draft and by rebuilding its packet from the day's ParlParse XML.

At Senate 17 September 2026 #1 the chair put "The question is that the second reading be agreed to"
straight after a senator moved "That the question be now put" (S17.1 to S17.2, speech
`uk.org.publicwhip/lords/2026-09-17.11.1`). `MoverFinder` took the latest "I move" before the
question, which was the closure's, so the draft said the second reading motion was "introduced by"
that senator and quoted "That the question be now put." under Motion Text. The second reading
motion is not in that day's Hansard before the vote, so it was moved on an earlier sitting day. The
draft passed validation, so an editor would see a plausible draft with the wrong motion in it.
KI-54 covers the closure's own division; this is the question the closure then brings on. A fix
belongs in `MoverFinder`, so that a closure is passed over when the question put is not the closure
itself, and would be tested in `mover_finder_spec.rb` and `context_builder_spec.rb` "with a
closure". KI-84 is the same mechanism reached through a deferral, so a fix should cover both.

### KI-63

**A motion moved in an earlier section of the same debate was not found, so a suspension of
standing orders was routed as a censure.** Severity: High. Status: Open. **Confirmed** by the
failed draft and by listing the day's ParlParse XML.

At House 17 September 2026 #1 the motion "That so much of the standing and sessional orders be
suspended as would prevent the Member for Herbert from moving the following motion immediately"
(moving no confidence in a minister) is in `2026-09-17.4.3`. The debate on it runs on through
sections 5 and 6 with no new heading, and the division is `2026-09-17.7.1`. Stage 1 looks for the
motion beside the division, so it found neither the motion nor its mover. The chair's question was
only "that the motion be agreed to", so the router fell back to `GENERAL_MOTION_FALLBACK`, the model
chose Template 10 (Censure Motion) from the motion the suspension would have allowed, and
validation failed on the missing `target_name`. `EarlierDebate` then added speeches from 10 and 16
September, warning that the motion "was not moved in the speeches beside it". Built from the
Division record without Hansard, the same division routed by rule to Template 17, because the
record's motion text holds the suspension wording. KI-16's rule is right once the motion's words
reach the router; the gap is in finding them. A fix would look back through earlier sections of
the same sitting day under the same heading before earlier days, and would be tested in
`context_builder_spec.rb`.

### KI-64

**The model rarely pointed at the mover's reasons.** Severity: Medium. Status: Open. **Verify**
against Hansard before changing anything.

Over the 12 drafts that compiled on 12 October 2026, Qwen3.6-35B-A3B (UD-Q4_K_M) gave explanation
references for one (Senate 17 September 2026 #8), so the other 11 print "No explanatory claims
recorded." Some of those votes may have had no debate to quote, such as rearranging business, a
third reading and an item standing as printed, and for those an empty section is right. Not yet checked:
whether the second reading amendments at Senate 17 September 2026 #9 and #10 had speeches giving
reasons that the model should have quoted. If they did, KI-58's wording in the prompt, which asks
for the case rather than remarks aimed at others, may have made the model too cautious.
Senate 17 September 2026 #9 and #10 are among the second reading amendments moved straight after
another division, where the mover's earlier speech never reaches the model (KI-90), so check them
against that cause first.

### KI-65

**A motion moved at another senator's request is described as the mover's own.** Severity: Low.
Status: Open. **Confirmed** from the drafts and the day's ParlParse XML.

At Senate 17 September 2026 #4 and #5 one senator moved two references to committees standing in
other senators' names: one "At the request of" the senator whose business it was, the other a
notice standing in another senator's name, as amended. Both drafts open with "a motion introduced
by" the senator who moved it. #4 quotes "At the request of Senator ..., I move:" as its
introduction, so a reader can see who it belonged to; #5 quotes nothing that shows it. The question
put names the senator whose business it was in both, so the information is in the packet.
`MoverFinder` already reads "in the name of" for its weaker `notice_owner` sign, which is where a
fix would start.

### KI-67

**The sitting-day retry has no limit on its size.** Severity: Medium. Status: Open. **Confirmed**
from the prompt and reply saved for the retry.

The retry's packet takes the last 200 speeches before the division whole
(`DataLoader::DivisionXml::CONTEXT_SPEECH_LIMITS`), however long they are, and `EarlierDebate`
searches earlier sitting days exhaustively. At House 16 September 2026 #6 that came to a user
prompt of 453,534 characters: 123,391 tokens to Qwen3.6-35B-A3B (UD-Q4_K_M), against 3,308 for the
first call. Through llama.cpp on a local machine it took 18 minutes to read. The model then
repeated one sentence until the prompt and its reply filled the server's 131,072-token context,
and gave no answer. The draft was built from the first reply, as
`DivisionSummarizer#widened_attempt` intends, so the cost was 26 minutes for a retry that could not
have helped, since this question has no separate terms (KI-4). A model with a smaller context
window would refuse a prompt this size outright, and on Bedrock every model run pays to read it.

The packet also named an amendment moved at 5:38 PM as this question's motion, and told the model
"The motion is settled": the latest "I move" before the question taken as its motion, as in KI-62.
The retry gave no answer, so this did not reach the draft.

This is the fourth retry found reading the whole day when it could not help, after KI-32, KI-44
and KI-59. Each of those was fixed by stopping one trigger, and nothing yet bounds the retry itself.
A fix could give the sitting-day tier a character budget, as `EarlierDebate::MAX_CHARS` does for
earlier days, or skip the retry and tell the reviewer when the packet would exceed one. It would be
tested in `context_builder_spec.rb` and `division_summarizer_spec.rb`.

### KI-71

**The prompt does not connect a House mover's name with the seat or office the chair calls them
by.** Severity: Medium. Status: Open. **Confirmed** (the gap and the rule); that it caused a
failure is **Inferred** from the model's reasoning.

House S.O. 64 (as at 23 July 2025, p. 40) bars referring to a Member by name: a Member is referred
to by their ministerial office, their parliamentary office or their electoral division. So the
House chair puts "the amendment moved by the honourable member for [division]", while the prompt's
`<motion_as_moved>` gives the mover only by name ("Moved by: [name] (speech S[n])."). Stage 1
already knows they are the same person, since `MoverFinder` resolved the member. On 1 October 2026
the contradiction sent Qwen3.5-9B into a loop at House 18 August 2026 #3, going by its reasoning,
and its draft failed validation. The same gap was in the sitting-day retry for House 16 September
2026 #6 on 13 October 2026, where the chair named "the honourable member for Kooyong" and the
prompt gave the member's name. A fix would add the seat or office to the "Moved by" line for House
divisions ("Moved by: [name], the member for [division]"), and offices as well as seats, since "the
Minister for ..." or "the Leader of the House" confuses in the same way. The Senate chair names
senators, so the gap looks House-only. Test in `extraction_prompt_spec.rb`.

### KI-76

**The Reviewer Only section leaves out things a reviewer needs.** Severity: Low. Status: Open.
**Confirmed** from drafts, except where marked.

- A draft from `rake ai:draft_local` does not name the saved reply it was built from, or say
  whether that reply was cut off, so matching a draft to its reply means opening the saved prompts.
  The reply files are named by database id, which differs between machines.
- The "Mover" table has no row for an urgency motion's proposer, so a reviewer cannot see where "on
  behalf of Senator ..." came from (`ReviewerReport#mover_rows`). **Read.**
- "Explanation sentences to look at twice" (`ReviewerReport::POINTED`) looks for "you", "Senator X",
  "member for X", "Prime Minister" or "Minister X", so at Senate 20 August 2026 #23 it missed a
  sentence that described another member without naming them. No pattern can catch every such
  phrase, so the list should say it is a prompt for the reviewer, not a complete check.
- The "Title" row quotes the heading as stored on the Division record, such as "Securing the Ndis
  for Future Generations", though the draft's own title now reads "NDIS" (KI-48).

### KI-77

**The local model tools lose or misreport a reply that does not finish.** Severity: Low. Status:
Open. **Confirmed**.

`LocalModelClient`, used by `rake ai:draft_local` and `ai:summarize_division_local`, writes the
prompt and reply to `tmp/llm_replies/` only once the server has answered. A request that times out
leaves neither, so the runs most worth looking at leave nothing to read: on 1 October 2026 two
divisions that timed out for one model left no files. Writing the prompt before sending the request
would fix it. Separately, a reply cut off for length is always reported as "model wrote
<max_tokens> tokens without finishing (max_tokens in config/local_model.yml)", but at House
16 September 2026 #6 the model wrote 7,681 tokens and ran out of the server's context instead
(KI-67), so the message points at the wrong setting. It should give the number of tokens actually
written and say whether `max_tokens` or the server's context ran out.

### KI-79

**A draft said an amendment was agreed to when no amendment was moved or found, and passed
validation.** Severity: High. Status: Open. **Confirmed** from the draft.

At House 16 September 2026 #6 the question was "The question is the bill be agreed to.", the final
question of consideration in detail (KI-4). The model chose Template 4, an amendment template,
though Stage 1 found no mover and no terms, and the model gave no motion references and reported
"operative_motion" missing. The draft's title ended "Consideration in Detail Amendment", and it said
"a small majority voted for an amendment to the [bill] during the Consideration in Detail stage,
which means it was successful. The text of the bill has been changed accordingly." The last
sentence is `SummaryWording#amendment_effect_clause`, which Templates 3 and 4 print when the vote
succeeds. `ProvenanceValidator` recorded no errors, only the warning that the model had reported the
terms missing, so an editor would see a plausible draft saying this vote amended the bill.

Nothing compares the kind of template chosen with the evidence found. An amendment template with no
terms, no amendments circulated and no mover is the case to catch. A fix belongs in
`ProvenanceValidator` and would be tested in `provenance_validator_spec.rb`. Whether it fails the
draft or only warns the reviewer is a decision to agree first.

### KI-80

**A deferred vote the chair put by name, without restating its question, was drafted as a
closure.** Severity: High. Status: Open. **Confirmed** from the draft, the model's saved reply and
Hansard, and by replaying the division on 15 October 2026.

When the Senate takes a deferred vote, the chair may name it rather than restate the question. At
Senate 5 March 2026 #8 the chair said "The question is the deferred vote, as moved by Senator Duniam
on Tuesday 3 March, be taken now." (`uk.org.publicwhip/lords/2026-03-05.37.2`). The motion deferred
was "That the Criminal Code Amendment (Keeping Australia Safe) Bill 2026 be considered during
private senators' time on Thursday, 5 March 2026" (`uk.org.publicwhip/lords/2026-03-03.208.3`,
deferred at 208.4). No router rule matched the chair's words, so `GENERAL_MOTION_FALLBACK` offered
Template 15 as advice, and Qwen3.6-35B-A3B (UD-Q4_K_M) chose Template 22, reasoning that "be taken
now" made it "a closure question". The prompt's description of Template 22 lists "That the ballot be
taken now" among its forms. The draft is titled "Closure of Debate", carries the closure explainer,
and says the senator's motion was "to end the debate and put the question immediately ... The
debate continued." The Reviewer Only section carried the deferral warning, which did not stop it,
and nothing checks a template the model chose against the router's advice.
`ParliamentaryOutcome#closure_variant` looks for "ballot be taken now", so it would not have
caught it either.

The words for taking a deferred vote are not the question decided: the division is the one called
on the motion deferred (Senate S.O. 57(3), p. 47). `EarlierDebate` had already found the motion
moved on 3 March, so the route could follow it when the chair's words only name a deferred vote. A
fix would route on that motion, and would be tested with this form of words.

### KI-81

**The deferral warning misses Senate wordings, and in both chambers fires on text that isn't the
chair's.** Severity: Low. Status: Open. **Confirmed** by running the pattern against each chair's
statement, and by replaying Senate 4 March 2026 #4 and House 18 August 2026 #10 on 15 October 2026.

`ContextBuilder::DEFERRED_STATEMENT` misses three ways the Senate takes a deferred vote: "a division
on amendment (1) on sheet 3472 moved by Senator Shoebridge was deferred"
(`uk.org.publicwhip/lords/2026-03-03.13.3`, Senate 3 March 2026 #2); "the votes on the amendments
moved by Senator Shorebridge and Senator Bell were deferred" (Hansard's spelling,
`uk.org.publicwhip/lords/2026-08-20.65.2`, Senate 20 August 2026 #14 and #15); and a deferred vote
put with no mention of deferral (`uk.org.publicwhip/lords/2026-03-25.17.3`, deferred at
`uk.org.publicwhip/lords/2026-03-23.216.2`; that division failed to draft). And because
`#deferred_by_chair?` reads every speech in the packet, not just the chair's statements, it fires on
a motion's own terms (Senate 4 March 2026 #4, whose motion at
`uk.org.publicwhip/lords/2026-03-04.23.1` mentions "the deferred vote") and, on the sitting-day
retry, on any deferred vote earlier in the day (Senate 5 February 2026 #10 and #11, from
`uk.org.publicwhip/lords/2026-02-05.36.2`). A false warning tells the model that the speeches beside
the division are not its debate. Where the warning was missed, the earlier debate was still added
for 3 March #2 and 20 August #15, because nothing beside the division moved anything and the
question mentioned an amendment: right, but not because the deferral was seen.

The Senate rightly has no time window to fall back on: S.O. 57(3), p. 47, takes the division "at a
time fixed by the Senate". A fix would read only the chair's statements putting this question and
its run, and allow words between "division" or "votes" and "deferred". Test in
`context_builder_spec.rb` "context warnings". This is the Senate half of KI-6.

The House has the same false warnings, from the same reading of every speech: House 10 February
2026 #2, 5 March 2026 #5, and 19 August 2026 #5 and #7 took it on the sitting-day retry from a
deferred question put that morning (`uk.org.publicwhip/debate/2026-02-10.3.3`, `2026-03-05.6.3`,
`2026-08-19.4.3`), and House 18 August 2026 #10 took it from a suspension motion's own terms, "(7)
standing order 133(b) (deferred divisions) being suspended" (`uk.org.publicwhip/debate/2026-08-18.95.3`).
The retry prompt for 18 August #10 carries the false warning in its context warnings. The eight
House deferrals of 2026 were all found, so KI-6's fix holds for finding them.

### KI-84

**A deferred second reading was credited to the mover of a second reading amendment negatived
before it, and the amendment was printed as its motion.** Severity: High. Status: Open.
**Confirmed** by replaying House 5 March 2026 #1 on 15 October 2026, the same as the draft, and by
reading its prompt.

On 4 March 2026 the Chair put the member for Goldstein's second reading amendment, which was
negatived on the voices, and then the second reading itself, on which "in accordance with standing
order 133 the division was deferred until the first opportunity of the next sitting day"
(`uk.org.publicwhip/debate/2026-03-04.122.2`). On 5 March the Speaker put it: "I shall now proceed
to put the question on the motion moved on the second reading of the [bill] ... The question before
the House is that this bill be now read a second time." (`2026-03-05.6.3`). The second reading had
been moved by the Treasurer on 11 February 2026 (`2026-02-11.4.3`). `EarlierDebate` found the latest
move, the amendment moved on 3 March (`2026-03-03.102.28`), and stopped there; the 4 March statement
saying the amendment had been negatived did not reach the packet. `MoverFinder` took that move as
the motion, and the prompt told the model the mover and that "The motion is settled". The draft says
a majority "voted for a motion introduced by Tim Wilson MP (Liberal Party) to pass the [bill] through
its second reading", quotes his "In addition to that, I move:" as the Motion Introduction, and prints
his amendment as the Motion Text. It passed validation.

House S.O. 133(d), p. 60: "The Speaker shall put all questions on which a division has been
deferred", so the deferred question is the one the Chair names, which need not be the last thing
moved. This is KI-62's mechanism, the latest move taken as the question's, reached through a
deferral rather than a closure. A fix belongs in `MoverFinder`, so that a move whose question was
already decided (here, "Question negatived" in the Chair's statement) or that doesn't match the
question put is passed over, and in `EarlierDebate`, which should keep looking back when the move
it finds isn't the question's. Test in `mover_finder_spec.rb` and `context_builder_spec.rb` with a
deferred second reading after a negatived amendment.

### KI-86

**The division page's "unanimously" is never printed.** Severity: Low. Status: Open. **Read**: the
code against `DivisionsHelper`.

`DivisionFacts.majority_strength` repeats `DivisionsHelper#majority_strength_in_words`'s thresholds
so that a draft never contradicts the page beside it, but not its first case: the page says
"unanimously" when `Division#unanimous?`, and the pipeline's copy gives "large majority" for a
fraction of 1. No 2026 division in either chamber had an empty side, so no draft is affected. In the
House a unanimous division is most likely at the third reading of a constitution alteration bill,
where the bells are rung "even when this question is carried on the voices" (House Guide p. 77). A
fix would return the page's word, and the vote sentence would need a form without "a ... majority".
Test in `division_facts_spec.rb` ".majority_strength".

### KI-87

**A word such as "delayed", "Committee" or "refer" anywhere in a Senate second reading amendment's
added words switches off the validator's check of `declines_second_reading`.** Severity:
Medium-High. Status: Open. **Confirmed** by running `ProvenanceValidator`'s own patterns on the
terms of Senate 14 September 2026 #7 on 15 October 2026. That a draft would then be wrong is
**Inferred**: no 2026 draft has been found wrong this way.

At Senate 14 September 2026 #7 the Greens' amendment (`uk.org.publicwhip/lords/2026-09-14.30.1`)
adds words that only note and call on the Government: "At the end of the motion, add ', but the
Senate: (a) notes the uncertainty ... caused by the delayed confirmation of continued funding for
the worker retention payment; and (b) calls on the Government to ...". `#declining_by_rule` settles
an opinion-only Senate addition as not declining (KI-11), but `REFERRAL_OR_DELAY` matches the stem
"delay" in "delayed", so it returns nil and the flag is left to the model, with no warning. The
model answered `false`, rightly. Had it answered `true`, the draft would have said "Because the
amendment sought to refuse the bill a second reading, a vote for it was in effect a vote against the
bill proceeding", the reverse of what the mover said ("The Australian Greens support this
legislation", 30.1). Of the 50 Senate second reading amendment drafts of 2026 whose amendment adds
words at the end of the motion, 19 have the check switched off this way. About ten of them do refer
the bill to a committee; the rest only mention a delay, a committee, a referral or a rejection
("by delaying taking action", "refused to refer the bill", a House committee named in an opinion,
"condemns and rejects legislation"). The model answered `false` in all 19; whether that was right
for each was not checked.

Senate Guide No. 16, p. 47, lists what such amendments may do: "express an opinion about the bill
or the government's handling of the related policy issues; reverse the effect of the motion so that
the bill is defeated at that point; refer the bill to a committee; and delay further consideration
of the bill". What decides the flag is whether the added words do one of the last three, not whether
they mention a committee or a delay. A fix belongs in `ProvenanceValidator::REFERRAL_OR_DELAY`,
which should match operative forms ("the bill be referred", "consideration of the bill be
postponed", "not be proceeded with", "this day 6 months") rather than stems anywhere, and a warning
that the flag was left unchecked would tell the editor when it still is. Test in
`provenance_validator_spec.rb` "declines_second_reading against the motion text": an opinion-only
addition mentioning "the delayed confirmation" and "the Committee's report" is settled as `false`,
and a real referral is still left to the model.

The opinion-only test also fails the other way. `OPINION_PATTERN` (notes, calls on, is of the
opinion, condemns, regrets, expresses, acknowledges, recognises, urges) has no "welcomes",
"supports" or "reaffirms", so added words that only welcome or support leave the flag to the
model too, with no warning. At Senate 14 September 2026 #8 the check settled `false` by rule only
because part (b) of the amendment says "notes"; part (a) alone ("welcomes the certainty ...")
matches neither pattern (run on 15 October 2026). No 2026 draft is harmed: of the 50 Senate drafts
adding words at the end of the motion, 10 have no opinion word, nine of them referrals and one
(Senate 31 March 2026 #15) already left to the model by `REFERRAL_OR_DELAY`. A fix could settle as
`false` any addition with no operative referral, delay or declining form, rather than require an
opinion word. Test: an addition that only "welcomes" is settled `false`.

### KI-88

**For a second reading amendment, the quoted reasons can be about the bill rather than the
amendment.** Severity: Low. Status: Open. **Confirmed** by replaying Senate 14 September 2026 #7 on
15 October 2026.

A second reading amendment is usually moved at the end of a second reading speech on the whole
bill, so most of the mover's sentences are about the bill. At Senate 14 September 2026 #7 the model quoted, from
`uk.org.publicwhip/lords/2026-09-14.30.1`, "... doesn't mean we must not also urgently address the
gap for educators in family day care and in-home care." The Greens' amendment says nothing about
family day care or in-home care; the opposition's amendment, voted on next (#8), does. A reader may
take the quote as the amendment's purpose. The model's reasoning checked the sentence against the
prompt's rule 5 on remarks about other members, not against the amendment's terms: rule 5's "Scope
to what the vote itself decides" list names Templates 8, 17, 18 and 9, and not 2.

A fix belongs in `extraction/extraction_prompt.rb` rule 5: a Template 2 line asking for the reasons
for the amendment's own terms, not for or against the bill as a whole. Test in
`extraction_prompt_spec.rb`; whether models follow it can only be judged on real output, as for
KI-58. The same trap waits where the amendment is moved apart from the speech: at Senate
14 September 2026 #8 the mover's earlier speech (`uk.org.publicwhip/lords/2026-09-14.28.1`) also
argues for the committee amendments, so once KI-90 brings it to the model, a draft must not quote
those sentences as the second reading amendment's purpose.

### KI-89

**"Question Put" gives the chair's question the time of the speech before it.** Severity: Low.
Status: Open. **Confirmed** by replaying Senate 14 September 2026 #7 on 15 October 2026; the time
the question was really put is **Inferred**.

At Senate 14 September 2026 #7 the draft says "At 1:04 PM, Senator Leah Blyth, in the chair, put
the following question". The XML gives the chair's statement
(`uk.org.publicwhip/lords/2026-09-14.37.2`) `time="13:04"`, the time the minister's summing-up
(37.1) began; the question came after that speech, before the 13:16 division.
`EvidenceSections#moment` prints the excerpt's XML time, which is right for a member's own speech
(KI-29's fix) but, for a chair's interjection, is inherited from the speech it follows. The longer
that speech, the further out the time.

A fix belongs in `EvidenceSections#question`, which could say "Before the division at ..." or leave
the time out when the chair's statement shares the previous speech's time. Test in
`template_compiler_spec.rb` beside "quotes each passage under the time of the speech and the
mover's name".

### KI-90

**A mover's reasons given before an earlier division in the same debate never reach the model, so
"About the Amendment" says "No explanatory claims recorded."** Severity: Medium. Status: Open.
**Confirmed** by replaying Senate 14 September 2026 #8 on 15 October 2026: the packet holds only the
move and the chair's question, and "Earlier debate added" is "none". How often it happens is
**Inferred** from the 2026 drafts and the cached XML.

At Senate 14 September 2026 #8 Senator O'Sullivan gave the opposition's case in his second reading
speech (`uk.org.publicwhip/lords/2026-09-14.28.1`, 11:25). Two hours later, after the minister's
closing speech and division 7 on the Greens' amendment, he moved the opposition's amendment with no
further words (`uk.org.publicwhip/lords/2026-09-14.39.1`), and division 8 decided it.
`DivisionXml#previous_speeches` stops at the previous `division` element, so the subdebate packet
held only 39.1 and the chair's question (39.2). `ContextBuilder#earlier_debate` is skipped whenever a
speech beside the division moves something (`moved_here`), and 39.1 does. Told that an explanation
can only be sentences the mover spoke, the model rightly found none. The Reviewer Only section says
only that there was no explanation and "Earlier debate added | none", so the editor isn't told the
reasons exist.

This is the usual Senate pattern when more than one second reading amendment is foreshadowed: "An
amendment proposed shall be disposed of before another amendment to the original question may be
moved" (Senate S.O. 91(2), p. 63), so each later one is moved after the previous one's division. Of
the 105 Senate second reading amendment drafts of 2026, 11 have their moving speech straight after a
division, and all 11 print "No explanatory claims recorded."; in four the mover had spoken earlier
under the same heading that day (Senate 31 March 2026 #15 and #21, 7 September 2026 #2, 14 September
2026 #8). Whether each of those speeches gave reasons for the amendment, and whether the other seven
movers spoke on an earlier day, was not checked. Senate 17 September 2026 #9 and #10, which KI-64
asks about, are among the seven. KI-64 looks at the model; this cause is in Stage 1, and may account
for part of KI-64's count.

A fix belongs in Stage 1: when the mover is found and the window starts at an earlier division under
the same heading, add the mover's own earlier speeches in that debate (`EarlierDebate` already finds
the same debate's speeches). `ARCHITECTURE.md` section 3 should say that the subdebate stops at the
previous division. Once fixed, KI-88 applies. Test in `context_builder_spec.rb`: a member speaks,
another member's amendment is divided on, then the first member moves theirs without a speech, and
the packet holds the first member's speech.

### KI-91

**Template 2's vote sentence says the amendment was "introduced by" the senator "to the" bill.**
Severity: Low. Status: Open. **Confirmed** by replaying Senate 14 September 2026 #8 on 15 October
2026.

At Senate 14 September 2026 #8: "a small majority voted against a second reading amendment
introduced by Senator Matt O'Sullivan (Liberal Party) to the [bill]". The explainer above it says "It
amends the motion instead", and the Amendment Text says "moved". The same senator's committee
amendment to the same bill, decided at Senate 15 September 2026 #1, reads "voted against an
amendment introduced by Senator Matt O'Sullivan (Liberal Party) to the [bill]": one vote on words of
opinion, one on the bill's text, in nearly the same sentence. Amendments "may be moved to the
question for the second reading" (Senate S.O. 114(3), p. 71), and are moved and proposed (S.O. 90
and 91, p. 63), while senators "introduce a bill" (Senate Guide No. 16, p. 45); such amendments "may
affect the passage of the bill but not its content" (Guide No. 16, p. 47).

"introduced by" comes from `TemplateCompiler#mover_details` and is shared by every template; if it is
the site's chosen style, KI-78 should say so. "to the" bill comes from
`SummaryWording#second_reading_amendment_sentence`. A fix: "moved by" for amendments, and for
Template 2 "an amendment ... to the motion for the second reading of the [bill]". Test in
`template_compiler_spec.rb` beside the Template 2 vote sentence.

### KI-94

**When there is nothing to quote, "About the Motion" prints "> No explanatory claims recorded." as a
block quote, in the pipeline's own term, whatever the reason.** Severity: Low. Status: Open.
**Confirmed** by replaying Senate 14 September 2026 #10 on 15 October 2026; 456 of the run's 867
drafts print it.

At Senate 14 September 2026 #10 the mover gave no reasons: the order was moved and put as formal
business, and a formal motion is "put and determined without amendment or debate" (Senate S.O.
66(3), p. 51; "Most orders for production of documents start with a notice of motion, which is moved
and determined during 'formal motions'", Senate Guide No. 12, p. 30). The draft's "About the Motion"
is the one line "> No explanatory claims recorded.", set in the same block-quote style as the
Hansard quotes below it, so it can be read as words someone said, and "explanatory claims" is the
pipeline's term, not a reader's. The same line prints whether the mover gave no reasons (here), gave
them where the pipeline didn't look (KI-90), or the model didn't point at them (KI-64), and the reader
can't tell which.

The line is `EvidenceSections::NO_EXPLANATION`. A fix: print it as plain text in a reader's words,
such as "The mover gave no reasons in the chamber.", and, once Stage 1 can tell a formal motion from
a debated one, say so. Test in `template_compiler_spec.rb` beside the existing "No explanatory claims
recorded." expectation, and update `spec/fixtures/division_summaries/test_1/expected_output.md`.
