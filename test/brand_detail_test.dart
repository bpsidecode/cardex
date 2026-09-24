import 'package:cardex/main.dart';
import 'package:cardex/models/catalog_models.dart';
import 'package:cardex/repositories/catalog_repository.dart';
import 'package:cardex/repositories/progress_repository.dart';
import 'package:cardex/services/collection_service.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';

class _MemoryProgress implements ProgressRepository {
  final records = <String, CollectionRecord>{};
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
  _Catalog(this.brandItem);
  final CarBrand brandItem;
  @override
  int get version => 1;
  @override
  List<CarBrand> get brands => [brandItem];
  @override
  List<ManufacturerGroup> get groups =>
      const [ManufacturerGroup(id: 'toyota', name: 'Toyota Motor Corporation')];
  @override
  List<OriginCountry> get countries =>
      const [OriginCountry(id: 'jp', name: 'Japan', flag: '🇯🇵')];
  @override
  List<Badge> get badges => const [];
  @override
  CarBrand brand(String id) => brandItem;
  @override
  OriginCountry country(String id) => countries.single;
  @override
  ManufacturerGroup group(String id) => groups.single;
}

void main() {
  testWidgets('detail screen celebrates collecting and can remove a brand', (
    tester,
  ) async {
    const brand = CarBrand(
        id: 'lexus',
        name: 'Lexus',
        foundedYear: 1989,
        originCountryId: 'jp',
        groupId: 'toyota',
        description: 'Toyota luxury marque.');
    final service = CollectionService(_Catalog(brand), _MemoryProgress());
    await service.initialize();
    await tester.pumpWidget(AnimatedBuilder(
      animation: service,
      builder: (_, __) =>
          MaterialApp(home: BrandDetailPage(brand: brand, service: service)),
    ));
    expect(find.text('I spotted Lexus'), findsOneWidget);
    await tester.tap(find.text('I spotted Lexus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(service.isCollected('lexus'), isTrue);
    expect(find.byKey(const Key('new-find-celebration')), findsOneWidget);
    expect(find.text('New find!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('brand-detail-lexus')), findsOneWidget);
    expect(find.text('Remove from collection'), findsOneWidget);

    await tester.tap(find.text('Remove from collection'));
    await tester.pump();

    expect(service.isCollected('lexus'), isFalse);
    expect(find.text('I spotted Lexus'), findsOneWidget);
  });

  testWidgets('quick collect celebrates before opening brand details', (
    tester,
  ) async {
    const brand = CarBrand(
      id: 'lexus',
      name: 'Lexus',
      foundedYear: 1989,
      originCountryId: 'jp',
      groupId: 'toyota',
      description: 'Toyota luxury marque.',
    );
    final service = CollectionService(_Catalog(brand), _MemoryProgress());
    await service.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BrandTile(brand: brand, service: service)),
      ),
    );

    await tester.tap(find.byTooltip('Collect Lexus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(service.isCollected('lexus'), isTrue);
    expect(find.byKey(const Key('new-find-celebration')), findsOneWidget);
    expect(find.text('New find!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('brand-detail-lexus')), findsOneWidget);
    expect(find.text('Toyota luxury marque.'), findsOneWidget);
    expect(find.text('Remove from collection'), findsOneWidget);
  });
}
