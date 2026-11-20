# P11: verification and failure behavior

## Branch and automated checks

Work for this task is prepared on `v1.0_dev`. A push to that branch starts the
GitHub Actions workflow `.github/workflows/p11-quality-gate.yml`, which performs these
checks in order:

1. Install Flutter packages.
2. Check tracked files for private keys.
3. Run `dart analyze lib test`.
4. Run the full unit test suite with `flutter test --no-pub`.
5. Build a debug Android APK and upload it as the `yomu-debug-apk` artifact.

The APK artifact is the installable demo for a mobile app. This pipeline does
not publish to an app store or deploy a live web service.

## What happens when a unit test fails?

Flutter exits with a non-zero status and prints the failing test name, source
location, expected value, and actual value. GitHub Actions marks the check red
and the job stops at the test step. The Android build and APK upload do not run,
so a failing change cannot produce a demo artifact. Fix the implementation or
the incorrect expectation, run the complete suite again, then push the fix.

The failure behavior was exercised with a temporary deliberately incorrect
expectation and then removed. The committed suite must remain green.

## Focus of the P11 regression tests

`p11_comic_count_contract_test.dart` exercises the API model's chapter-count
mapping over 133 values, numeric and text representations, list/detail payloads,
field aliases, plus malformed-value fallbacks. These cases protect admin forms
and bookmark/comic displays from showing stale or missing chapter counts.

## Results

Local verification on 20 November 2026:

- `dart analyze lib test`: passed, no issues found.
- `flutter test --no-pub`: passed; Flutter reported `+201` with no failures.
- `flutter build apk --debug --no-pub`: passed; APK built at
  `comicstream_app/build/app/outputs/flutter-apk/app-debug.apk` (about 186 MB).
- Failure demo: a temporary expected-value mismatch displayed
  `Expected: <195> / Actual: <194>`, returned exit code 1, and was removed.
