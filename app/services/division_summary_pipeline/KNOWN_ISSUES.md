# Known issues in the division summary pipeline

`ARCHITECTURE.md` explains how this pipeline is meant to work. This file records where it does
not, so that the next person to pick it up starts from what is already known rather than
rediscovering it.

Every entry says what is wrong, where, what parliamentary source says so, and what a fix would
have to do. Entries are numbered `KI-n` so they can be cited from commits, issues and code
comments. Numbers are never reused; a fixed entry keeps its number and gains a `Fixed` status.

## Where these findings came from

They came from reading the pipeline against the two official procedural guides in September
2026:

- **House of Representatives, _Guide to Procedures_, 6th edition 2017** (reprinted September
  2018, amended June 2019), Department of the House of Representatives. Cited below as
  "House Guide" with the guide's own printed page numbers.
- **_Guides to Senate procedure_**, Department of the Senate, the 23 numbered guides, each
  marked "Last reviewed: June 2025". Cited below as "Senate Guide No. _n_".

Both are Commonwealth publications licensed CC BY-NC-ND 3.0 AU, so neither is committed to this
repository. Download them from aph.gov.au if you need to check a citation. Where a guide does
not settle a point, that is said rather than filled in: several entries below exist precisely
because the pipeline asserted something no source supports.

Neither guide is the last word. `House of Representatives Practice` and `Odgers' Australian
Senate Practice` are the definitive texts, and both guides say so. For anything load-bearing,
check there before publishing.

## How findings were verified

- **Confirmed** means the behaviour was reproduced by running the code, not inferred from
  reading it. The reproduction is described in the entry.
- **Read** means it follows from the source but was not executed.
- **Verify** means it needs checking against a primary source before anyone acts on it, and the
  entry says which one.

This register was compiled with AI assistance (Claude Code, claude-opus-5[1m]), and revised with the
same assistance in a later pass that fixed most of the entries and added KI-15 to KI-19. The
procedural citations are drawn from the two guides named above and should be checked against them;
the code behaviour marked **Confirmed** was reproduced against this working tree.

A **Fixed** entry keeps its full description of what was wrong, because that is what stops the same
mistake being reintroduced, and gains a note saying what the fix does and which spec holds it.

## Index

