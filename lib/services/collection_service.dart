import 'package:flutter/foundation.dart';

import '../models/catalog_models.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/progress_repository.dart';

class CollectionService extends ChangeNotifier {
  CollectionService(this.catalog, this.progress);
  final CatalogRepository catalog;
  final ProgressRepository progress;
  Map<String, CollectionRecord> _records = {};
  bool ready = false;

  Future<void> initialize() async {
    _records = await progress.load();
    ready = true;
    notifyListeners();
  }

  bool isCollected(String brandId) => _records.containsKey(brandId);
  int get collectedCount => _records.length;
  DateTime? collectedAt(String brandId) => _records[brandId]?.firstCollectedAt;

  Future<void> toggle(CarBrand brand) async {
    if (isCollected(brand.id)) {
      _records.remove(brand.id);
      await progress.remove(brand.id);
    } else {
      final record = CollectionRecord(brandId: brand.id, firstCollectedAt: DateTime.now());
      _records[brand.id] = record;
      await progress.save(record);
    }
    notifyListeners();
  }

  List<CarBrand> brandsForBadge(Badge badge) => catalog.brands.where((brand) {
        return badge.kind == BadgeKind.manufacturer
            ? brand.groupId == badge.subjectId
            : brand.originCountryId == badge.subjectId;
      }).toList();

  bool isBadgeEarned(Badge badge) {
    final set = brandsForBadge(badge);
    return set.isNotEmpty && set.every((brand) => isCollected(brand.id));
  }

  List<CarBrand> missingForBadge(Badge badge) =>
      brandsForBadge(badge).where((brand) => !isCollected(brand.id)).toList();
}

/// Contract for a later camera/ML feature; deliberately unused in v1.
abstract class BrandRecognitionService {
  Future<List<String>> recognizeBrandIds(List<int> imageBytes);
}
