import 'package:flutter/material.dart';

import '../models/catalog_models.dart';
import '../services/collection_service.dart';
import '../widgets/page_title.dart';
import 'brand_pages.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.service});

  final CollectionService service;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

enum _BrandSort {
  alphabetical('Alphabetical'),
  country('Country of origin'),
  parentCompany('Parent company');

  const _BrandSort(this.label);

  final String label;
}

class _DiscoverPageState extends State<DiscoverPage> {
  String query = '';
  _BrandSort sort = _BrandSort.alphabetical;

  int compareBrands(CarBrand a, CarBrand b) {
    final catalog = widget.service.catalog;
    final comparison = switch (sort) {
      _BrandSort.alphabetical => 0,
      _BrandSort.country => catalog
          .country(a.originCountryId)
          .name
          .compareTo(catalog.country(b.originCountryId).name),
      _BrandSort.parentCompany =>
        catalog.group(a.groupId).name.compareTo(catalog.group(b.groupId).name),
    };
    return comparison != 0 ? comparison : a.name.compareTo(b.name);
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.service.catalog.brands
        .where(
          (brand) => brand.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList()
      ..sort(compareBrands);
    return Column(
      children: [
        const PageTitle(
          title: 'Discover',
          subtitle: 'What did you spot today?',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SearchBar(
            hintText: 'Search car brands',
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => query = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<_BrandSort>(
              tooltip: 'Sort brands',
              initialValue: sort,
              onSelected: (value) => setState(() => sort = value),
              itemBuilder: (_) => _BrandSort.values
                  .map(
                    (value) => CheckedPopupMenuItem(
                      value: value,
                      checked: sort == value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort),
                    const SizedBox(width: 8),
                    Text('Sort: ${sort.label}'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: brands.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => BrandTile(
              brand: brands[i],
              service: widget.service,
              showParentCompany: sort == _BrandSort.parentCompany,
            ),
          ),
        ),
      ],
    );
  }
}
