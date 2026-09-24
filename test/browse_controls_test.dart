import 'package:cardex/main.dart';
import 'package:cardex/repositories/catalog_repository.dart';
import 'package:cardex/repositories/progress_repository.dart';
import 'package:cardex/services/collection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CollectionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = CollectionService(
      BundledCatalogRepository(),
      LocalProgressRepository(),
    );
    await service.initialize();
  });

  tearDown(() => service.dispose());

  testWidgets('Discover sorts by each option and keeps search and tab state',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(service: service)));

    String firstBrand() =>
        tester.widget<BrandTile>(find.byType(BrandTile).first).brand.name;
    Future<void> chooseSort(String label) async {
      await tester.tap(find.byTooltip('Sort brands'));
      await tester.pumpAndSettle();
      await tester.tap(find.ancestor(
        of: find.text(label),
        matching:
            find.byWidgetPredicate((widget) => widget is CheckedPopupMenuItem),
      ));
      await tester.pumpAndSettle();
    }

    expect(firstBrand(), 'Abarth');
    await chooseSort('Country of origin');
    expect(firstBrand(), 'BYD');
    expect(
        tester
            .widgetList<BrandTile>(find.byType(BrandTile))
            .take(2)
            .map((tile) => tile.brand.name),
        ['BYD', 'Chery']);
    await chooseSort('Parent company');
    expect(firstBrand(), 'Aston Martin');
    expect(find.text('Aston Martin Lagonda'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'au');
    await tester.pumpAndSettle();
    expect(firstBrand(), 'Renault');
    await chooseSort('Alphabetical');
    expect(firstBrand(), 'Audi');
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();
    expect(find.text('Sort: Alphabetical'), findsOneWidget);
    expect(firstBrand(), 'Audi');
    expect(find.text('au'), findsOneWidget);
  });

  testWidgets(
      'Collections categories expand, collapse, and survive tab changes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(service: service)));
    expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);

    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();
    expect(find.text('Collections'), findsWidgets);
    final countrySection =
        find.widgetWithText(ExpansionTile, 'Country collections');
    expect(find.descendant(of: countrySection, matching: find.byType(ListTile)),
        findsOneWidget);
    await tester.tap(find.text('Country collections'));
    await tester.pumpAndSettle();
    expect(
        find
            .descendant(of: countrySection, matching: find.byType(ListTile))
            .evaluate()
            .length,
        greaterThan(1));
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collections').last);
    await tester.pumpAndSettle();
    expect(
        find
            .descendant(of: countrySection, matching: find.byType(ListTile))
            .evaluate()
            .length,
        greaterThan(1));
    await tester.tap(find.text('Country collections'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: countrySection, matching: find.byType(ListTile)),
        findsOneWidget);

    await tester.tap(find.text('Badges'));
    await tester.pumpAndSettle();
    expect(find.text('My badges'), findsOneWidget);
    expect(find.text('Earned badges'), findsOneWidget);
  });
}
