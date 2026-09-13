# Cardex

An offline-first Flutter collector for car marques. Mark a brand when you see
it, learn its origin and current ownership, and complete manufacturer and
country sets.

## Run

Install Flutter and an Android SDK/JDK, then run:

```bash
flutter pub get
flutter run
```

The initial catalog is bundled in `lib/data/catalog_seed.dart`; user progress
is stored locally with `shared_preferences`. No account or network access is
required.
