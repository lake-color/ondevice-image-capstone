import 'package:flutter/material.dart';

import '../service/image_input_service.dart';
import 'app_router.dart';
import 'app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(inputService: ImageInputService());
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
