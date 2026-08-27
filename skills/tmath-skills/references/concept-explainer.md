# Concept explainer

Use this for an ordinary educational animation whose evidence is a changing relation, construction, comparison, or causal mechanism. If one labeled still answers the question, make a still; animate only when time adds proof.

## Direct the explanation

Choose one compact arc: discovery, problem–solution, comparison, or build-up. State the audience, question, likely misconception, and final aha. Then write 3–7 beats before code:

| Beat field | Required decision |
|---|---|
| claim | the one sentence this beat proves |
| source state | canonical values or geometry used |
| focus | one semantic object or relation |
| motion | one dominant change that proves the claim |
| context | what stays, dims, or leaves |
| hold | enough time to read the changed state |
| review time | an exact render time after the motion settles |

The first frame must already pose the question, show the subject, or establish a deliberate visual reference. It must be one coherent state, not labels whose owners are still hidden. Use a blank lead-in only when explicitly designed and reviewed; follow the API reference's entrance-animation rule.

## Make motion truthful

A visual metaphor must preserve the relation it claims to demonstrate. Claimed incidence must share a dependency, not merely use the same formula: a tangent to a contour at `p`, for example, requires the displayed contour level to equal `f(p)`, both objects to pass through `p`, and the tangent direction to be orthogonal to the computed gradient. Apply the analogous checks to projections, equal areas, paths, slopes, and intersections. Mark the regime of every approximation; a finite-step comparison cannot silently stand in for a local directional-derivative proof. An illustrative guide may simplify appearance, but must not be labeled as exact evidence.

Choose motion by intent:

| Intent | Preferred operation |
|---|---|
| establish existence | `create`, `write`, or `fade_in` |
| reveal direction or construction order | `create` |
| preserve identity across compatible sampled geometry | `morph` |
| consume one object into its successor | `replacement_transform` |
| change representation without implying geometric identity | `fade_transform` |
| focus attention without changing state | `indicate` or a temporary `StyleGroup` |
| reveal a sequence | an animation array with deliberate lag |
| prove a spatial relation | camera `look`; otherwise keep the camera quiet |

## Pace and stage

Use these as starting ranges, then tune at normal speed: supporting reveal 0.35–0.7 s; main construction 0.7–1.4 s; conceptual transform 0.9–1.8 s; short reading hold 0.35–0.8 s; equation or key result hold 1.2–2.5 s; final hold 1.5–4 s. A requested duration is not a quota. Without supplied narration timing, any single `wait` over 4 s is a review failure; add a truthful beat or shorten the piece.

Keep one focal action at a time. A useful salience starting point is primary opacity 1, context 0.35–0.6, and construction structure 0.15–0.3. Dimming may suppress attention but must not change semantic identity or color meaning. Prefer geometry over prose; narration may add context but the silent animation must still communicate the core relation.

## Review the movie, not only the result

Apply the scene-contract review matrix to every ledger beat, not only the opening, midpoint, and final frame. Watch once at 1× with sound off, then with requested narration timing. A caption is not a beat unless its visible state already proves the caption.
