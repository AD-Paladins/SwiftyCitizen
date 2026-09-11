# USCIS Civics Test Rules

Last verified: September 10, 2026

This document records the test rules that drive SwiftyCitizen's question selection and scoring. It is intentionally separate from UI and implementation details.

## Test Version Selection

The applicable test depends on the date the applicant filed Form N-400:

| N-400 filing date | Test version | Question bank | Questions asked | Passing requirement |
| --- | --- | ---: | ---: | ---: |
| Before October 20, 2025 | 2008 civics test | 100 | Up to 10 | 6 correct |
| October 20, 2025 or later | 2025 civics test | 128 | Up to 20 | 12 correct |

The app should store the selected test version explicitly. It should not silently infer a version from the current date because the filing date controls eligibility.

## Interview Format

The civics portion is an oral interview. The officer asks questions aloud and the applicant answers aloud. Therefore:

- The official simulation should be oral-style by default.
- Multiple-choice exercises may exist as a separate learning mode.
- A generated paraphrase must never replace the official question in the exam simulator.
- A transcript is evidence of what was recognized, not an authoritative immigration decision.

## 65/20 Special Consideration

An applicant who qualifies for the 65/20 special consideration studies a designated set of 20 questions. The officer asks up to 10 of those questions, and the applicant must answer 6 correctly.

The app should model this as a separate test configuration rather than a UI toggle layered onto the standard 2008 or 2025 bank. Eligibility is user-provided and should be clearly explained as a study configuration, not legal advice.

## Content That Can Change

Some answers depend on current information, such as the President, Vice President, state governor, or a state-specific representative. The content model must therefore support:

- A verification date.
- A source URL.
- A jurisdiction or location requirement.
- Multiple valid answer variants.
- Reverification without changing the stable question identifier.

The app should show a content-update notice when a current answer may need review.

## Implementation Rules

- `TestConfiguration` owns question count and passing score.
- `ExamEngine` receives a configuration and never hardcodes a single exam format.
- `QuestionBank` owns official questions and answers.
- `AnswerEvaluator` handles answer cardinality and curated variants.
- AI output cannot be used as official content or as the sole scoring authority.
- Unit tests must cover both test versions and the 65/20 configuration.

## Source

- [USCIS 2008 Civics Questions and Answers (100 questions)](https://www.uscis.gov/sites/default/files/document/questions-and-answers/100q.pdf) (rev. 01/19)
- [USCIS Civics Questions for the 65/20 Exemption](https://www.uscis.gov/sites/default/files/document/questions-and-answers/65-20q.pdf) (rev. 01/19)
- [USCIS 2025 Civics Test: 128 Questions and Answers](https://www.uscis.gov/sites/default/files/document/questions-and-answers/2025-Civics-Test-128-Questions-and-Answers.pdf)
- [USCIS Citizenship Resource Center](https://www.uscis.gov/citizenship)

The bundled resources were verified on September 10, 2026. The 2008 and 2025 JSON files contain the numbered USCIS questions and answer bullets. The 65/20 JSON file contains only the 20 stable IDs designated by the official 65/20 PDF and derives its text from the 2008 bank; it does not duplicate question text. The 2025 PDF also marks a 20-question special-consideration set, but this app's `65/20` configuration follows the separately published 2008-era 65/20 material and must not silently substitute the 2025 asterisk set.

## Content Update Procedure

1. Download the current USCIS source PDFs from the links above and record the document revision or publication marker.
2. Compare question numbering, official wording, answer bullets, special-set membership, and current or jurisdiction-dependent answers against the previous JSON resources.
3. Preserve stable IDs for unchanged questions. Add a new source revision and verification date to changed records and the bank manifest.
4. Run the loader tests and validate all three banks against their `TestConfiguration` counts before shipping.
5. Review current answers against the USCIS test-updates page before release; do not replace a dynamic answer with an app-generated value.

The JSON resources intentionally do not claim that a dynamic answer is permanently correct. `isJurisdictionDependent` identifies answers requiring current-official or location-specific review, while `verificationDate` records when the bundled source was checked.
