# Content Pipeline

Versioned, validated, offline USCIS question banks. The app never treats official content as generated AI output; SwiftData references it by stable ID.

## Source of truth

Bundled JSON in `SwiftyCitizen/Resources/QuestionBanks/`:

| File | Version | Bank size | Source |
| --- | --- | --- | --- |
| `uscis-2008.json` | 2008 | 100 | Official 2008 civics test |
| `uscis-2025.json` | 2025 | 128 | Official 2025 civics test |
| `uscis-65-20.json` | 65/20 | 20 | *Derived* from the 2008 bank via a manifest |

## Loader and validation

`QuestionBankLoader.load(version:)`:

1. Resolves the resource (`QuestionBankResource`, schema version 1).
2. Decodes `QuestionRecord`s with ISO-8601 dates.
3. If the resource is a derived set, loads the source bank and filters by `questionIDs`, applying `isSixtyFiveTwentyQuestion = true`.
4. Validates with `QuestionContentValidator` against the matching `TestConfiguration` — wrong count, duplicate IDs, bad cardinality, or missing source metadata fails the load.

Failures surface as `QuestionBankLoaderError` (validation details in the failure's errors). Screens treat failures as an explicit "Content unavailable" state instead of a silently-empty deck.

## Question content

`QuestionContent` fields: stable ID, version, official text, accepted answer variants, `answerCardinality` (1 or 2), topic, source URL/revision/verification date, jurisdiction flag, 65/20 flag.

Cardinality is meaningful for both display ("Provide 2 of the answers shown") and evaluation (`AnswerEvaluator`).

## Configuration mapping

`TestConfiguration` bundles version, bank count, max questions asked, passing score, and applicability:

| Version | Bank | Asked | Passing |
| --- | --- | --- | --- |
| 2008 | 100 | 10 | 6 |
| 2025 | 128 | 20 | 12 |
| 65/20 | 20 | 10 | 6 |

`OnboardingConfiguration` derives the version from filing date (`2025-10-20` boundary) unless 65/20 eligibility is set, and validates that the selected version matches the derivation.

## Known content corrections

- 2008-088, 2025-028, 2025-037 previously declared `answerCardinality = 2` while the official question asks for one; fixed to 1 (the banks still validate).
- 2008-020, 2008-023, 2008-043, 2008-044 had empty variants; now use the official "Answers will vary." wording mirrored from the 2025 bank. Until a jurisdiction-aware answer path exists, these are placeholders.

## Checklist

- [ ] Any new JSON bank ships with the matching `TestConfiguration` counts.
- [ ] Loader validates before returning questions; screens handle absence explicitly.
- [ ] Content changes beyond formatting require a source revision bump and review.
- [ ] Derived sets (65/20) are manifests over a source bank, not duplicated content.