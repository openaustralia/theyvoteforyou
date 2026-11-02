# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

This is a **single-context** repo: one `GLOSSARY.md` and one `docs/adr/` at the root, alongside `design_docs/`.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root - the glossary of domain terms.
- **`docs/adr/`** - read ADRs that touch the area you're about to work in.
- **`design_docs/principles.md`**, **`design_docs/design_persona.md`** and **`design_docs/user-questions.md`** - who
  the site is for and how it should behave. Read them before changing anything user-facing.

The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) adds to the glossary
and ADRs as terms and decisions get resolved.

## File structure

```
/
├── GLOSSARY.md         ← glossary
├── docs/adr/           ← one file per decision
├── design_docs/
│   ├── principles.md
│   ├── design_persona.md
│   └── user-questions.md
└── app/
```

If this repo ever grows into separate bounded contexts, the multi-context layout is a root `GLOSSARY-MAP.md` pointing at
one `GLOSSARY.md` per context, with context-scoped ADRs alongside each. Not the case today.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the
term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal - either you're inventing language the project
doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (cached whip tallies over counting `Vote` rows) - but worth reopening because…_
