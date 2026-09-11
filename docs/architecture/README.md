# SwiftyCitizen Architecture Docs

Library of implementation-oriented documents that explain *how the app works today*: screen flows, data flow, persistence, content pipeline, and dependency rules. These are meant to be the fastest way for both AI agents and people to understand the code without reconstructing it from source.

## Reading order

| Audience | Start with | Then |
| --- | --- | --- |
| New to the app | `app-overview.md` | `flow-flashcards.md` → `flow-mock-test.md` |
| Changing an existing flow | `flow-*.md` for that flow | `data-and-persistence.md` |
| Changing models or persistence | `data-and-persistence.md` | `dependencies.md` |
| Changing content/validation | `content-pipeline.md` | `data-and-persistence.md` |

## The documents

| Document | Covers |
| --- | --- |
| `app-overview.md` | Entry point, tab root, layer boundaries, how a screen builds a session |
| `flow-flashcards.md` | Flashcards and targeted review: scopes, deck building, resume, self-assessment |
| `flow-mock-test.md` | Mock test: setup, questions, manual answers, early pass/fail, result, missed-questions review |
| `flow-targeted-review.md` | Targeted review entry: scopes, counts, resume row | 
| `data-and-persistence.md` | SwiftData schema, models, migration policy, session/attempt lifecycle |
| `content-pipeline.md` | Bundled JSON banks, loader, validation, derived 65/20 set |
| `dependencies.md` | File-level dependency map and layer rules |

## How to keep this library honest

- **Same work unit**: any task that changes behavior in a covered area must update the matching document in the same commit/slice the code lands in.
- **Flows evolve**: when a flow gains a screen, a decision point, or a persistence step, update its `flow-*.md` and the data-flow section first, then the code.
- **Regressions in rules**: a change that breaks a triangle/dependency arrow in `dependencies.md` is a design-review trigger, not a documentation update.
- **Cycle of truth**: `docs/plan/*` is *intent* (what to build and rules); `docs/architecture/*` is *implementation* (what exists and why). Keep them in sync but do not merge them.