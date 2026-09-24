import 'package:flutter/material.dart';

import 'app/cardex_app.dart';

export 'app/cardex_app.dart' show CardexBootstrap;
export 'screens/badges_page.dart' show BadgesPage;
export 'screens/brand_pages.dart'
    show BrandDetailPage, BrandTile, SetDetailPage;
export 'screens/collections_page.dart' show CollectionsPage;
export 'screens/discover_page.dart' show DiscoverPage;
export 'screens/home_screen.dart' show HomeScreen;
export 'widgets/brand_mark.dart' show BrandMark;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardexBootstrap());
}
