# AI division summaries: the model selects, it never writes

The AI in the division summary pipeline may identify, classify and select. It never supplies publication
text. Every published character of a draft is human-written template prose, a database fact, or Hansard's own
text retrieved by code from a reference.

For any fact a summary needs: if the database or a fixed rule already knows it, the model is never asked. If
Hansard contains it but finding it needs understanding, the model points at it and code retrieves it. If
nothing authoritative contains it, it is left out and flagged for the reviewer.

Why: a summary on They Vote For You has to be something nobody can dispute, because it is a member's own
words or the parliament's own record. Checking a model's string against Hansard after the fact still let the
model choose the words, so paraphrase, tidied punctuation, the wrong occurrence of a repeated sentence and
invented labels could all reach a draft. Making the model answer with references instead puts provenance in
the data model rather than in a check.

Consequences:

- The model's reply has two kinds of content, kept apart: semantic decisions (the template, whether a second
  reading amendment declines the bill, which kinds of evidence are missing, from a closed list) and references
  (IDs of transcript units, and a unit plus a short phrase for a named fact). There is no field for a topic, a
  claim, the motion's text or a note, and no legacy title-and-description path.
- Stage 1 finds the motion, the mover's "I move" words and the chair's question by rule. Stage 4 resolves
  every reference into an `Evidence` excerpt of raw Hansard text, and the compiler sees only that.
  Normalised text is used to search, never to publish.
- A draft's title is built by rule from the Hansard heading and the template.
- Every draft ends with a fixed-form Reviewer Only report built from the pipeline's own records, never from
  model prose.

See `app/services/division_summary_pipeline/ARCHITECTURE.md` section 2 for how this shapes each stage.

Decided 2026-09-28, when the pipeline was rebuilt around source references (feature/1716-ai-division-summaries). Drafted with AI assistance (Claude Code, claude-opus-5-5).
