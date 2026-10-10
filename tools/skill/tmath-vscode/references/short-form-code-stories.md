# Building short-form stories from code evidence

Read this with [short-form-authoring.md](short-form-authoring.md) and the [algorithm-and-code profile](../../tmath-skills/references/profiles/algorithm-and-code.md) when a repository, symbol, topic, PR, or commit must become a short-form series. This file governs evidence selection, not motion style.

## Establish evidence first

Fix the repository revision and requested scope. For change explanations, record exact base and head. Inspect the selected entry point, callers, callees, state owners, data transformations, failure or cleanup path, and the tests, traces, benchmarks, docs, issues, or review statements that constrain the claim. A diff shows change, not necessarily intent or runtime effect; label inference in the description.

For each candidate episode record:

- the one question or hook;
- verified source anchors and scenario input;
- decisive transition;
- observable output, invariant, cost, or failure;
- supporting test or constraint;
- Related Source order.

Reject filler, repeated claims, unsupported hooks, and topics without a visible causal transition. Prefer one strong episode over an artificial series.

## Route the evidence scope

- Repository: select a reader journey through purpose, entry path, decisive mechanism, ownership, and a meaningful edge path—not a directory tour.
- Selected code: center the exact symbol or range, then follow only the representative dependencies needed to explain it.
- Topic: choose a concrete executable path and disclose when it represents only one implementation.
- PR: compare exact revisions and unchanged context; group by behavior rather than file or hunk order. Separate new behavior, intended-equivalent refactoring, test strengthening, and speculative impact.
- Commit: inspect its parent and split only independently meaningful behavior changes.

## Map proof to an episode

Keep the minimum cast: initiating source token or input, stable structure, actual state transition, and observable proof. Preserve names and causal order across Canvas, title, description, manifest `links`, and Inspector. For concurrency, show overlap and order links by causal handoff without inventing serial execution.

Use the description for revisions, scope, caveats, reproduction inputs, alternate branches, benchmark conditions, and why an anchor matters. The Canvas stays immediate but cannot be less accurate. Every episode's exact final frame must preserve its resolved answer and evidence. Use one exact manifest `series` string, make every episode independently understandable, and omit all tmath Lua from subject evidence and Related Source.
