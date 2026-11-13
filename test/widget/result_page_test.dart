import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/app/app_theme.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/domain/analysis_result.dart';
import 'package:ondevice_image_capstone/page/result_page.dart';

import '../support/fakes.dart';

const lowConfidenceNotice = '신뢰도가 낮은 추정 결과입니다. 사물이 크게 보이는 사진으로 다시 분석해 주세요.';

Future<void> pumpResult(WidgetTester tester, AnalysisResult result) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ResultPage(result: result),
    ),
  );
  await tester.pumpAndSettle();
}

AnalysisResult classification(double confidence) => AnalysisResult(
  method: AnalysisMethod.imageClassification,
  sourceName: 'cat.jpg',
  title: '분류 결과',
  content: 'Egyptian cat',
  duration: const Duration(milliseconds: 615),
  createdAt: DateTime.utc(2026, 11, 14),
  confidence: confidence,
  imagePath: '/tmp/cat.jpg',
);

void main() {
  testWidgets('classification shows label, time, confidence and the photo', (
    tester,
  ) async {
    await pumpResult(tester, classification(0.82));

    expect(find.text('사물 분석 결과를 확인하세요.'), findsOneWidget);
    expect(find.text('Egyptian cat'), findsOneWidget);
    expect(find.text('0.61초'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text(lowConfidenceNotice), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as FileImage).file.path, File('/tmp/cat.jpg').path);
  });

  testWidgets('confidence below 50% is flagged as uncertain', (tester) async {
    await pumpResult(tester, classification(0.31));

    expect(find.text('31%'), findsOneWidget);
    expect(find.text(lowConfidenceNotice), findsOneWidget);
  });

  testWidgets('OCR shows the text without a confidence row', (tester) async {
    await pumpResult(tester, sampleResult('안녕하세요\nHello'));

    expect(find.text('텍스트 분석 결과를 확인하세요.'), findsOneWidget);
    expect(find.text('안녕하세요\nHello'), findsOneWidget);
    expect(find.text('인식 신뢰도'), findsNothing);
    // History entries carry no photo path.
    expect(find.text('원본 사진은 이력에 저장되지 않습니다.'), findsOneWidget);
  });

  testWidgets('share opens the OS share sheet with the result text', (
    tester,
  ) async {
    final calls = mockShareChannel(tester);
    final result = classification(0.306);
    await pumpResult(tester, result);

    await tester.tap(find.text('결과 공유하기'));
    await tester.pumpAndSettle();

    expect(calls.single.method, 'share');
    final arguments = calls.single.arguments as Map;
    expect(arguments['text'], result.shareText);
    // iPad needs a non-empty anchor rectangle for the share popover.
    expect(arguments['originWidth'], greaterThan(0));
    expect(arguments['originHeight'], greaterThan(0));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a share failure is reported instead of crashing', (
    tester,
  ) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'error', message: 'raw'),
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await pumpResult(tester, classification(0.82));

    await tester.tap(find.text('결과 공유하기'));
    await tester.pumpAndSettle();

    expect(find.text('공유 화면을 열지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('raw'), findsNothing);
  });
}
