# Authoring verified code-diff visualizations

Read this for PR, commit, refactor, or other revision-dependent evidence. Read the real repository diff and unchanged context before planning the visualization. Never reconstruct previous or deleted code from the current file, prose, or memory.

## Select fair evidence

Resolve both revisions to full `40`-character commit SHAs. Use a Diff link only when those objects are locally available and the checkout plus current file exactly match the declared head. Compare the same scenario on both sides and identify the first behavioral divergence. Patch file and hunk order are evidence locations, not runtime order; keep manifest links in representative execution or causal order.

Use a concise title for the behavioral claim, not a path, hash, generic before/after label, or changed-file list. Use ordinary Source links for unchanged implementation context and Diff only for revision-dependent claims.

## Manifest contract

A Diff link retains the normal `label`, post-change `source`, and explicit `range`, then adds:

```json
"diff": { "base": "<full SHA>", "head": "<full SHA>", "oldPath": "<optional previous path>" }
```

`range` is one-based, inclusive, and addresses the head/current file. It must cover the smallest coherent current block containing the governing input or condition, decisive operation, and immediate result or handoff. Do not reduce it to a changed line when adjacent code determines meaning.

For a rename, `source` is the current path and `oldPath` is the previous path. For a verified added file, omit `oldPath`; the base commit must resolve, the current path must be absent there, and checked-out content must equal the head blob. The Viewer compares the selected inserted range against an empty previous document. Never use this rule to mask a missing rename path.

For deletion-only evidence, anchor the range to the nearest truthful surviving current line that preserves execution context. Removed rows come only from the base blob. Omit the link when no honest current anchor exists.

## Failure boundary

Keep animation Lua, helper scenes, paths, hashes, and large patches off Canvas and out of `links`. A short verified fragment may orient the scene; the Inspector owns full evidence. If checkout, content, revision, path, rename, or range verification fails, preserve the declaration and show `DIFF UNAVAILABLE`. Never switch revisions, invent blobs, guess code, or silently fall back.
