import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/app/app_router.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/domain/exceptions.dart';
import 'package:ondevice_image_capstone/page/notice_card.dart';
import 'package:ondevice_image_capstone/service/analysis_service.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';

const ocrRequest = AnalysisRequest(
  method: AnalysisMethod.ocr,
  input: sampleInput,
);

void main() {
  testWidgets('a finished analysis is shown on the result page', (
    tester,
  ) async {
    final navigator = await pumpRoutedApp(
      tester,
      analysisService: AnalysisService(
        FakeOcr(text: '안녕하세요'),
        FakeClassifier(),
      ),
    );

    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();

    expect(find.text('분석 결과'), findsOneWidget);
    expect(find.text('안녕하세요'), findsOneWidget);

    // The loading page was replaced, so leaving the result returns home.
    await tester.tap(find.text('다른 사진 분석'));
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('a failed analysis explains why', (tester) async {
    final navigator = await pumpRoutedApp(
      tester,
      analysisService: AnalysisService(
        FakeOcr(error: const AnalysisException('사진에서 인식할 텍스트를 찾지 못했습니다.')),
        FakeClassifier(),
      ),
    );

    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();

    expect(find.byType(NoticeCard), findsOneWidget);
    expect(find.text('인식 불가'), findsOneWidget);
    expect(find.text('사진에서 인식할 텍스트를 찾지 못했습니다.'), findsOneWidget);

    await tester.tap(find.text('다른 사진 분석'));
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('an unexpected error shows general guidance, not its details', (
    tester,
  ) async {
    final navigator = await pumpRoutedApp(
      tester,
      analysisService: AnalysisService(
        FakeOcr(error: StateError('internal detail')),
        FakeClassifier(),
      ),
    );

    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();

    expect(find.text('다른 사진을 선택하거나 분석 방식을 바꿔보세요.'), findsOneWidget);
    expect(find.textContaining('internal detail'), findsNothing);
  });

  testWidgets('cancelling leaves the page and discards the late result', (
    tester,
  ) async {
    final gate = Completer<void>();
    final navigator = await pumpRoutedApp(
      tester,
      analysisService: AnalysisService(
        FakeOcr(gate: gate.future),
        FakeClassifier(),
      ),
    );

    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();
    expect(find.text('사진을 분석하고 있어요'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('분석 취소'));
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('분석 결과'), findsNothing);
  });
}
