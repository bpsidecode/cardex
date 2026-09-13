import 'package:cardex/models/catalog_models.dart';
import 'package:cardex/repositories/catalog_repository.dart';
import 'package:cardex/repositories/progress_repository.dart';
import 'package:cardex/services/collection_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryProgressRepository implements ProgressRepository {
  final records = <String, CollectionRecord>{};
  @override Future<Map<String, CollectionRecord>> load() async => Map.of(records);
  @override Future<void> remove(String brandId) async { records.remove(brandId); }
  @override Future<void> save(CollectionRecord record) async { records.putIfAbsent(record.brandId, () => record); }
}

void main() {
  late CollectionService service;
  late CarBrand toyota;
  late CarBrand lexus;
  late Badge badge;

  setUp(() {
    toyota = const CarBrand(id: 'toyota', name: 'Toyota', foundedYear: 1937, originCountryId: 'jp', groupId: 'toyota', description: '');
    lexus = const CarBrand(id: 'lexus', name: 'Lexus', foundedYear: 1989, originCountryId: 'jp', groupId: 'toyota', description: '');
    final catalog = _Catalog([toyota, lexus]);
    service = CollectionService(catalog, MemoryProgressRepository());
    badge = const Badge(id: 'maker-toyota', title: 'Toyota collection', kind: BadgeKind.manufacturer, subjectId: 'toyota');
  });

  test('marks once, preserves first event, and can undo', () async {
    await service.initialize();
    await service.toggle(toyota);
    final first = service.collectedAt(toyota.id);
    expect(service.isCollected(toyota.id), isTrue);
    await service.toggle(toyota);
    expect(service.isCollected(toyota.id), isFalse);
    await service.toggle(toyota);
    expect(service.collectedAt(toyota.id), isNot(first));
  });

  test('badge needs every brand in its set and exposes missing brands', () async {
    await service.initialize();
    await service.toggle(toyota);
    expect(service.isBadgeEarned(badge), isFalse);
    expect(service.missingForBadge(badge), [lexus]);
    await service.toggle(lexus);
    expect(service.isBadgeEarned(badge), isTrue);
  });
}

class _Catalog implements CatalogRepository {
  _Catalog(this.brands);
  @override final List<CarBrand> brands;
  @override int get version => 1;
  @override List<ManufacturerGroup> get groups => const [ManufacturerGroup(id: 'toyota', name: 'Toyota')];
  @override List<OriginCountry> get countries => const [OriginCountry(id: 'jp', name: 'Japan', flag: '🇯🇵')];
  @override List<Badge> get badges => const [];
  @override CarBrand brand(String id) => brands.firstWhere((b) => b.id == id);
  @override OriginCountry country(String id) => countries.single;
  @override ManufacturerGroup group(String id) => groups.single;
}
