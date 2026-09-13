import 'package:cardex/data/catalog_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1 catalog has 75 uniquely identified brands with valid relationships', () {
    expect(CatalogSeed.brands, hasLength(75));
    expect(CatalogSeed.brands.map((brand) => brand.id).toSet(), hasLength(75));
    final countryIds = CatalogSeed.countries.map((country) => country.id).toSet();
    final groupIds = CatalogSeed.groups.map((group) => group.id).toSet();
    for (final brand in CatalogSeed.brands) {
      expect(countryIds, contains(brand.originCountryId), reason: brand.name);
      expect(groupIds, contains(brand.groupId), reason: brand.name);
    }
  });
}
