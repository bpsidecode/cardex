import 'package:cardex/main.dart';
import 'package:cardex/models/catalog_models.dart';
import 'package:cardex/repositories/catalog_repository.dart';
import 'package:cardex/repositories/progress_repository.dart';
import 'package:cardex/services/collection_service.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';

class _MemoryProgress implements ProgressRepository {
  _MemoryProgress(Iterable<String> collectedIds)
      : records = {
          for (final id in collectedIds)
            id: CollectionRecord(
              brandId: id,
              firstCollectedAt: DateTime(2026),
            ),
        };

  final Map<String, CollectionRecord> records;

  @override
  Future<Map<String, CollectionRecord>> load() async => Map.of(records);

  @override
  Future<void> remove(String brandId) async {
    records.remove(brandId);
  }

  @override
  Future<void> save(CollectionRecord record) async {
    records[record.brandId] = record;
  }
}

class _Catalog implements CatalogRepository {
  static const completeBrand = CarBrand(
    id: 'complete-one',
    name: 'Complete One',
    foundedYear: 2001,
    originCountryId: 'test-country',
    groupId: 'complete',
    description: '',
  );
  static const progressOne = CarBrand(
    id: 'progress-one',
    name: 'Progress One',
    foundedYear: 2002,
    originCountryId: 'test-country',
    groupId: 'progress',
    description: '',
  );
  static const progressTwo = CarBrand(
    id: 'progress-two',
    name: 'Progress Two',
    foundedYear: 2003,
    originCountryId: 'test-country',
    groupId: 'progress',
    description: '',
  );
  static const notStartedBrand = CarBrand(
    id: 'not-started-one',
    name: 'Not Started One',
    foundedYear: 2004,
    originCountryId: 'test-country',
    groupId: 'not-started',
    description: '',
  );

  @override
  int get version => 1;

  @override
  List<CarBrand> get brands => const [
        completeBrand,
        progressOne,
        progressTwo,
        notStartedBrand,
      ];

  @override
  List<ManufacturerGroup> get groups => const [
        ManufacturerGroup(id: 'complete', name: 'Complete'),
        ManufacturerGroup(id: 'progress', name: 'Progress'),
        ManufacturerGroup(id: 'not-started', name: 'Not Started'),
      ];

  @override
  List<OriginCountry> get countries => const [
        OriginCountry(id: 'test-country', name: 'Test Country', flag: '🏁'),
      ];

  @override
  List<Badge> get badges => const [
        Badge(
          id: 'maker-complete',
          title: 'Complete collection',
          kind: BadgeKind.manufacturer,
          subjectId: 'complete',
        ),
        Badge(
          id: 'maker-progress',
          title: 'Progress collection',
          kind: BadgeKind.manufacturer,
          subjectId: 'progress',
        ),
        Badge(
          id: 'maker-not-started',
          title: 'Not Started collection',
          kind: BadgeKind.manufacturer,
          subjectId: 'not-started',
        ),
      ];

  @override
  CarBrand brand(String id) => brands.firstWhere((brand) => brand.id == id);

  @override
  OriginCountry country(String id) => countries.single;

  @override
  ManufacturerGroup group(String id) =>
      groups.firstWhere((group) => group.id == id);
}

void main() {
  testWidgets('Explore distinguishes all three collection progress states', (
    tester,
  ) async {
    final service = CollectionService(
      _Catalog(),
      _MemoryProgress(const ['complete-one', 'progress-one']),
    );
    await service.initialize();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ExplorePage(service: service))),
    );
    await tester.tap(find.text('Manufacturer collections'));
    await tester.pumpAndSettle();

    expect(find.text('Badge earned'), findsOneWidget);
    expect(find.text('1 brand to find'), findsOneWidget);
    expect(find.text('Not started · 1 brand to find'), findsOneWidget);

    final completedIcon = tester.widget<CircleAvatar>(
      find.byKey(const Key('collection-icon-maker-complete')),
    );
    final inProgressIcon = tester.widget<CircleAvatar>(
      find.byKey(const Key('collection-icon-maker-progress')),
    );
    final notStartedIcon = tester.widget<CircleAvatar>(
      find.byKey(const Key('collection-icon-maker-not-started')),
    );
    final context = tester.element(find.byType(ExplorePage));
    final colors = Theme.of(context).colorScheme;

    expect(completedIcon.backgroundColor, const Color(0xffd4af37));
    expect(inProgressIcon.backgroundColor, isNull);
    expect(notStartedIcon.backgroundColor, colors.surfaceContainerHighest);

    final completedProgress = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('collection-progress-maker-complete')),
    );
    final inProgress = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('collection-progress-maker-progress')),
    );
    final notStarted = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('collection-progress-maker-not-started')),
    );

    expect(completedProgress.value, 1);
    expect(completedProgress.color, const Color(0xffd4af37));
    expect(inProgress.value, 0.5);
    expect(inProgress.color, colors.primary);
    expect(notStarted.value, 0);
    expect(notStarted.color, colors.outline);
  });
}
