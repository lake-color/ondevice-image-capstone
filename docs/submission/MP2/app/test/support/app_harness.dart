import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/app/app_router.dart';
import 'package:ondevice_image_capstone/app/app_theme.dart';
import 'package:ondevice_image_capstone/service/analysis_service.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';

import 'fakes.dart';

/// Pumps the real router and theme with test doubles for the services, on a
/// phone-shaped surface so every button is on screen. Returns the navigator.
Future<NavigatorState> pumpRoutedApp(
  WidgetTester tester, {
  ImageInputService? inputService,
  AnalysisService? analysisService,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final navigatorKey = GlobalKey<NavigatorState>();
  final router = AppRouter(
    inputService: inputService ?? ImageInputService(imagePicker: FakePicker()),
    analysisService:
        analysisService ?? AnalysisService(FakeOcr(), FakeClassifier()),
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      onGenerateRoute: router.onGenerateRoute,
    ),
  );
  return navigatorKey.currentState!;
}
