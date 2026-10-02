# android/

This folder intentionally does not contain hand-authored platform
files. Generate them locally with:

```bash
flutter create . --platforms=android
```

run once from the project root after `flutter pub get`. Flutter
regenerates this folder deterministically from `pubspec.yaml`, so
hand-committing it here would only invite drift.
