import '../data/catalog_seed.dart';
import '../models/catalog_models.dart';

abstract class CatalogRepository {
  int get version;
  List<CarBrand> get brands;
  List<ManufacturerGroup> get groups;
  List<OriginCountry> get countries;
  List<Badge> get badges;
  CarBrand brand(String id);
  ManufacturerGroup group(String id);
  OriginCountry country(String id);
}

class BundledCatalogRepository implements CatalogRepository {
  @override int get version => CatalogSeed.version;
  @override List<CarBrand> get brands => CatalogSeed.brands;
  @override List<ManufacturerGroup> get groups => CatalogSeed.groups;
  @override List<OriginCountry> get countries => CatalogSeed.countries;
  @override List<Badge> get badges => CatalogSeed.badges;
  @override CarBrand brand(String id) => brands.firstWhere((item) => item.id == id);
  @override ManufacturerGroup group(String id) => groups.firstWhere((item) => item.id == id);
  @override OriginCountry country(String id) => countries.firstWhere((item) => item.id == id);
}
