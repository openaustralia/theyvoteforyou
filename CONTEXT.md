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

### Server migration

**Cutover**:
The act of moving one environment (staging or production) from the old server instance to the new one. Each
environment cuts over separately.
_Avoid_: Migration, switchover

**Rehearsal**:
The period when staging runs on a new instance before production cuts over to it, proving the build works. The
rehearsal happens on the permanent new instance, not a throwaway box.
_Avoid_: Dry run, trial box
