import 'package:flutter/material.dart';

import '../page/analysis_page.dart';
import '../page/title_page.dart';
import '../service/image_input_service.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const analysis = '/analysis';
}

class AppRouter {
  const AppRouter({required this.inputService});

  final ImageInputService inputService;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.home => const TitlePage(),
      AppRoutes.analysis => AnalysisPage(inputService: inputService),
      _ => const TitlePage(),
    };

    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
