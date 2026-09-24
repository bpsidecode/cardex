import 'package:flutter/material.dart' hide Badge;

import '../models/catalog_models.dart';
import '../services/collection_service.dart';
import '../widgets/brand_mark.dart';
import 'collection_celebration.dart';

class BrandTile extends StatelessWidget {
  const BrandTile({
    super.key,
    required this.brand,
    required this.service,
    this.showParentCompany = false,
  });

  final CarBrand brand;
  final CollectionService service;
  final bool showParentCompany;

  @override
  Widget build(BuildContext context) {
    final collected = service.isCollected(brand.id);
    final country = service.catalog.country(brand.originCountryId);
    return ListTile(
      leading: BrandMark(name: brand.name, collected: collected),
      title: Text(brand.name),
      subtitle: Text(
        showParentCompany
            ? service.catalog.group(brand.groupId).name
            : '${country.flag} ${country.name} · ${brand.foundedYear}',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BrandDetailPage(brand: brand, service: service),
        ),
      ),
      trailing: IconButton(
        tooltip: collected ? 'Remove ${brand.name}' : 'Collect ${brand.name}',
        icon: Icon(
          collected ? Icons.check_circle : Icons.add_circle_outline,
          color: collected ? Theme.of(context).colorScheme.primary : null,
        ),
        onPressed: () async {
          if (collected) {
            await service.toggle(brand);
            return;
          }

          await collectAndCelebrate(
            Navigator.of(context),
            brand: brand,
            service: service,
            brandDetailBuilder: (_) =>
                BrandDetailPage(brand: brand, service: service),
          );
        },
      ),
    );
  }
}

class BrandDetailPage extends StatelessWidget {
  const BrandDetailPage({
    super.key,
    required this.brand,
    required this.service,
  });

  final CarBrand brand;
  final CollectionService service;

  @override
  Widget build(BuildContext context) {
    final country = service.catalog.country(brand.originCountryId);
    final group = service.catalog.group(brand.groupId);
    final countryBadge = service.catalog.badges.firstWhere(
      (badge) =>
          badge.kind == BadgeKind.country &&
          badge.subjectId == brand.originCountryId,
    );
    final manufacturerBadge = service.catalog.badges.firstWhere(
      (badge) =>
          badge.kind == BadgeKind.manufacturer &&
          badge.subjectId == brand.groupId,
    );
    final collected = service.isCollected(brand.id);
    return Scaffold(
      key: Key('brand-detail-${brand.id}'),
      appBar: AppBar(title: Text(brand.name)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: BrandMark(
              name: brand.name,
              collected: collected,
              size: 112,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            brand.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            brand.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _Fact(
            icon: Icons.calendar_today_outlined,
            label: 'Founded',
            value: '${brand.foundedYear}',
          ),
          _Fact(
            icon: Icons.public_outlined,
            label: 'Brand origin',
            value: '${country.flag} ${country.name}',
            onTap: () => _openSetDetail(context, countryBadge),
          ),
          _Fact(
            icon: Icons.account_tree_outlined,
            label: 'Current parent',
            value: group.name,
            onTap: () => _openSetDetail(context, manufacturerBadge),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: Icon(collected ? Icons.undo : Icons.check),
            label: Text(
              collected ? 'Remove from collection' : 'I spotted ${brand.name}',
            ),
            onPressed: () async {
              if (collected) {
                await service.toggle(brand);
                return;
              }

              await collectAndCelebrate(
                Navigator.of(context),
                brand: brand,
                service: service,
                returnToCurrentPage: true,
                brandDetailBuilder: (_) =>
                    BrandDetailPage(brand: brand, service: service),
              );
            },
          ),
          if (collected && service.collectedAt(brand.id) != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'First collected ${_date(service.collectedAt(brand.id)!)}',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  void _openSetDetail(BuildContext context, Badge badge) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SetDetailPage(badge: badge, service: service),
      ),
    );
  }
}

class SetDetailPage extends StatelessWidget {
  const SetDetailPage({
    super.key,
    required this.badge,
    required this.service,
  });

  final Badge badge;
  final CollectionService service;

  @override
  Widget build(BuildContext context) {
    final all = service.brandsForBadge(badge)
      ..sort((a, b) => a.name.compareTo(b.name));
    final missing = service.missingForBadge(badge);
    final earned = service.isBadgeEarned(badge);
    return Scaffold(
      appBar: AppBar(title: Text(badge.title)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  earned
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  size: 54,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  earned
                      ? 'Badge earned!'
                      : '${missing.length} brand${missing.length == 1 ? '' : 's'} still missing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                    '${all.length - missing.length} of ${all.length} collected'),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              earned ? 'Complete collection' : 'Brands to look for',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...all.map((brand) => BrandTile(brand: brand, service: service)),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        key: Key('brand-fact-${label.toLowerCase().replaceAll(' ', '-')}'),
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
