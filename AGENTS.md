# Repository Guidelines

## Project Structure & Module Organization

Cardex is an offline-first Flutter application. Application code lives in `lib/`:

- `main.dart` contains app bootstrap and UI widgets.
- `models/` defines catalog and collection data types.
- `repositories/` provides bundled catalog access and local progress persistence.
- `services/` contains collection and badge behavior.
- `data/catalog_seed.dart` is the built-in car-marque catalog.

Tests live in `test/` and generally mirror the feature under test, such as `collection_service_test.dart`. Android host configuration is under `android/`. The app currently has no separate asset directory; declare new assets in `pubspec.yaml` before use.

## Build, Test, and Development Commands

Run commands from the repository root:

```bash
flutter pub get       # Install locked Dart and Flutter dependencies.
flutter run           # Launch on a connected device or emulator.
flutter analyze       # Apply analyzer rules from analysis_options.yaml.
flutter test          # Run the complete unit and widget test suite.
flutter build apk     # Produce an Android release APK.
dart format lib test  # Format Dart source and tests.
```

Use `flutter test test/catalog_seed_test.dart` while iterating on one area.

## Coding Style & Naming Conventions

Follow `flutter_lints` and standard Dart formatting (two-space indentation, trailing commas where they improve formatting). Use `UpperCamelCase` for classes and enums, `lowerCamelCase` for methods and variables, and `snake_case.dart` for files. Prefix library-private declarations with `_`. Keep UI state in widgets, persistence behind repository interfaces, and collection rules in services. Prefer `const` constructors and immutable fields where possible.

## Testing Guidelines

Tests use `flutter_test`. Name files `*_test.dart` and describe observable behavior in `test` or `testWidgets` labels. Add focused coverage for service rules, catalog integrity, persistence behavior, and user-visible navigation or controls. Use in-memory fakes for repository dependencies so tests remain deterministic and offline. Run `flutter analyze` and `flutter test` before submitting changes.

## Commit & Pull Request Guidelines

History favors concise, imperative commit subjects, for example `Add better navigation and sorting to explore and discover pages.` Keep each commit focused and explain non-obvious tradeoffs in the body. Pull requests should include a clear summary, verification commands, and linked issues when applicable. Attach screenshots or recordings for UI changes, and call out catalog migrations or Android configuration changes explicitly.

## Data & Configuration

Cardex requires no account or network access. Do not commit secrets, generated build output, `.dart_tool/`, or IDE-specific files. Preserve backward compatibility for data stored through `shared_preferences` when changing progress models.
