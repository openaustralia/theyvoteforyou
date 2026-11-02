# They Vote For You

Makes Australian parliamentary voting data understandable: who voted for what, and how that compares with stated
policies. This glossary records the canonical terms for concepts that have more than one plausible name.

## Language

### People and how they appear

**Portrait**:
The photograph of an MP or senator shown beside their name, on pages and on cards. Sourced from
openaustralia.org.au but served by this site.
_Avoid_: Face, photo, member image, headshot

**Card**:
The 1200x628 image generated nightly for a policy, person, or comparison, and pointed at by the page's OpenGraph
tags so social media previews show it. A card contains portraits; it is not itself a portrait.
_Avoid_: OG image, social image, share image, screenshot

### Email delivery

**Hard bounce**:
A permanent delivery failure reported for an email: the receiving server refused it, or the address no longer exists.
A refusal that blames our sending server or reputation (an enhanced status code starting 5.7) is not a hard bounce,
because it says nothing about the person's address.
_Avoid_: Bounce (when the kind matters), failure

**Suppression**:
The state of an email address that alert emails are no longer sent to, because of a hard bounce. It belongs to the
address, not to an account or an alert, never expires, and ends only by a deliberate action: the person changes their
address or signs up again and confirms, or staff clear it. It stops alert emails but not mail the person has just
asked for, such as a sign-up confirmation or a password reset.
_Avoid_: Blacklist, blocklist, unsubscribe (an unsubscribe is the person's choice, a suppression is not)

**Complaint**:
A person marking an alert email as spam. Postal reports none, so the only complaint signal we receive is the person
using one-click unsubscribe, which removes every alert subscription at that address.
_Avoid_: Spam report

### Server migration

**Cutover**:
The act of moving one environment (staging or production) from the old server instance to the new one. Each
environment cuts over separately.
_Avoid_: Migration, switchover

**Rehearsal**:
The period when staging runs on a new instance before production cuts over to it, proving the build works. The
rehearsal happens on the permanent new instance, not a throwaway box.
_Avoid_: Dry run, trial box
