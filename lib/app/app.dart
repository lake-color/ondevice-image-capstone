import 'package:flutter/material.dart';

import '../data/analysis_history_store.dart';
import '../service/analysis_service.dart';
import '../service/image_input_service.dart';
import '../service/ocr_analyzer.dart';
import '../service/share_service.dart';
import '../service/text_analyzer.dart';
import 'app_router.dart';
import 'app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AnalysisHistoryStore _historyStore;
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _historyStore = AnalysisHistoryStore();
    _router = AppRouter(
      inputService: UnavailableImageInputService(),
      analysisService: const AnalysisService(
        UnavailableOcrAnalyzer(),
        UnavailableTextAnalyzer(),
      ),
      historyStore: _historyStore,
      shareService: ClipboardShareService(),
    );
  }

  @override
  void dispose() {
    _historyStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '온디바이스 이미지 분석',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      onGenerateRoute: _router.onGenerateRoute,
    );
  }
}
