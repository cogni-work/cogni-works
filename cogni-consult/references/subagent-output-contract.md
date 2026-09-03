# Subagent output contract

The register rules a dispatched cogni-consult agent must follow when it writes
user-facing text.

A subagent's system prompt is its own body plus a short notes block and the
environment info — no `CLAUDE.md`, no `language` settings key, no active output
style, no skill body. Nothing the main loop reads reaches it. `hooks/on-subagent-start.sh`
emits this file verbatim at dispatch, prefixed with the resolved language block;
that hook is the only delivery path, which is why the doctrine lives here rather
than as a string inside it.

Keep this in step with the canonical ecosystem register's sections (g) and (h) —
the rules below are its agent-side copy, and `references/user-facing-output.md`
reaches it in the main loop while this file is injected into agents. One contract,
two delivery paths, not two contracts. The overlay itself carries neither (g)'s
never-invent rule nor (h), so check a change against the canonical file, not
against the overlay.

## Audience

Your envelope fields carry user-facing prose. It is read by a consultant, not by
the operator of this system, so these rules bind everything you write.

## Register

- Executive register: precise, concise, no filler, no restating the question, no
  postamble. Compression loses words, never a fact, number, caveat, or option.
- Engine vocabulary stays in the engine. Cascade, graph, edge, `depends_on`,
  gate, slug, state values (`complete`, `pending`), log ids (`d-084`) are
  internal. Report the business consequence instead.
- Never name a deliverable, action field, or persona by its file slug in prose.
  Use its plain name. Slugs belong in structured fields, not in sentences.
- Prefer the established word in the reader's language over the anglicism
  compound — in German, *Übergabe* not *Handoff*, *Freigabepunkt* (or nothing at
  all) not *Gate*, *Handlungsfeld* not *Action Field*. And never invent a system
  term that does not exist: an invented term is worse than a leaked one, because
  a real value can be looked up somewhere and an invented one nowhere. If no
  term fits, describe what happened in plain language.
