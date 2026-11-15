import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/app/app_theme.dart';
import 'package:ondevice_image_capstone/data/analysis_history_store.dart';
import 'package:ondevice_image_capstone/page/history_page.dart';
import 'package:ondevice_image_capstone/page/notice_card.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';

Future<void> pumpHistory(
  WidgetTester tester,
  AnalysisHistoryStore store, {
  Size size = const Size(800, 1400),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: HistoryPage(historyStore: store),
    ),
  );
  await tester.pumpAndSettle();
}

FilledButton shareButton(WidgetTester tester) =>
    tester.widget(find.widgetWithText(FilledButton, '결과 공유하기'));

void main() {
  testWidgets('entries are listed newest first with their details', (
    tester,
  ) async {
    final store = await loadedStore();
    await store.add(sampleResult('안녕하세요'));
    await store.add(sampleResult('tabby', confidence: 0.95));
    await pumpHistory(tester, store);

    expect(find.text('tabby'), findsOneWidget);
    expect(find.text('신뢰도 95% · 0.12초'), findsOneWidget);
    expect(find.text('안녕하세요'), findsOneWidget);
    expect(find.text('0.12초'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('tabby')).dy,
      lessThan(tester.getTopLeft(find.text('안녕하세요')).dy),
    );
  });

  testWidgets('delete asks first, and only confirming removes the entry', (
    tester,
  ) async {
    final store = await loadedStore();
    await store.add(sampleResult('안녕하세요'));
    // A narrow phone: the two dialog buttons must still sit side by side.
    await pumpHistory(tester, store, size: const Size(320, 700));

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    final cancel = find.widgetWithText(TextButton, '취소');
    final confirm = find.widgetWithText(FilledButton, '삭제');
    expect(find.text('이 기록을 삭제할까요?'), findsOneWidget);
    expect(
      tester.getCenter(cancel).dy,
      closeTo(tester.getCenter(confirm).dy, 1),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(store.entries, hasLength(1));

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(store.entries, isEmpty);
    expect(find.text('안녕하세요'), findsNothing);
  });

  testWidgets('a delete that cannot be saved keeps the entry and says so', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final store = await loadedStore(storage);
    await store.add(sampleResult('안녕하세요'));
    await pumpHistory(tester, store);

    storage.failWrite = true;
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('이력을 저장하지 못했어요. 저장 공간을 확인하고 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('안녕하세요'), findsOneWidget);
    expect(store.entries, hasLength(1));
  });

  testWidgets('empty history shows the notice card and disables sharing', (
    tester,
  ) async {
    await pumpHistory(tester, await loadedStore());

    expect(find.byType(NoticeCard), findsOneWidget);
    expect(find.text('빈이력'), findsOneWidget);
    expect(find.text('아직 분석 이력이 없어요'), findsOneWidget);
    expect(shareButton(tester).onPressed, isNull);
  });

  testWidgets('share sends the most recent entry to the OS share sheet', (
    tester,
  ) async {
    final calls = mockShareChannel(tester);
    final store = await loadedStore();
    await store.add(sampleResult('오래된 결과'));
    final latest = sampleResult('tabby', confidence: 0.95);
    await store.add(latest);
    await pumpHistory(tester, store);

    await tester.tap(find.text('결과 공유하기'));
    await tester.pumpAndSettle();

    expect((calls.single.arguments as Map)['text'], latest.shareText);
  });

  testWidgets('a history file that cannot be read offers a retry', (
    tester,
  ) async {
    final storage = MemoryStorage()..failRead = true;
    final store = await loadedStore(storage);
    await pumpHistory(tester, store);

    expect(find.text('저장된 이력을 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byType(NoticeCard), findsNothing);

    storage.failRead = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('아직 분석 이력이 없어요'), findsOneWidget);
  });
}
