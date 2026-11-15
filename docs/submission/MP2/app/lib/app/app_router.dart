import 'package:flutter/material.dart';

import '../domain/analysis_result.dart';
import '../page/analysis_page.dart';
import '../page/loading_page.dart';
import '../page/result_page.dart';
import '../page/title_page.dart';
import '../service/analysis_service.dart';
import '../service/image_input_service.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const analysis = '/analysis';
  static const loading = '/loading';
  static const result = '/result';
}

class AppRouter {
  const AppRouter({required this.inputService, required this.analysisService});

  final ImageInputService inputService;
  final AnalysisService analysisService;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.home => const TitlePage(),
      AppRoutes.analysis => AnalysisPage(inputService: inputService),
      AppRoutes.loading => LoadingPage(
        request: settings.arguments! as AnalysisRequest,
        analysisService: analysisService,
      ),
      AppRoutes.result => ResultPage(
        result: settings.arguments! as AnalysisResult,
      ),
      _ => const TitlePage(),
    };

    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
