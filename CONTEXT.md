# They Vote For You

Makes Australian parliamentary voting data understandable: who voted for what, and how that compares with stated
policies. This glossary records the canonical terms for concepts that have more than one plausible name.

## Language

### Server migration

**Cutover**:
The act of moving one environment (staging or production) from the old server instance to the new one. Each
environment cuts over separately.
_Avoid_: Migration, switchover

**Rehearsal**:
The period when staging runs on a new instance before production cuts over to it, proving the build works. The
rehearsal happens on the permanent new instance, not a throwaway box.
_Avoid_: Dry run, trial box
