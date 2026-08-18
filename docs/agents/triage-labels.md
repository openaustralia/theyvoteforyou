# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in
this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                     |
| -------------------------- | -------------------- | ------------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue     |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information    |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent     |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation               |
| `wontfix`                  | `wontfix`            | Will not be actioned                        |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this
table.

Edit the right-hand column to match whatever vocabulary you actually use.

## Label history

- `wontfix` predates this file and already carried the canonical name.
- `needs-triage` was previously called `needs-categorization`. Renaming preserved the label on the issues that already
  carried it, so historical issues show the new name.
- `needs-info`, `ready-for-agent` and `ready-for-human` were created for this vocabulary and had no prior equivalent.

`openaustralia/.github` defines no org-wide triage vocabulary, so these labels are repo-local.
