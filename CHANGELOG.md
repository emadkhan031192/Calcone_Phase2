# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed — Phase 1 issues
- Continuing from a result keeps exact precision: results are seeded back
  as lossless expression text instead of display-formatted strings, so
  `1/3 = × 3 =` gives `1` (spec §32).
- Long-press `=` repeats with the original operand text, so
  `500+10% =` repeats to `605` (spec §17); it only repeats immediately
  after an evaluation, so a half-typed expression is never clobbered, and
  falls back to a normal evaluation when there is nothing to repeat.
- Live result preview while typing (as the code already promised).
- Smart parenthesis key: one tap inserts `(` or `)` by context; the
  hidden long-press for `)` is gone.
- Backspace after `=` restores the exact result for editing instead of
  wiping it.
- Tests for long-press repeat (including the smart-percent case),
  precision continuation, smart paren, backspace-edit, and the preview
  helper.
- Removed unused dependencies (`intl`, `path`, `cupertino_icons`,
  `sqflite`); kept `share_plus` and `shared_preferences`.
- CI now fails on unformatted code (`dart format --set-exit-if-changed`)
  instead of silently reformatting; Android launcher label set to
  "Calcone"; app renamed to the user's "Calcone" spelling.

### Added — Phase 2: Signature UX
- `QuickScanSheet`: swipe up from the peek handle (or tap it) to see the
  session tape as an adaptive grid with a running total; past 12 entries
  it groups into labelled fours with subtotals (spec §8–§11).
- Tap a value for Edit / Delete / Copy; long-press for a tiny menu
  (Edit / Delete / Copy / Save). Editing re-evaluates the entry and the
  total updates automatically (spec §9). The tape stores raw expressions
  so edits re-parse exactly.
- Gestures (spec §17): tap result to copy, long-press for Copy / Share /
  Save / Show Steps, swipe left to copy, swipe right to share; swipes
  yield to scrolling when the result overflows.
- `StepExplainer`: real step-by-step breakdowns derived from the AST
  evaluation order (spec §25); hidden when not safely explainable.
- Undo (spec §18): delete, edit, and clear actions post an undo request;
  a small snackbar with Undo, no permanent chrome.
- `SessionService` (shared_preferences, on-device only): the tape and
  in-progress expression auto-save (debounced); relaunching offers
  "Continue previous calculation?" (spec §19). Saved numbers (spec §27)
  with a browsing dialog in Quick Scan.
- Widget tests walking the spec §45 acceptance flow (evaluate → Quick
  Scan → edit 450→540 → total updates → share sheet; session restore
  after restart).

### Added — Phase 3: Sharing
- `SharePayload` / `ShareCard` / share sheet (spec §12–§14): a clean
  calculation card (no keypad) shared as an image or text through
  Android's native share sheet; whole-calculation sharing with total
  from the Quick Scan header. Image capture falls back to text so
  sharing never dead-ends.

### Added — Phase 1: Foundation

- Project scaffold with clean, modular architecture (`core/`, `models/`,
  `engines/`, `features/`, `widgets/`).
- Precision-safe expression engine: tokenizer, recursive-descent parser,
  AST, and `ExpressionEvaluator`, built on exact `Rational` arithmetic.
- Smart, context-aware percentage handling (`500 + 10%` vs `500 × 10%`).
- Standalone `PercentageEngine` for non-inline percentage math (discount,
  markup, margin, percent change) for later reuse by the Finance module.
- `NumberFormatter`: thousands separators and trailing-zero trimming
  without ever converting through `double`.
- `CalculatorEngine`: input handling (digit/operator/decimal/percent/
  parens), backspace, clear/clear-all, evaluation, session tape, and
  long-press-equals "repeat last operation".
- Material 3 light/dark/system theme.
- Basic calculator screen: expression + result display, peek handle
  (visual placeholder for Phase 2's Quick Scan), and the four-row keypad.
- Unit tests for the expression evaluator, calculator engine, percentage
  engine, and number formatter, covering the arithmetic/percentage/
  decimal-precision/error-handling scenarios from the product spec.