| ID | Severity | Status | Summary |
|---|---|---|---|
| [KI-1](#ki-1) | High | Fixed | Template 6's closing sentence ignored the vote result |
| [KI-2](#ki-2) | High | Fixed | Template 7 has no inversion handling for "does not insist" or "disagreed to" |
| [KI-3](#ki-3) | High | Fixed | Template 22 contradicts itself when a discussion is ended by calling on the business of the day |
| [KI-4](#ki-4) | High | Partly fixed | Seven real question forms fall through to Template 15 and are described as opinion-only motions |
| [KI-5](#ki-5) | High | Fixed | Absolute-majority questions are reported using a simple-majority test |
| [KI-6](#ki-6) | Medium | Fixed | Deferred and successive divisions defeat the context window |
| [KI-7](#ki-7) | Medium | Fixed | Template 24 states the wrong suspension period and the wrong Senate wording |
| [KI-8](#ki-8) | Medium | Fixed | House quorum threshold is hardcoded against a 2019 date |
| [KI-9](#ki-9) | Medium | Fixed | Template 2 overstates the effect of carrying a reasoned amendment |
| [KI-10](#ki-10) | Medium | Fixed | Template 17 asserts a purpose the question usually does not support |
| [KI-11](#ki-11) | Medium | Fixed | `declines_second_reading` is left to the model when the guides give a closed list of forms |
| [KI-12](#ki-12) | Low | Fixed | Template copy that the guides would sharpen (1, 8, 9, 14, 16, 18, 22, 26) |
| [KI-13](#ki-13) | Low | Partly fixed | Template 2 describes one of the four things a stage amendment can do |
| [KI-14](#ki-14) | Low | Fixed | `ARCHITECTURE.md` drift: template count, adjournment, Senate quorum |
| [KI-15](#ki-15) | High | Fixed | `declines_second_reading` and `sufficient_context` were coerced to true whatever the model returned |
| [KI-16](#ki-16) | High | Fixed | A suspension of standing orders was routed as whatever motion it quoted |
| [KI-17](#ki-17) | Medium | Fixed | The compiler's grammar tidying edited quoted Hansard |
| [KI-18](#ki-18) | Medium | Open | A tied House division cannot be resolved from the recorded figures |
| [KI-19](#ki-19) | Low | Verify | Template 21 cites the Parliament Act 1974, which neither guide mentions |

---

## Confirmed defects

### KI-1

**Template 6's closing sentence ignored the vote result.**
Severity: High. Status: **Fixed** by `TemplateCompiler#bill_stage_clause`, covered by the
"Template 6, reporting the result of the stage and not just the stage" examples in
`spec/services/division_summary_pipeline/template_compiler_spec.rb`.

`TemplateCompiler#prepare_compilation_data` built `stage_clause` from the bill stage alone.
Only the Constitution Alteration branch consulted `is_successful`, so a defeated division
compiled to a sentence stating the opposite of the one before it:

> At 05:00 PM, a majority voted against a motion ... to pass the Example Bill 2026 through its
> third reading, which means it was **unsuccessful**. This means the bill **has now passed the
> Senate** and will go to the House of Representatives.

A defeated second reading produced "This means they agreed with the main idea of the bill".
No spec covered a negatived Template 6 division, which is how it survived.

A second fault sat in the same sentence: "will go to the {{other_chamber}}" is only true of a
bill that originated in the chamber that just passed it. A bill that came from the other
chamber and passes here unamended goes to the Governor-General for assent (House Guide p. 87),
and one this chamber amended goes back with a schedule of amendments (House Guide p. 87-88).
The TVFY schema does not record where a bill originated (`bills` carries only `official_id`,
`url` and `title`), so the fix states the destination only when a `bill_originating_house`
attribute is supplied on the division data, and otherwise stops at "has now passed the
{chamber}". That is a placeholder seam of the same shape as `digest_section` and
`followup_link`; see `ARCHITECTURE.md` section 15.

**Confirmed** by compiling a Template 6 extraction with `result: "negatived"` at both stages.

### KI-2

**Template 7 has no inversion handling for "does not insist" or "disagreed to".**
Severity: High. Status: **Fixed** by `TemplateCompiler#message_form`, `#message_action_clause` and
`#message_effect_clause`, covered by the "Template 7, the forms a message question takes" examples in
`spec/services/division_summary_pipeline/template_compiler_spec.rb`.

`ProceduralRouter` routes `does not insist`, `insist on its amendment`, `disagreed to` and
`requests be made` to Template 7 (`procedural_router.rb`, `is_message_pattern`). Template 7's
only sentence is "to agree to the {{other_chamber}} amendments made to the
[{{bill_name}}]({{bill_link}})". So "That the committee does not insist on its amendments to
which the House of Representatives has disagreed" compiles to:

> At 09:20 PM, a majority voted against a motion ... to agree to the House of Representatives
> amendments made to the Example Bill 2026, which means it was unsuccessful.

That is wrong twice over. The amendments were the Senate's own, not the House's; and Senate
Guide No. 18 is explicit about the polarity: "if a majority votes against the motion, the
effect is that the amendments are insisted on". The same guide adds that an equally divided
vote flips it back the other way, because the tie shows the amendments no longer command a
majority, and that a further twist applies where the insisted-on amendment was itself one to
omit a clause. The chair of committees makes a statement explaining the result when this
happens.

"That the amendments be disagreed to" (House Guide p. 87) has the same problem: voting Aye
rejects the other chamber's changes, and the template says the opposite.

Requests under section 53 of the Constitution are a third distinct thing routed here. A request
is not an amendment: the Senate may not amend a taxation bill or an appropriation bill for the
ordinary annual services of government, so its proposed changes take the form of requests to
the House (Senate Guide No. 16; House Guide p. 88-89). "Pressed requests" are more distinct
still, and the House "has never recognised the power of the Senate to insist on or press a
request" (House Guide p. 89).

**Fixed** the way Template 28 handles the same class of error. The compiler reads the form off the
extracted `motion_text` (agree, disagree, insist, does not insist, request) and renders two clauses
from it: what was moved, and what carrying or defeating it did. The amendments are attributed to the
right chamber in each form, the defeated "does not insist" now says the amendments are insisted on,
and the Senate's equal-division twist and the chair of committees' statement are covered. Requests
get the section 53 explanation instead of an effect clause, since what happens next is the House's
call. The template's own explainer sets the family up rather than describing only the agree form.

Still open in this area: the further twist where the insisted-on amendment was itself one to omit a
clause (Odgers', via Senate Guide No. 18) is not distinguished from an ordinary insist.

**Confirmed** by compiling a Template 7 extraction with a "does not insist" motion text.

### KI-3

**Template 22 contradicts itself when a discussion is ended by calling on the business of the
day.** Severity: High. Status: **Fixed** by `TemplateCompiler#closure_variant`, `#closure_explainer`
and `#closure_action_clause`, covered by the "Template 22, the three questions that arrive as a
closure" examples in `spec/services/division_summary_pipeline/template_compiler_spec.rb`.

`ProceduralRouter` sends "That the business of the day be called on" to Template 22, and
`TemplateCompiler#followup_clause` already special-cases it correctly. But the template body and
its jargon explainer still describe a closure, so the compiled output says three things, two of
them wrong:

> **Jargon Explainer:** *This motion stops the debate and forces an immediate vote on whatever
> is being discussed. ... It does not decide the underlying question, **which is put to a
> separate vote straight afterwards**.*
>
> At 03:40 PM, a majority voted for a procedural motion ... to end the debate on cost of living
> and **put the question immediately**, which means it was successful. **There was no question
> before the Chair to decide**, so the House of Representatives moved straight to the next item
> of business.

House Guide p. 40-41 explains why: this motion "is used to curtail or preclude a discussion on
a matter of public importance, and can only be used in this context. This form of closure is
provided because there is no question before the Chair during an MPI" (S.O. 46(e)). An MPI is
"a discussion, on which no vote is taken" (House Guide p. 109), so the only division an MPI can
produce is this one.

**Fixed** without growing the catalogue, because that is a decision for a human (see KI-4). Template
22's explainer, the description of what was moved and the trailing clause are all now chosen from the
operative motion text, so the three questions that arrive here each read correctly: the ordinary
closure, calling on the business of the day, and "That the ballot be taken now" during the election of
a Speaker (House S.O. 11(h), Guide p. 41), which the router also now recognises. A defeated closure
says the debate continued, which it previously did not say at all.

A separate template for each would still be tidier than three branches inside one; that is a
catalogue decision, not a defect.

**Confirmed** by compiling a Template 22 extraction with motion text "That the business of the
day be called on."

---

## Routing gaps

### KI-4

**Seven real question forms fall through to Template 15.** Severity: High. Status: **Partly fixed**.

Template 15 is the fallback and it asserts "The motion records an opinion of the {{chamber}} and
has no legal effect". That sentence is therefore printed over every question no rule matches.
Each of the following was run through `ProceduralRouter.route` and returned
`GENERAL_MOTION_FALLBACK`:

| Question form | Source | What it actually is |
|---|---|---|
| "That the bill be considered urgent" | House S.O. 82, Guide p. 74 | Step one of the House guillotine. The allotment-of-time motion that follows is already routed to Template 18; this is the question that enables it, put immediately with no debate or amendment. Beware the keyword collision with Template 16 (Senate matter of urgency). |
| "That the bill stand as printed" | Senate Guide No. 16 | The final question in committee of the whole when no amendments were agreed to, the counterpart of "That the bill, as amended, be agreed to". `procedural_router.rb` correctly excludes it from Template 28, but nothing catches it afterwards. |
| "That the bill (as amended) be agreed to" | House S.O. 150(c), 153(a), Guide p. 72-73 | End of consideration in detail with the bill taken as a whole, or the report stage for a bill from the Federation Chamber. |
| "That the report of the committee be adopted" | Senate Guide No. 16 | Report from committee of the whole. The guide notes amendments are moved to this motion "especially if the committee of the whole stage reveals further action that the Senate may wish to take", so divisions do happen here. |
| "That the proposed expenditure(s) be agreed to" | House Guide p. 82 | The appropriation bill detail stage, put per portfolio or group of portfolios. |
| "That the words proposed to be omitted stand part of the question" | House S.O. 122(a), 123(c), Guide p. 52 | An **inverted** question: Aye keeps the original words and defeats the amendment. The guide calls the alternative forms "no longer used" in current House practice, so this is low priority for Australian data, but it is the standard form on the `php-compatibility` UK branch. |
| "That the House approves the form of agreement ..." | House Guide p. 94-95 | Approval of a legislative instrument, the mirror of disallowance. Some Acts require active approval before an instrument takes effect. "Changes no law" is exactly backwards. |

**Fixed so far**, without growing the catalogue:

- "That the bill be considered urgent" now routes to Template 18. It is not a separate procedure but
  the first of the two questions that impose a House time limit, which Template 18 already covers, so
  the template's explainer now describes both steps. The keyword collision with Template 16 is safe
  because the Senate matter-of-urgency rule is matched earlier.
- Template 15 no longer asserts "The motion records an opinion of the {chamber} and has no legal
  effect" over every question that reached it. That sentence is now printed only where the motion's
  own words are declaratory, and the explainer says plainly that the question did not match a known
  procedure and that what it does depends on its wording. Approval of a legislative instrument was
  the worst case: "changes no law" is exactly backwards, and it now goes unsaid rather than said
  wrongly.

**Still open**: five forms still land on Template 15 with no template that fits them - "That the bill
stand as printed", "That the bill (as amended) be agreed to", "That the report of the committee be
adopted", "That the proposed expenditure(s) be agreed to", and "That the House approves the form of
agreement ...". "That the words proposed to be omitted stand part of the question" is a sixth, and
is inverted like Template 28, though the House guide calls the form "no longer used" in current
practice. Each needs its own template, which takes the catalogue past 28: a decision to agree with a
human before writing, not a change to make unilaterally.

**Confirmed** by running each form through `ProceduralRouter.route`.

---

## Accuracy of compiled facts

### KI-5

**Absolute-majority questions are reported using a simple-majority test.** Severity: High.
Status: **Fixed** by `TemplateCompiler#absolute_majority_requirement` and
`#absolute_majority_notice`, covered by the Template 17 examples in
`spec/services/division_summary_pipeline/template_compiler_spec.rb`.

`TemplateCompiler` derives `is_successful` from `Division#passed?`, which is
`tied? ? false : aye_majority >= 1` (`app/models/division.rb`). Several questions need an
absolute majority, meaning a majority of all the members of the chamber rather than of those
voting:

- a motion to suspend standing orders moved **without notice**: 76 in the House (S.O. 47(c),
  Guide p. 2), 39 in the Senate (S.O. 209, Senate Guide No. 3);
- a motion to rescind an order of the Senate (S.O. 87, Senate Guide No. 3);
- the third reading of a Constitution Alteration bill, under section 128 (House S.O. 173,
  Guide p. 77; Senate Guide No. 3).

So a suspension carried 40 to 36 in the Senate would be reported "successful" when the chamber
did not agree to it. Note the qualifier that makes this tractable: the absolute majority applies
only to a suspension moved without notice. Moved on notice, by leave, or under a contingent
notice, a simple majority is enough, and Senate Guide No. 5 says most suspensions use contingent
notices precisely to avoid the higher bar. The pipeline cannot always tell which applies from
the question alone.

**Fixed** as described: the pipeline does not try to decide it. Where the ayes clear a simple
majority but not the absolute one, a notice beside the vote counts says which threshold applies and
why the record cannot settle it, and the draft goes to a person. The two cases are distinguished,
because they are not the same kind of doubt:

- a suspension of standing orders (Template 17) is conditional, so the notice gives both thresholds
  and says the question alone does not record how the motion was moved;
- section 128 on a Constitution Alteration third reading (Template 6), and rescinding an order of the
  Senate under S.O. 87, are unconditional, so the notice says the recorded result and the requirement
  disagree. Template 6 additionally stops asserting that the bill passed, rather than asserting the
  opposite from figures that cannot settle it either.

The thresholds come from the number of members actually sitting on the day where TVFY knows it (see
KI-8), and from the guides' own figures of 76 and 39 otherwise.

**Read** from `Division#passed?`; not reproduced against real division data.

### KI-7

**Template 24 states the wrong suspension period and the wrong Senate wording.** Severity:
Medium. Status: **Fixed** by `TemplateCompiler#suspension_period_sentence` and the
`{{suspension_form}}` placeholder, covered by the "Template 24, suspension periods and the two
chambers' wording" examples in `spec/services/division_summary_pipeline/template_compiler_spec.rb`.

`24_suspension_of_member.md` says a suspended member "is excluded for the remainder of the
sitting". House S.O. 94(d) (Guide p. 43-44) sets escalating periods instead: 24 hours on the
first occasion; three consecutive sittings on a second occasion in the same calendar year,
excluding the day of suspension; seven consecutive sittings on a third or later occasion.
Suspensions in a previous session, and orders to leave for one hour under S.O. 94(a), are
disregarded in that count.

The same guide adds detail the template could use: the exclusion covers the Chamber, all its
galleries and any room where the Federation Chamber is meeting, and petitions, notices of motion,
notices of questions and MPI proposals are not accepted from a member under suspension. The
member is not otherwise prevented from serving on a committee.

The template also renders "be suspended from the service of the {{chamber}}". That is the House
form. The Senate form is "suspended from the **sitting** of the Senate" (Senate Guide No. 2).

The standing order citation is partial too: Senate S.O. 203 covers naming, and "periods of
suspension are covered by standing order 204" (Senate Guide No. 2). The Senate guide does not
state what those periods are, so do not assert them; cite S.O. 204 or check Odgers.

**Fixed**: the House branch gives the escalating periods and the detail about what the exclusion
covers, the Senate branch says the form is "suspended from the sitting of the Senate" and points at
S.O.s 203 and 204 without asserting periods the guide does not state.

### KI-8

**House quorum threshold is hardcoded against a 2019 date.** Severity: Medium. Status: **Fixed**
by `TemplateCompiler#chamber_member_count`, which the durable fix below describes.

`TemplateCompiler#house_quorum_threshold` returns 31 for any date from 1 July 2019 and 30
before it, on the correct reasoning that the quorum is "at least one fifth of the whole number
of the Members of the House" (House of Representatives (Quorum) Act 1989; House Guide p. 16)
and the House grew from 150 to 151 seats in 2019.

The House size changed again at the 2025 election. If it returned to 150, the quorum returns to
30 and every division after that date is currently measured against the wrong threshold. This
needs checking against the AEC or the House's own records before anyone changes the constant.

The durable fix is to stop hardcoding dates: derive the threshold from the number of members
sitting in the House on the division's date, which TVFY already knows, and the question goes
away permanently.

**Fixed** that way. `Member.in_house(house).current_on(date).count` gives the size of the chamber on
the day, the quorum is one fifth of it rounded up, and the absolute majority in KI-5 is more than half
of it. The dated constant survives only as the fallback for when the member records are not loaded, so
the 2025 question no longer needs answering before the code is right: the answer comes from the data.
A `chamber_size` attribute on the division data overrides both, for fixtures and for any caller that
already knows.

This matters because of what the notice says. House S.O. 58: if a division shows fewer than a
quorum voting, the House has not made a decision on the question. Getting the threshold wrong in
either direction means telling a reader either that a decision was not made when it was, or the
reverse.

### KI-9

**Template 2 overstates the effect of carrying a reasoned amendment.** Severity: Medium.
Status: **Fixed** in `templates/2_second_reading_amendment.md`.

`2_second_reading_amendment.md` says "If agreed to in the House, it generally halts further
progress on the bill." House Guide p. 69-70 is markedly more cautious: "The standing orders are
silent on the effect of carrying a reasoned amendment, which has only occurred once (in 2016).
Following a statement by the Speaker, standing orders were suspended to enable the bill to be
restored." It then says only that "In general, carriage of a second reading amendment would
likely be regarded as preventing further progress on the bill."

So the one time it happened, the bill was restored. The template should say what the source
supports and attribute it, rather than stating a rule that does not exist.

**Fixed**: the explainer now says the standing orders are silent, that it has happened once, in 2016,
that standing orders were then suspended so the bill could be restored, and quotes the guide's own
"would likely be regarded as preventing further progress on the bill" rather than asserting it.

### KI-10

**Template 17 asserts a purpose the question usually does not support.** Severity: Medium.
Status: **Fixed** by `TemplateCompiler#suspension_purpose_clause`, covered by the "Template 17, the
purpose a suspension states for itself" examples in
`spec/services/division_summary_pipeline/template_compiler_spec.rb`.

`17_suspension_of_standing_orders.md` hardcodes "to allow the {{chamber}} to debate an urgent
matter regarding {{topic}}". Suspensions are moved for many purposes, and both guides list them:
to move a motion of which notice has not been given, to make a statement after leave was refused,
to table a document after leave was refused, to rearrange business, to bring on a disallowance
motion, to enable a censure or no-confidence motion to be moved immediately, to move a guillotine,
and to give non-ministers the power to rearrange business that S.O. 56 gives ministers (Senate
Guide No. 5; House Guide p. 2, p. 53-54, p. 75).

The suspension motion states its own purpose, in the words after "as would prevent". That is
where the clause should come from. A stock "to debate an urgent matter" is a guess, and it reads
as a characterisation of the matter rather than a description of the vote.

The template also produces a visible stutter when the topic is itself about urgency: "to debate
an urgent matter regarding an urgent matter".

**Fixed**: the clause is taken from the motion's own words after "as would prevent", falling back to
the topic and then to nothing. The stock "urgent matter" wording is gone from the template, which
also removes the stutter, and the explainer now lists the purposes both guides give.

### KI-12

**Template copy the guides would sharpen.** Severity: Low. Status: **Fixed**, and extended to
Templates 3, 4, 5, 10, 20, 25, 27 and 28 while the guides were open.

None of these is wrong, but each leaves out the thing a reader most needs.

- **Template 1 (first reading)** says divisions at this stage are rare without saying why. In
  the House the Clerk reads the bill a first time "without any question being put" and no debate
  occurs (House Guide p. 63-64), so a House first-reading division essentially cannot arise. The
  Senate does debate the first reading of bills it may not amend (Senate Guide No. 2 time-limit
  table), which is where such a division comes from.
- **Template 8 (production of documents)** could cite the source of the power, section 49 of
  the Constitution as continued by section 5 of the Parliamentary Privileges Act 1987; note that
  there are "no automatic exemptions or exceptions for cabinet submissions or national security
  documents"; and mention the 30-day rule under S.O. 164 for seeking an explanation of
  non-compliance (Senate Guide No. 12). It could also note that an order may require a document
  to be created, not merely handed over.
- **Template 9 (disallowance)** omits deemed disallowance, which changes what a defeated
  disallowance division means: if a disallowance motion is not withdrawn or otherwise resolved
  within 15 sitting days **of the notice being given**, the instrument is disallowed anyway
  (Senate Guide No. 19; House Guide p. 93).
- **Template 14 (Selection of Bills Committee)** could note that the motion for the adoption of
  the report "may be amended to vary the details of the recommendations or to add or delete
  bills" (Senate Guide No. 16), since a division here is often on such an amendment rather than
  on the report.
- **Template 16 (matter of urgency)** could open with the distinction the Senate guide leads
  with: a matter of public importance is a discussion with no vote, whereas an urgency motion
  takes the form "That in the opinion of the Senate the following is a matter of urgency" and is
  voted on. It needs four senators besides the proposer to proceed. Odgers', quoted in Senate
  Guide No. 9, makes the point a reader most needs: the vote is technically on whether the
  subject is urgent, but "is often regarded ... as a vote on a substantive matter". That can be
  stated neutrally and is more useful than the current "records an opinion and changes no law".
- **Template 18 (guillotine)** could note that once a time limit is in place the closure cannot
  be moved for the affected proceedings (House S.O. 85(c), Guide p. 40; Senate S.O. 142(5),
  Senate Guide No. 17), and that the House procedure is two questions rather than one (see
  KI-4).
- **Template 22 (closure)** could carry the same cross-reference from the other side.
- **Template 26 (adjournment)** is accurate, including that a defeated adjournment returns the
  chamber to its interrupted business (House Guide p. 15-16). Two gaps: in the House the motion
  "may only be moved by a Minister" (S.O. 32(a)), and at the scheduled time the Speaker proposes
  it with no mover at all, in which case the template's "introduced by {{mover_title}}
  {{mover_name}}" has nobody to name and degrades to "a member".

**Template 23 checks out** and is worth recording as verified rather than left to be
re-litigated: Senate Guide No. 2 states "There is no ability to 'gag' a senator (that is, move
that a senator be no longer heard)", which is exactly what the template and the router's
`MEMBER_NO_LONGER_HEARD_CHAMBER_CONFLICT` fence assume.

**Fixed**, each against the passage named above. Template 26 gained a `{{mover_clause}}` that renders
nothing when there is no mover, rather than "introduced by a member", and says what a defeated
adjournment does. Four more were sharpened at the same time, from the same reading:

- **Template 3 and Template 4**: both said the chamber goes through the bill line by line. In
  practice the bill is taken as a whole, in the Senate by practice (Senate Guide No. 16) and in the
  House by leave in most cases (House Guide p. 71).
- **Template 5** did not say why a Federation Chamber bill produces a division in the House at all.
  It now explains the unresolved question (House S.O. 188) and that the report questions are put
  immediately without debate or amendment (S.O. 153).
- **Template 10** described every division reaching it as "an attempted censure motion", which is
  only true of the ones that never got past the suspension. It now reports the censure itself, covers
  no confidence in the government as well as in an individual, and explains S.O. 48 priority.
- **Templates 20, 25, 27 and 28** gained the notice-versus-order-of-the-day distinction
  (S.O.s 110(c), 117(b)), the limits on what can be dissented from (House Guide p. 42), what a take
  note motion is actually for, and why the inverted question protects against a tie leaving an
  unsupported clause in the bill.

---

## Extraction quality

### KI-11

**`declines_second_reading` is left to the model when the guides give a closed list of forms.**
Severity: Medium. Status: **Fixed** by `SemanticExtractor#system_prompt` rule 7 and
`ProvenanceValidator#check_declines_second_reading_against_motion`, covered by the
"declines_second_reading against the motion text" examples in
`spec/services/division_summary_pipeline/provenance_validator_spec.rb`.

Template 2's summary says the opposite thing depending on this flag, and `ProvenanceValidator`
rightly refuses to let the model leave it null. But the decision is more deterministic than the
pipeline treats it. House Guide p. 68-69 lists the standard words substituted into a reasoned
amendment:

- "the bill be withdrawn and redrafted to provide for ..."
- "the bill be withdrawn and a select committee be appointed to inquire into ..."
- "the House declines to give the bill a second reading as it is of the opinion that ..."
- "the House disapproves of the inequitable and disproportionate charges imposed by the bill ..."
- "the House is of the opinion that the bill should not be proceeded with until ..."
- "whilst not opposing the provisions of the bill, the House is of the opinion that ..."
- "whilst not declining to give the bill a second reading, the House is of the opinion that ..."

The last two are explicit negatives, and the third is an explicit positive. The system prompt
currently gives the model one example of each.

**Fixed** as described: the whole list is in the prompt, split into the forms that decline and the
forms that do not, with the two "whilst not ..." traps called out; and the validator fails the
extraction when the flag contradicts the motion text the model itself returned.

### KI-13

**Template 2 describes one of the four things a stage amendment can do.** Severity: Low.
Status: **Partly fixed** in `templates/2_second_reading_amendment.md`.

Senate Guide No. 16 sets out the closed list of what an amendment to the motion for a stage of
a bill may do: express an opinion about the bill or the government's handling of the policy;
reverse the effect of the motion so the bill is defeated at that point; refer the bill to a
committee; or delay further consideration. Template 2's explainer covers only the first.

Two follow-ons worth knowing while working here. A referral can arrive as a second reading
amendment under Senate S.O. 114(3), which means a division that looks like an amendment vote is
really about sending the bill to a committee. And the second reading amendment on the main
appropriation bill is exempt from the relevancy rule and is conventionally cast as a censure of
the Budget (House Guide p. 81-82), so it can carry censure wording without being a censure
motion. The router's ordering happens to handle that correctly today, because the second reading
rules are reached before Template 10 would be, but it is fragile and undocumented.

**Fixed so far**: the explainer now lists all four, so a reader is not told the amendment must be an
opinion motion when it may be a referral or a delay.

**Still open**: extracting which of the four applies, as a constrained enum, so the summary can say
which one this division was about rather than listing the possibilities. That adds a field to
`ExtractionPayload`, a rule to the prompt and a branch to the template, and is worth doing when the
evaluation corpus has enough Template 2 divisions to tell whether the model gets it right.

---

## Structural

### KI-6

**Deferred and successive divisions defeat the context window.** Severity: Medium. Status:
**Fixed** by `ContextBuilder#context_warnings` and `DataLoader::DivisionXml#preceded_by_division?`,
covered by the "context warnings" examples in
`spec/services/division_summary_pipeline/context_builder_spec.rb`.

`DataLoader::DivisionXml#context_speeches` takes the speeches immediately preceding the
`<division>` element in document order. That assumes the debate next to a division is the debate
about it. Two House procedures break the assumption:

- **Deferred divisions** (S.O. 133, House Guide p. 58). On Mondays, divisions called between
  10 am and 12 noon are deferred until after 12 noon; on Tuesdays, divisions called before 2 pm
  are deferred until after the MPI discussion. The Chair then puts all the deferred questions in
  the order they were deferred, "without amendment and without further debate". The speeches next
  to such a division belong to whatever business the chamber had reached by then.
- **Successive divisions** (S.O. 131, House Guide p. 57; the Senate equivalent in Senate Guide
  No. 3). Where divisions follow one another with no intervening debate, only the first has
  debate before it.

This is structurally the same trap as the "Limitation of Debate" heading that Stage 2 exists to
defeat: a positional assumption that is usually right and silently wrong in a knowable set of
cases. Stage 1 has no defence against it today.

**Fixed** as described, by flagging rather than by trying to recover the right debate. `ContextPacket`
gained a `context_warnings` list, which the packet raises when:

- another `<division>` sits between this one and the last heading, which is exactly the successive
  case and is read straight off the XML rather than inferred;
- no speeches were found before the division at all;
- a House division falls in the part of the day when deferred questions are put; or
- no Hansard XML matched and the packet was built from the `Division` record's own motion text.

The warnings go to the extractor in a `<context_warnings>` block, so it can answer
`sufficient_context: false` instead of reading unrelated speeches as the argument for this vote, and
to `ProvenanceValidator`, which records them and marks the draft for human review.

One caveat, stated in the code as well: S.O. 133 fixes when the deferral window opens but not how
long the run of deferred questions takes, so the hour-long windows the check uses are this code's own
estimate rather than anything either guide says. They only raise a warning, so an over-wide window
costs a reviewer a look.

---

## Defects found while fixing the above

These came from reading the code against the same two guides in the same pass, rather than from the
guides directly. They are numbered in sequence with the rest so they can be cited the same way.

### KI-15

**`declines_second_reading` and `sufficient_context` were coerced to true whatever the model
returned.** Severity: High. Status: **Fixed** by `ExtractionPayload.optional_boolean`, covered by
the "boolean fields" examples in
`spec/services/division_summary_pipeline/extraction_payload_spec.rb`.

`ExtractionPayload` normalised both flags with `value.nil? ? nil : !value.nil?`, and `!false.nil?`
is `true`. Every value the model supplied therefore became `true`, and only an omitted field stayed
nil. `from_h` had the same expression twice over.

Two things followed, both silent:

- Template 2's summary says the opposite thing depending on `declines_second_reading`. Every
  extraction that set it at all compiled as though the amendment declined the bill a second reading,
  including the "whilst not declining to give the bill a second reading" form, which is the exact
  case KI-11 is about. The evaluation fixture happens to set it to `true`, so the corpus could not
  catch it.
- `sufficient_context` could never be false, so `DivisionSummarizer`'s progressive context
  expansion never ran. The Level C sitting-day tier that `ARCHITECTURE.md` constraint 4 requires was
  unreachable in practice, and `ProvenanceValidator#check_context_sufficiency` could never fire.

The replacement is three-state: true, false, and "the model did not answer", which are three
different things here. It also accepts the string forms models return often enough to matter
("true", "false", "yes", "no"), and treats anything else as unanswered rather than as true.

**Confirmed** by parsing `{"declines_second_reading": false}` and reading the field back.

### KI-16

**A suspension of standing orders was routed as whatever motion it quoted.** Severity: High.
Status: **Fixed** by reordering `ProceduralRouter`, covered by the "suspension of standing orders is
matched before the motion it would enable" examples in
`spec/services/division_summary_pipeline/procedural_router_spec.rb`.

A suspension question recites the motion it would clear the way for ("That so much of the standing
orders be suspended as would prevent ...", House Guide p. 2), so it contains the trigger words of
whichever rule covers that motion. `ARCHITECTURE.md` and the router's own comment both said the
suspension rule was matched first for exactly that reason. It was not: the closure rule sat above it.

So "That so much of the standing orders be suspended as would prevent the question being now put"
returned Template 22 and was published as a closure of debate. Suspensions moved to let a question be
put forthwith are common, and the censure case the comment describes was only safe because the
censure rule happens to sit below.

The suspension rule is now first in the whole router, which is what both documents already claimed.

**Confirmed** by routing that question before and after the change.

### KI-17

**The compiler's grammar tidying edited quoted Hansard.** Severity: Medium. Status: **Fixed** by
`TemplateCompiler::VERBATIM_PLACEHOLDERS`, covered by the "verbatim quoted text" examples in
`spec/services/division_summary_pipeline/template_compiler_spec.rb`.

`TemplateCompiler#compile` ran its cosmetic passes over the whole rendered document, after the
placeholders had been filled. Those passes collapse runs of spaces, collapse a duplicated "the", and
used to rewrite "a" to "an" before a vowel. The motion text, the mover's claims and any Bills Digest
extract are all in that document, inside blockquotes, and are there precisely because they are
reproduced word for word. A pipeline whose entire claim is mechanical verbatim provenance was
quietly editing the quotations after stage 4 had verified them.

The indefinite-article pass was wrong on its own terms as well: its only exception was "unanimous",
so "a unique opportunity" became "an unique opportunity".

The fix has two halves. Verbatim placeholders are substituted last, behind a token, so no cosmetic
pass can reach them. And the indefinite article is gone from the tidying entirely: `{{amount}}` is
the only value that ever followed a bare "a" in a template, so the templates now use
`{{amount_with_article}}`, which carries the right article chosen from the value.

**Confirmed** by compiling a motion text containing "    " and "the the" and reading it back.

### KI-18

**A tied House division cannot be resolved from the recorded figures.** Severity: Medium.
Status: Open.

`Division#passed?` returns false for a tie. In the Senate that is right: the President has an
ordinary vote and no casting vote, so an equally divided question is lost (Constitution s 23, Senate
Guide No. 3). In the House it is not: the occupant of the Chair has a casting vote under s 40, which
decides the question and is not in the aye and no counts.

The summary used to report a tied House division as "a majority voted against ... which means it was
unsuccessful" and then, in the next paragraph, that the casting vote decided it. Both cannot be true.

Softened rather than solved: a tied division is now reported as "voted on" rather than for or
against, a tied House division as "not decided by the division figures, which were equal", and the
notice says the figures do not record which way the casting vote went. That is honest, but it is
less than a reader wants. Recovering the casting vote means reading the Votes and Proceedings, where
S.O. 135(c) requires the Speaker's reasons to be recorded, and TVFY does not load that.

### KI-19

**Template 21 cites the Parliament Act 1974, which neither guide mentions.** Severity: Low.
Status: **Verify**.

`21_parliamentary_zone_works.md` says works in the Parliamentary Zone "must be formally approved by a
vote in both chambers of parliament" under the Parliament Act 1974. The House guide confirms the
approval requirement exists - the House Appropriations and Administration Committee "considers
proposals for works in the parliamentary precincts that are subject to parliamentary approval"
(p. 117) - but names no Act, and the Senate guides do not cover it. The citation is probably right
and was left alone rather than removed, but it has not been checked against a primary source, which
this register exists to say out loud.

---

## Documentation drift

### KI-14

**`ARCHITECTURE.md` drift.** Severity: Low. Status: **Fixed**.

- Three places still said 27 templates where there are 28: `ARCHITECTURE.md` sections 4
  ("the full 27-template catalogue") and 5 ("one of 27 human-curated Markdown templates"), and
  the comment above the compilation data table in `template_compiler.rb`. Section 4's diagram and
  section 9's file listing both said 28. A fourth was worse than a miscount:
  `ExtractionPayload.json_schema` capped `template_id` at 23 and described it as "1 to 23", so the
  schema the model is handed disagreed with the catalogue in the same prompt.
- Section 4 said the end-of-day "that the House do now adjourn" is "deliberately left
  unmatched". Template 26 matches it.
- Section 4 said Stage 5 "detects turnout below quorum thresholds (fewer than 30 in the House,
  fewer than 19 in the Senate)". The compiler deliberately does not do the Senate, and its own
  comment explains why: the Senate guides set out no rule voiding a Senate division for want of
  a quorum, and an unverifiable citation is not one to publish. The code was right and the
  document was wrong.

**Fixed**, all four, along with the sections describing behaviour this round of work changed.
