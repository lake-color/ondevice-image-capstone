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
  FakePicker picker, {
  Future<void> Function()? openSettings,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final requested = <RouteSettings>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AnalysisPage(
        inputService: ImageInputService(
          imagePicker: picker,
          openSettings: openSettings ?? () async {},
        ),
      ),
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

/// Records which photos the page asks to discard instead of deleting files.
class RecordingInputService extends ImageInputService {
  RecordingInputService(FakePicker picker) : super(imagePicker: picker);

  final discarded = <String>[];

  @override
  Future<void> discard(ImageInput input) async => discarded.add(input.path);
}

/// Opens the source sheet with the main button, whatever its label, and
/// chooses [option].
Future<void> pickFrom(WidgetTester tester, String option) async {
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

InkWell methodButton(WidgetTester tester, String title) => tester.widget(
  find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
);

void main() {
  testWidgets('the source sheet explains why each access is needed', (
    tester,
  ) async {
    await pumpAnalysisPage(tester, FakePicker());

    await tester.tap(find.text('사진 가져오기'));
    await tester.pumpAndSettle();

    expect(
      find.text('촬영을 위해 카메라 권한을 요청해요. 사진은 기기 안에서만 사용합니다.'),
      findsOneWidget,
    );
    expect(find.text('직접 고른 사진 한 장만 앱에 전달됩니다.'), findsOneWidget);
  });

  for (final (option, source) in [
    ('카메라로 촬영', ImageSource.camera),
    ('갤러리에서 선택', ImageSource.gallery),
  ]) {
    testWidgets('a photo from "$option" is displayed', (tester) async {
      final picker = FakePicker(file: XFile('/tmp/picked.jpg'));
      await pumpAnalysisPage(tester, picker);
      expect(find.text('분석할 사진을 추가해 주세요'), findsOneWidget);

      await pickFrom(tester, option);

      expect(picker.lastSource, source);
      expect(find.text('분석할 사진을 추가해 주세요'), findsNothing);
      expect(find.textContaining('picked.jpg'), findsOneWidget);
      expect(find.text('다른 사진 선택'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<FileImage>());
    });
  }

  testWidgets('cancelling the picker keeps the page unchanged', (tester) async {
    await pumpAnalysisPage(tester, FakePicker());

    await pickFrom(tester, '갤러리에서 선택');

    expect(find.text('분석할 사진을 추가해 주세요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the source sheet without choosing does nothing', (
    tester,
  ) async {
    final picker = FakePicker(file: XFile('/tmp/picked.jpg'));
    await pumpAnalysisPage(tester, picker);

    await tester.tap(find.text('사진 가져오기'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(picker.lastSource, isNull);
    expect(find.text('분석할 사진을 추가해 주세요'), findsOneWidget);
  });

  for (final (option, code, title) in [
    ('카메라로 촬영', 'camera_access_denied', '카메라 권한이 필요해요'),
    ('갤러리에서 선택', 'photo_access_denied', '사진 접근 권한이 필요해요'),
  ]) {
    testWidgets('denied access explains the source that was denied: $option', (
      tester,
    ) async {
      var settingsOpened = 0;
      await pumpAnalysisPage(
        tester,
        FakePicker(error: PlatformException(code: code)),
        openSettings: () async => settingsOpened++,
      );

      await pickFrom(tester, option);

      expect(find.text('권한 거부'), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining('설정 > 권한'), findsOneWidget);
      // Picking has ended, so nothing keeps spinning behind the dialog.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('설정에서 권한 열기'));
      await tester.pumpAndSettle();
      expect(settingsOpened, 1);
      expect(find.text(title), findsNothing);
      expect(find.text('사진 선택'), findsOneWidget);
    });
  }

  testWidgets(
    'a denied permission can be dismissed and the app keeps working',
    (tester) async {
      await pumpAnalysisPage(
        tester,
        FakePicker(error: PlatformException(code: 'camera_access_denied')),
      );

      await pickFrom(tester, '카메라로 촬영');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('권한 거부'), findsNothing);
      expect(find.text('사진 가져오기'), findsOneWidget);
    },
  );

  testWidgets('settings that cannot be opened are reported, not thrown', (
    tester,
  ) async {
    await pumpAnalysisPage(
      tester,
      FakePicker(error: PlatformException(code: 'camera_access_denied')),
      openSettings: () async => throw PlatformException(code: 'unavailable'),
    );

    await pickFrom(tester, '카메라로 촬영');
    await tester.tap(find.text('설정에서 권한 열기'));
    await tester.pumpAndSettle();

    expect(
      find.text('설정을 열지 못했습니다. 기기 설정에서 앱 권한을 직접 변경해 주세요.'),
      findsOneWidget,
    );
  });

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

  testWidgets('a photo is discarded when replaced and on leaving the page', (
    tester,
  ) async {
    final picker = FakePicker(file: XFile('/tmp/first.jpg'));
    final service = RecordingInputService(picker);
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AnalysisPage(inputService: service),
      ),
    );

    await pickFrom(tester, '갤러리에서 선택');
    expect(service.discarded, isEmpty);

    picker.file = XFile('/tmp/second.jpg');
    await pickFrom(tester, '갤러리에서 선택');
    expect(service.discarded, [XFile('/tmp/first.jpg').path]);

    // A cancelled pick keeps the current photo.
    picker.file = null;
    await pickFrom(tester, '갤러리에서 선택');
    expect(service.discarded, hasLength(1));

    await tester.pumpWidget(const SizedBox());
    expect(service.discarded.last, XFile('/tmp/second.jpg').path);
  });
}
