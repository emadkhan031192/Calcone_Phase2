# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added — Phase 2: Signature UX

- `ExpressionTerm` model and `ExpressionDecomposer`: splits a chained
  addition/subtraction expression into editable Quick Scan cells, with
  correct handling of unary minus, parentheses, and nested `*`/`/`.
  Deliberately disables itself for any expression containing `%`, since
  a context-aware percent depends on everything to its left — decomposing
  it into independent cells would silently produce a wrong total.
- `CalculatorEngine.editTerm` / `deleteTerm`: edit or remove one Quick Scan
  cell and recalculate the total in place (spec §9, acceptance test §45).
- `CalculatorSnapshot` + `CalculatorEngine.snapshot()` / `restore()`: the
  mechanism behind Undo (spec §18), used by Quick Scan delete and by the
  keypad's AC/C buttons.
- `QuickScanSheet`: the swipe-up grid — adaptive `GridView`, automatic
  grouping into fours with subtotals past 8 entries (spec §10), tap/
  long-press → Edit/Delete/Copy/Save action sheet.
- Gestures on the home screen: tap or swipe-left on the result to copy,
  swipe-up to open Quick Scan, swipe-right shows an honest "coming in
  Phase 3" notice rather than a fake share sheet.
- `SessionPersistenceService` (SharedPreferences-backed) and `SessionGate`:
  auto-saves the in-progress calculation after every input and offers
  "Continue previous calculation? / Start New" on the next launch
  (spec §19).
- `SavedNumbersService`: persists values from Quick Scan's "Save" action
  (spec §27); a browsing UI for them is a Phase 4 deliverable.
- `CalculationEntry.toJson()` / `fromJson()`, using numerator/denominator
  strings rather than decimal-string parsing, so a saved session never
  loses precision on a non-terminating value.
- Unit tests for the term decomposer, the new engine methods (edit/
  delete/undo), `CalculationEntry` JSON round-tripping, and session
  save/load/clear.

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
