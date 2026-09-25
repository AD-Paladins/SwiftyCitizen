#!/usr/bin/env python3
"""Generador correcto de Localizable.xcstrings para SwiftyCitizen.

Reconstruye el catálogo desde cero con el formato EXACTO que espera Xcode:

    "key": {
      "localizations": {
        "en": { "stringUnit": { "state": "new", "value": "English text" } }
      }
    }

Las plurales se resuelven en Swift (el SDK no tiene API de plurales), así que
cada concepto plural son dos claves simples: <key>Singular / <key>Plural.
"""
import json

CATALOG = "SwiftyCitizen/Localizable.xcstrings"

SIMPLE = {
    # --- App tabs (App/AppTab.swift) ---
    "app.tab.home": "Home",
    "app.tab.study": "Study",
    "app.tab.practice": "Practice",
    "app.tab.progress": "Progress",

    # --- Welcome (App/ContentView.swift) ---
    "welcome.navTitle": "Welcome",
    "welcome.title": "Welcome to SwiftyCitizen",
    "welcome.subtitle": "Build confidence with an offline study aid for the USCIS civics test.",
    "welcome.disclaimer": "SwiftyCitizen is for study support only. It does not determine immigration eligibility or replace official USCIS guidance.",
    "welcome.setUpButton": "Set up your test",

    # --- Home (Features/Home/HomeDashboardView.swift) ---
    "home.greeting.morning": "Good morning",
    "home.greeting.afternoon": "Good afternoon",
    "home.greeting.evening": "Good evening",
    "home.title": "Home",
    "home.continue.title": "Continue studying",
    "home.continue.subtitle": "Review your current set and keep your streak going.",
    "home.continue.cta": "Start review",
    "home.milestone.title": "Daily Milestone",
    "home.milestone.cta": "Continue Daily Review",
    "home.readiness.label": "Exam Readiness",
    "home.readiness.fallback": "Start a review session to build coverage",
    "home.streak.label": "Streak",
    "home.metric.reviewed": "Reviewed",
    "home.metric.gotit": "Got it",
    "home.mastery.title": "Mastery",
    "home.mastery.mastered": "Mastered",
    "home.mastery.due": "Due",
    "home.mastery.unseen": "Unseen",
    "home.today.title": "Today",
    "home.today.empty.title": "No sessions yet",
    "home.today.empty.message": "Start a review session to begin tracking today's progress.",
    "home.duenext.title": "Due next",
    "home.duenext.empty.caughtup.title": "All caught up",
    "home.duenext.empty.caughtup.message": "You have reviewed every question in your test set.",
    "home.duenext.empty.none.title": "Nothing due yet",
    "home.duenext.empty.none.message": "Due questions appear here once you have review history.",
    "home.duenext.card.hint": "Opens the Study tab",

    # --- Study (Features/Study/StudyView.swift) ---
    "study.title": "Study",
    "study.headerSubtitle": "Pick a mode to start reviewing.",
    "study.flashcardsEntryTitle": "Flashcards",
    "study.flashcardsEntrySubtitle": "Study the full version bank, one card at a time.",
    "study.flashcardsEntryAction": "Start",
    "study.targetedReviewEntryTitle": "Targeted Review",
    "study.targetedReviewEntrySubtitle": "Drill the questions you are still working on.",
    "study.targetedReviewEntryAction": "Review",
    "study.contentUnavailable": "Content unavailable",
    "study.contentUnavailableMessage": "The question bank for your selected test version could not be loaded. Try updating the app or choosing another test version in Settings.",

    # --- Flashcard (Features/Study/FlashcardSessionView.swift) ---
    "study.flashcard.closeSession": "Close session",
    "study.flashcard.progressPrefix": "Progress ",
    "study.flashcard.questionPrefix": "Question ",
    "study.flashcard.answerDependsNotice": "Answer depends on where you live. Local officials accept any correct answer for your state.",
    "study.flashcard.howWellDidYouKnowIt": "How well did you know it?",
    "study.flashcard.iAnsweredPrefix": "I answered ",
    "study.flashcard.officialAnswer": "Official answer",
    "study.flashcard.acceptedNotice": "Accepted: your answer covers one accepted version of the official answer.",
    "study.flashcard.source": "Source",
    "study.flashcard.sourcePrefix": "Source ",
    "study.flashcard.yourAnswer": "Your answer",
    "study.flashcard.nothingToReview": "Nothing to review",
    "study.flashcard.nothingToReviewMessage": "There are no questions in this review set. Try a different scope or test version.",
    "study.flashcard.endSessionConfirm": "End this session?",
    "study.flashcard.endSession": "End session",
    "study.flashcard.keepStudying": "Keep studying",
    "study.flashcard.revealAnswer": "Reveal answer",
    "study.flashcard.typeReply": "Type your reply…",
    "study.flashcard.providePrefix": "Provide ",
    "study.flashcard.answersShownSuffix": " the answers shown.",
    "study.summary.done": "Done",
    "study.targeted.countOpen": "(",
    "study.targeted.countClose": ")",

    # --- Targeted (Features/Study/TargetedReviewView.swift) ---
    "study.targeted.inProgressSection": "In progress",
    "study.targeted.byCategorySection": "By category",
    "study.targeted.showCategories": "Show categories",
    "study.targeted.reviewScopeHeader": "Review scope",
    "study.targeted.noQuestionsInScope": "No questions in this scope yet. As you study, questions move into this review list.",
    "study.targeted.title": "Targeted review",
    "study.targeted.resumeSession": "Resume session",

    # --- Summary (Features/Study/SessionSummaryView.swift) ---
    "study.summary.complete": "Session complete",
    "study.summary.reviewedPrefix": "You reviewed ",
    "study.summary.reviewedSingular": "question.",
    "study.summary.reviewedPlural": "questions.",

    # --- MockTestResult (Features/Practice/MockTestResultView.swift) ---
    "mocktest.result.passingScoreLabel": "Passing score: ",
    "mocktest.result.reviewMissed": "Review missed questions",
    "mocktest.result.incorrectSingular": "question was answered incorrectly.",
    "mocktest.result.incorrectPlural": "questions were answered incorrectly.",
    "mocktest.result.skippedDuringTest": "Skipped during the test",
    "mocktest.result.deferredPrefix": "You deferred ",
    "mocktest.result.deferredSingular": "question. Review them here.",
    "mocktest.result.deferredPlural": "questions. Review them here.",
    "mocktest.result.disclaimer": (
        "This simulation follows the official civics test rules but the app is a "
        "study aid, not an immigration authority. An officer's evaluation always "
        "decides the real interview."
    ),
    "mocktest.result.correctAdjective": "correct",
    "mocktest.result.correctLabel": "Correct",
    "mocktest.result.incorrectLabel": "Incorrect",
    "mocktest.result.reviewInTargeted": "Review in targeted review",
    "mocktest.result.reviewSkipped": "Review skipped questions",
    "mocktest.result.done": "Done",
    "mocktest.result.passed": "Passed",
    "mocktest.result.notPassed": "Not passed",

    # --- MockTestSession (Features/Practice/MockTestSessionView.swift) ---
    "mocktest.session.contentUnavailable": "Content unavailable",
    "mocktest.session.contentUnavailableMessagePrefix": "The question bank for ",
    "mocktest.session.contentUnavailableMessageSuffixEmpty": " is empty. Try updating the app or choosing another test version in Settings.",
    "mocktest.session.contentUnavailableMessageSuffixLoadFailed": " could not be loaded. Try updating the app or choosing another test version in Settings.",
    "mocktest.session.typeAnswer": "Type your answer",
    "mocktest.session.seeResults": "See results",
    "mocktest.session.next": "Next",
    "mocktest.session.recordAnswer": "Record answer",
    "mocktest.session.title": "Mock test",
    "mocktest.session.endTestConfirm": "End this test?",
    "mocktest.session.endTest": "End test",
    "mocktest.session.keepGoing": "Keep going",
    "mocktest.session.hideOfficialAnswer": "Hide official answer",
    "mocktest.session.showOfficialAnswer": "Show official answer",
    "mocktest.session.skipQuestion": "Skip this question",

    # --- MockTestSetup (Features/Practice/MockTestSetupView.swift) ---
    "mocktest.setup.rulesSection": "Rules for this session",
    "mocktest.setup.answerInstructions": "Type or speak your answer. The app compares it against the official answers for each question.",
    "mocktest.setup.howYouAnswerSection": "How you answer",
    "mocktest.setup.startMockTest": "Start mock test",

    # --- Practice (Features/Practice/PracticeView.swift) ---
    "practice.title": "Practice",
    "practice.mockTest": "Mock test",
    "practice.oralPracticeTitle": "Oral practice",
    "practice.oralPracticeMessage": "Practice answering aloud without exam pressure. Planned for a later phase.",

    # --- Progress (Features/Progress/ProgressTabView.swift) ---
    "progress.title": "Progress",
    "progress.noProgressTitle": "No progress yet",
    "progress.noProgressMessage": "Your attempts, accuracy, and coverage will appear here after your first study session.",

    # --- Settings (Features/Settings/SettingsView.swift) ---
    "settings.title": "Settings",
    "settings.appearance": "Appearance",
    "settings.theme": "Theme",
    "settings.testConfiguration": "Test configuration",
    "settings.editTestConfiguration": "Edit test configuration",
    "settings.testVersion": "Test version",
    "settings.filingDate": "Filing date",
    "settings.studyLanguage": "Study language",
    "settings.specialConsideration": "Special consideration",
    "settings.specialConsiderationValue": "Age 65+, residency 20+ years",
    "settings.privacy": "Privacy",
    "settings.resetLocalProgress": "Reset local progress",
    "common.notSet": "Not set",
    "selection.selected": ", selected",

    # --- TestConfiguration (Features/Configuration/TestConfigurationView.swift) ---
    "config.titleNew": "Test Configuration",
    "config.titleEdit": "Edit Configuration",
    "config.filingDateSection": "Filing date",
    "config.n400FilingDateLabel": "N-400 filing date",
    "config.testVersionSection": "Test version",
    "config.sixtyTwentyToggle": "I qualify for the 65/20 special consideration",
    "config.selectedVersion": "Selected version",
    "config.studyOptionsSection": "Study options",
    "config.shuffleQuestions": "Shuffle questions when studying",
    "config.studyLanguageSection": "Study language",
    "config.studySupportLabel": "Study support",
    "config.chooseALanguage": "Choose a language",
    "config.yourStudySet": "Your study set",
    "config.questionBank": "Question bank",
    "config.questionBankValueSingular": "question",
    "config.questionBankValuePlural": "questions",
    "config.questionsAsked": "Questions asked",
    "config.questionsAskedPrefix": "Up to ",
    "config.passingScore": "Passing score",
    "config.passingScoreValueSuffix": "correct",
    "config.metricQuestions": "Questions",
    "config.metricAsked": "Asked",
    "config.metricToPass": "To pass",
    "config.testConfigurationFallback": "Test configuration",
    "config.disclaimerToggle": "I understand this is a study aid, not legal advice",
    "config.save": "Save",
    "config.filingDateNote": "This selects the applicable civics test rules unless you choose the 65/20 option.",
    "config.missingFilingDate": "Choose a filing date to continue.",
    "config.filingDateInFuture": "The filing date can't be in the future.",
    "config.missingTestVersion": "Select a test version to continue.",
    "config.missingStudyLanguage": "Choose a study support language.",
    "config.disclaimerNotAccepted": "Accept the study aid notice to save your configuration.",
    "config.incompleteConfigPrefix": "Incomplete configuration: ",
    "config.versionMismatchPrefix": "The selected version (",
    "config.versionMismatchSuffix": ") doesn't match your filing date (",
    "config.versionMismatchEnd": ")",
}

# FrAGMENTOS para componer cadenas dinámicas (el SDK no tiene formato/plurales).
FRAGMENTS = {
    "common.of": "of",
    "unit.questionSingular": "question",
    "unit.questionPlural": "questions",
    "unit.questionsCoveredSingular": "question covered",
    "unit.questionsCoveredPlural": "questions covered",
    "study.targeted.startReviewPrefix": "Start review (",
    "study.targeted.startReviewSuffix": ")",
}


def make_entry(value):
    """Entrada xcstrings en el formato EXACTO que espera Xcode."""
    return {
        "localizations": {
            "en": {
                "stringUnit": {"state": "new", "value": value}
            }
        }
    }


def build_catalog():
    strings = {}
    for key, value in SIMPLE.items():
        strings[key] = make_entry(value)
    for key, value in FRAGMENTS.items():
        strings[key] = make_entry(value)
    return {"sourceLanguage": "en", "version": "1.0", "strings": strings}


def main():
    catalog = build_catalog()
    with open(CATALOG, "w", encoding="utf-8") as fh:
        json.dump(catalog, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    print(f"Wrote {len(catalog['strings'])} keys to {CATALOG}")


if __name__ == "__main__":
    main()
