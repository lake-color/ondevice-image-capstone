import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ondevice_image_capstone/app/app.dart';
import 'package:ondevice_image_capstone/service/analysis_service.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';

void main() {
  testWidgets(
    'start, pick a photo, analyse, see the result, then find it in history',
    (tester) async {
      final store = await loadedStore();
      await pumpRoutedApp(
        tester,
        store: store,
        inputService: ImageInputService(
          imagePicker: FakePicker(file: XFile('/tmp/picked.jpg')),
        ),
        analysisService: AnalysisService(
          FakeOcr(),
          FakeClassifier(label: 'tabby', confidence: 0.9),
        ),
      );

      // Title page.
      expect(find.text('사진 속 정보를\n기기에서 바로 분석해요'), findsOneWidget);
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      // Photo selection.
      expect(find.text('사진 선택'), findsOneWidget);
      await tester.tap(find.text('사진 가져오기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('갤러리에서 선택'));
      await tester.pumpAndSettle();

      // Analysis passes through the loading page to the result.
      await tester.tap(find.text('사물 분석'));
      await tester.pumpAndSettle();
      expect(find.text('분석 결과'), findsOneWidget);
      expect(find.text('tabby'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);

      // Back on photo selection, the same photo is still selected.
      await tester.tap(find.text('다른 사진 분석'));
      await tester.pumpAndSettle();
      expect(find.text('사진 선택'), findsOneWidget);
      expect(find.text('분석할 사진을 추가해 주세요'), findsNothing);

      // The result was saved and is listed in history.
      await tester.tap(find.text('분석 이력 보기'));
      await tester.pumpAndSettle();
      expect(find.text('분석 이력'), findsOneWidget);
      expect(find.text('tabby'), findsOneWidget);

      await tester.tap(find.text('돌아가기'));
      await tester.pumpAndSettle();
      expect(find.text('사진 선택'), findsOneWidget);
    },
  );

  testWidgets('the real App starts even when history storage is unavailable', (
    tester,
  ) async {
    // The real wiring in app.dart: no storage directory can be resolved here,
    // so the history load fails and the app must still be usable.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => null,
    );
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('사물 분석'), findsOneWidget);
    expect(find.text('텍스트 분석'), findsOneWidget);

    await tester.tap(find.text('분석 이력 보기'));
    await tester.pumpAndSettle();
    expect(find.text('저장된 이력을 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
