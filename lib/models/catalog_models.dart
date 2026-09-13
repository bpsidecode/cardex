class CarBrand {
  const CarBrand({
    required this.id,
    required this.name,
    required this.foundedYear,
    required this.originCountryId,
    required this.groupId,
    required this.description,
    this.logoAsset,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int foundedYear;
  final String originCountryId;
  final String groupId;
  final String description;
  /// Reserved for licensed/offical image assets. The v1 UI uses a text mark.
  final String? logoAsset;
  final bool isActive;
}

class ManufacturerGroup {
  const ManufacturerGroup({required this.id, required this.name});
  final String id;
  final String name;
}

class OriginCountry {
  const OriginCountry({required this.id, required this.name, required this.flag});
  final String id;
  final String name;
  final String flag;
}

class Badge {
  const Badge({required this.id, required this.title, required this.kind, required this.subjectId});
  final String id;
  final String title;
  final BadgeKind kind;
  final String subjectId;
}

enum BadgeKind { manufacturer, country }

class CollectionRecord {
  const CollectionRecord({required this.brandId, required this.firstCollectedAt});
  final String brandId;
  final DateTime firstCollectedAt;
}
