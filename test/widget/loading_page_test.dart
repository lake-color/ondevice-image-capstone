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
  testWidgets('a finished analysis is saved and shown on the result page', (
    tester,
  ) async {
    final store = await loadedStore();
    final navigator = await pumpRoutedApp(
      tester,
      store: store,
      analysisService: AnalysisService(
        FakeOcr(text: '안녕하세요'),
        FakeClassifier(),
      ),
    );

    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();

    expect(find.text('분석 결과'), findsOneWidget);
    expect(find.text('안녕하세요'), findsOneWidget);
    expect(store.entries.single.result.content, '안녕하세요');

    // The loading page was replaced, so leaving the result returns home.
    await tester.tap(find.text('다른 사진 분석'));
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('a failed analysis explains why and saves nothing', (
    tester,
  ) async {
    final store = await loadedStore();
    final navigator = await pumpRoutedApp(
      tester,
      store: store,
      analysisService: AnalysisService(
        FakeOcr(error: const AnalysisException('사진에서 인식할 텍스트를 찾지 못했습니다.')),
        FakeClassifier(),
      ),
    );

    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();

    expect(find.byType(NoticeCard), findsOneWidget);
    expect(find.text('분석 실패'), findsOneWidget);
    expect(find.text('사진에서 인식할 텍스트를 찾지 못했습니다.'), findsOneWidget);
    expect(store.entries, isEmpty);

    await tester.tap(find.text('다른 사진 분석'));
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('an unexpected error shows general guidance, not its details', (
    tester,
  ) async {
    final store = await loadedStore();
    final navigator = await pumpRoutedApp(
      tester,
      store: store,
      analysisService: AnalysisService(
        FakeOcr(error: StateError('internal detail')),
        FakeClassifier(),
      ),
    );

    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();

    expect(find.text('다른 사진을 선택하거나 분석 방식을 바꿔보세요.'), findsOneWidget);
    expect(find.textContaining('internal detail'), findsNothing);
    expect(store.entries, isEmpty);
  });

  testWidgets('a failed save is retried without analysing the photo again', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final store = await loadedStore(storage);
    final ocr = FakeOcr(text: '안녕하세요');
    final navigator = await pumpRoutedApp(
      tester,
      store: store,
      analysisService: AnalysisService(ocr, FakeClassifier()),
    );

    storage.failWrite = true;
    navigator.pushNamed(AppRoutes.loading, arguments: ocrRequest);
    await tester.pumpAndSettle();

    expect(find.text('분석은 완료했지만 이력을 저장하지 못했어요.'), findsOneWidget);
    expect(store.entries, isEmpty);

    storage.failWrite = false;
    await tester.tap(find.text('저장 다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('분석 결과'), findsOneWidget);
    expect(store.entries.single.result.content, '안녕하세요');
    expect(ocr.calls, 1);
  });

  testWidgets('cancelling leaves the page and discards the late result', (
    tester,
  ) async {
    final store = await loadedStore();
    final gate = Completer<void>();
    final navigator = await pumpRoutedApp(
      tester,
      store: store,
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
    expect(store.entries, isEmpty);
    expect(find.text('분석 결과'), findsNothing);
  });
}
