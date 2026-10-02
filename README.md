# CalcOne

**Simple outside. Genius inside.**

CalcOne looks like an ordinary mobile calculator — until you swipe, tap,
and hold your way into the features you didn't know you needed. No
cluttered scientific keypad, no permanent history panel, no dashboard.
Just a calm, minimal calculator with carefully hidden power underneath.

> **Status: Phase 2 — Signature UX.** Phase 1's foundation (precision
> engine, Basic calculator screen) plus Phase 2's Quick Scan, gestures,
> Undo, and session auto-save are implemented and unit-tested. Sharing
> (Phase 3) and the scientific/advanced math modules are scaffolded as
> empty feature folders per the architecture below — see
> [Roadmap](#roadmap).

## Screenshots

<!-- placeholder — add screenshots once the app is running on a device -->

| Home | Quick Scan |
|------|------------|
| _screenshot pending_ | _screenshot pending_ |

## Features

**Phase 1 — Foundation**

- Clean, four-row keypad — digits, `+ − × ÷`, a context-aware `%`, decimal
  point, and equals. A slim utility row (`AC`, `C`, `⌫`, parentheses) sits
  above it.
- **Smart percentage engine**: `500 + 10% = 550`, `500 − 10% = 450`,
  `500 × 10% = 50` — the same `%` key means different things depending on
  the surrounding operator, exactly like a person would expect.
- **Exact precision arithmetic**: internal math runs on exact fractions
  (`package:rational`), not `double`, so `0.1 + 0.2` displays as `0.3`,
  never `0.30000000000000004`. Formatting (thousands separators, trimmed
  trailing zeros) never mutates the underlying exact value.
- Friendly error handling — division by zero, malformed expressions, and
  unmatched parentheses show a plain-language message, never a crash or a
  stack trace.
- Long-press `=` repeats the last operation on the new result.
- Material 3 light/dark/system theming.

**Phase 2 — Signature UX**

- **Quick Scan**: swipe up from the peek handle (or tap it) to see every
  number in the current calculation as an adaptive grid. Tap or hold a
  cell for Edit / Delete / Copy / Save. Editing a value recalculates the
  total immediately — no re-typing. Past 8 entries, cells group into
  labelled fours with subtotals. Not offered for a calculation containing
  `%`, since a context-aware percent can't be decomposed into independent
  cells without risking a wrong total.
- **Gestures**: tap or swipe-left the result to copy it; swipe up for
  Quick Scan; swipe-right currently shows an honest "coming in Phase 3"
  notice rather than a half-built share sheet.
- **Undo**: AC, C, and Quick Scan's delete all show an "Undo" snackbar
  backed by a full state snapshot — nothing destructive is silent.
- **Session auto-save**: the in-progress calculation is saved to disk
  after every keystroke; relaunching the app offers "Continue previous
  calculation? / Start New."
- **Saved Numbers**: Quick Scan's "Save" persists a value to disk now; a
  screen for browsing them back arrives in Phase 4.

## Architecture

```
lib/
├── core/            # theme, constants, formatting, error types — no UI, no state
├── models/          # plain data classes (CalculationEntry, …)
├── services/        # persistence & platform services (Phase 2+)
├── engines/         # pure calculation logic, framework-agnostic
│   ├── expression/  # tokenizer → parser → AST → ExpressionEvaluator
│   ├── percentage/  # standalone percentage math (reused by Finance later)
│   ├── calculator/  # CalculatorEngine: input handling + session tape
│   ├── conversion/  # unit converter engine (Phase 4)
│   └── mathematics/ # shared math helpers for advanced modules (Phase 6)
├── features/
│   ├── basic/       # ✅ implemented — the home screen
│   ├── quick_scan/  # ✅ implemented — the swipe-up grid (Phase 2)
│   ├── scientific/  # Phase 5
│   ├── history/  sharing/  converter/  finance/                    (Phase 3–4)
│   └── geometry/ statistics/ algebra/ graphing/ calculus/ matrix/  (Phase 6)
│       complex/ programmer/
└── widgets/         # shared, reusable UI (CalcButton, …)
```

The calculation engine is intentionally plain Dart with zero Flutter
imports (`lib/engines/**`) so it can be unit-tested without a widget tree
and reused if CalcOne ever grows a second front end.

### Why `Rational`, not `double` or raw `Decimal`?

`double` is binary floating point and cannot represent `0.1` exactly —
that's the entire "`0.1 + 0.2 = 0.30000000000000004`" problem. `Decimal`
alone isn't enough either, because it isn't closed under division: `1/3`
has no terminating decimal expansion. CalcOne's AST evaluates everything
as an exact [`Rational`](https://pub.dev/packages/rational) and only
converts to a fixed-scale `Decimal` at the very last step — display
formatting — via [`NumberFormatter`](lib/core/utils/number_formatter.dart).
The value stored back into the calculation tape is always the untouched,
exact `Rational`.

## Setup

Requirements:

- Flutter ≥ 3.19, Dart ≥ 3.3 (see `pubspec.yaml` → `environment`)
- Android SDK for building/running on Android

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
```

Current coverage (`test/`):

- `engines/expression_evaluator_test.dart` — arithmetic, operator
  precedence, the smart percentage engine, decimal-precision edge cases
  (`0.1 + 0.2`, `1/3 * 3`), negative numbers, and error handling.
- `engines/calculator_engine_test.dart` — keypad input handling
  (operator replacement, single decimal point per number), backspace/
  clear/clear-all, the session tape, and continuing a calculation from a
  previous result.
- `engines/percentage_engine_test.dart` — the standalone percentage
  functions (`percentOf`, `increaseBy`, `markupPrice`, …) that later
  power the Finance module.
- `core/number_formatter_test.dart` — grouping, trailing-zero trimming,
  sign handling, and capped precision on non-terminating decimals.

> This scaffold was authored without a local Flutter/Dart SDK available
> in the generation environment, so `flutter pub get && flutter test`
> has not been executed here — please run it as the first step after
> pulling the repo, and file an issue for anything that doesn't pass.

## Roadmap

- [x] **Phase 1 — Foundation**: project setup, theme, calculator engine,
      basic keypad, expression display.
- [ ] **Phase 2 — Signature UX**: calculation tape UI, Quick Scan,
      inline editing, gestures, undo, persistent session.
- [ ] **Phase 3 — Sharing**: Share Result, clean image/text cards,
      session sharing.
- [ ] **Phase 4 — Everyday intelligence**: fractions, unit converter,
      running totals, discount/paid/change.
- [ ] **Phase 5 — Scientific**: trig/log/exponent functions, DEG/RAD/GRAD.
- [ ] **Phase 6 — Advanced**: algebra, statistics, geometry, graphing,
      matrices, calculus, complex numbers, programmer mode.

## Contributing

1. Fork and branch off `main`.
2. Keep `lib/engines/**` free of Flutter imports.
3. Add or update tests for any engine change — `flutter test` must pass.
4. Run `dart format .` and `flutter analyze` before opening a PR.
5. One feature per PR where practical.

## License

MIT — see [LICENSE](LICENSE).
