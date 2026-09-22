# Delta Spec — Study by Category

## Purpose

Topic-based category filtering layered on Targeted Review deck-building. Reuses existing `QuestionContent.topic`. No new content model or persistence; selection is ephemeral.

## ADDED Requirements

### Requirement: category-filter

The system SHALL filter a scope-filtered targeted-review deck to questions whose `topic` is in the selected category set. An empty selection applies no category filter.

| Scenario | Given | When | Then |
|---|---|---|---|
| Select one topic | Deck spans multiple topics | User selects a single topic pill | Deck = all questions of that topic only |
| Multi-select unions | Deck spans multiple topics | User selects several pills | Deck = union of all selected topics' questions |
| Deselect removes | Deck = union of two topics | User deselects one pill | Deck = remaining selected topic's questions |
| Empty selection | Any deck | User deselects all pills | Deck is empty |
| Composes with scope | Scope = Unanswered | Select a topic | Deck = Unanswered questions of that topic only |
| Order preserved | Bank order varies | Select a topic | Deck questions appear in bank order |

### Requirement: category-summary

The system SHALL return, from the scope-filtered deck, the sorted topics present and their per-category counts (counts reflect the scope filter).

| Scenario | Given | When | Then |
|---|---|---|---|
| Summary from scope-filtered deck | Scope = Due, 3 topics present | Request summary | Sorted topics + count per topic; counts match scope-filtered deck |

## MODIFIED Requirements

### Requirement: targeted-review mode

The system SHALL expose an all-questions / by-category mode on Targeted Review, layered on the chosen scope. Selection is ephemeral and NOT persisted across sessions. The user MAY select multiple categories.

| Scenario | Given | When | Then |
|---|---|---|---|
| Toggle to by-category | Mode = all questions | User toggles to by-category | Pills list every topic with its count; deck becomes category-filtered |
| Toggle back to all | Mode = by-category, some selected | User toggles to all-questions | Deck = full scope-filtered deck, no category filter |
| Ephemeral selection | User selects categories | Restart session | Selection empty (not restored); mode defaults to all-questions |

(Previously: Targeted Review built a deck from the chosen scope only, with no category concept.)

### Requirement: pill display

The system SHALL surface every topic in the scope-filtered deck as a selectable pill labeled with its per-category count (e.g. "System of Government (47)"). Selecting a pill toggles that topic's inclusion; multiple pills may be selected at once.

| Scenario | Given | When | Then |
|---|---|---|---|
| Pill label shows count | Deck scope-filtered | View pills | Each pill shows topic name and its count |

(Previously: Targeted Review showed no category pills.)

### Requirement: empty deck state

The system SHALL reuse the existing "Nothing to review" state when the category-filtered deck is empty, and gate the start button on a count greater than zero.

| Scenario | Given | When | Then |
|---|---|---|---|
| All deselected | Multiple topics selected | Deselect all | Deck empty; "Nothing to review" shown; start disabled |

(Previously: Empty deck arose only from an empty scope.)

## MODIFIED Requirements — deck-building

### Requirement: build with categories

The `build`/`questionCount` operations SHALL accept an optional category set applied after scope filtering. When the set is empty, no category filtering occurs.

| Scenario | Given | When | Then |
|---|---|---|---|
| Categories provided | Scope-filtered deck | `build` with non-empty set | Result = scope-filtered questions whose topic is selected |
| Empty categories | Scope-filtered deck | `build` with empty set | Result = full scope-filtered deck (unchanged) |

(Previously: `build`/`questionCount` accepted no category set.)
