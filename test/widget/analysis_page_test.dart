import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ondevice_image_capstone/app/app_router.dart';
import 'package:ondevice_image_capstone/app/app_theme.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/page/analysis_page.dart';
import 'package:ondevice_image_capstone/service/analysis_service.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';

import '../support/fakes.dart';

/// Pumps the page alone and records the routes it asks for.
Future<List<RouteSettings>> pumpAnalysisPage(
  WidgetTester tester,
  FakePicker picker,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final requested = <RouteSettings>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AnalysisPage(inputService: ImageInputService(imagePicker: picker)),
      onGenerateRoute: (settings) {
        requested.add(settings);
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('다음 화면')),
        );
      },
    ),
  );
  return requested;
}

Future<void> pickFrom(WidgetTester tester, String option) async {
  await tester.tap(find.text('다른 사진 선택'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

InkWell methodButton(WidgetTester tester, String title) => tester.widget(
  find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
);

void main() {
  testWidgets('analysis cannot start until a photo is selected', (
    tester,
  ) async {
    final requested = await pumpAnalysisPage(tester, FakePicker());

    expect(find.text('분석할 사진을 추가해 주세요'), findsOneWidget);
    for (final title in ['사물 분석', '텍스트 분석']) {
      expect(methodButton(tester, title).onTap, isNull);
    }

    // Closing the picker without choosing keeps the page unchanged.
    await pickFrom(tester, '갤러리에서 선택');
    expect(find.text('분석할 사진을 추가해 주세요'), findsOneWidget);
    expect(methodButton(tester, '사물 분석').onTap, isNull);
    expect(requested, isEmpty);
  });

  testWidgets('a selected photo starts the chosen analysis with that photo', (
    tester,
  ) async {
    final file = XFile('/tmp/picked.jpg');
    final requested = await pumpAnalysisPage(tester, FakePicker(file: file));

    await pickFrom(tester, '갤러리에서 선택');
    expect(find.text('분석할 사진을 추가해 주세요'), findsNothing);

    await tester.tap(find.text('텍스트 분석'));
    await tester.pumpAndSettle();

    final settings = requested.single;
    expect(settings.name, AppRoutes.loading);
    final request = settings.arguments! as AnalysisRequest;
    expect(request.method, AnalysisMethod.ocr);
    expect(request.input.path, file.path);
  });

  for (final (option, code, title) in [
    ('카메라로 촬영', 'camera_access_denied', '카메라 권한이 필요해요'),
    ('갤러리에서 선택', 'photo_access_denied', '사진 접근 권한이 필요해요'),
  ]) {
    testWidgets('denied access explains the source that was denied: $option', (
      tester,
    ) async {
      await pumpAnalysisPage(
        tester,
        FakePicker(error: PlatformException(code: code)),
      );

      await pickFrom(tester, option);

      expect(find.text('권한 거부'), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      // Picking has ended, so nothing keeps spinning behind the dialog.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('설정에서 권한 열기'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsNothing);
      expect(find.text('사진 선택'), findsOneWidget);
    });
  }

  testWidgets('other input failures show a readable message', (tester) async {
    await pumpAnalysisPage(
      tester,
      FakePicker(
        error: PlatformException(
          code: 'invalid_image',
          message: 'raw platform text',
        ),
      ),
    );

    await pickFrom(tester, '갤러리에서 선택');

    expect(find.text('사진을 불러오지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('raw platform text'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
