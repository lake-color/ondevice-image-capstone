import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/app/app_theme.dart';
import 'package:ondevice_image_capstone/data/analysis_history_store.dart';
import 'package:ondevice_image_capstone/data/history_storage.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/page/analysis_page.dart';
import 'package:ondevice_image_capstone/page/history_page.dart';
import 'package:ondevice_image_capstone/page/result_page.dart';
import 'package:ondevice_image_capstone/service/analysis_service.dart';
import 'package:ondevice_image_capstone/service/image_classifier.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';
import 'package:ondevice_image_capstone/service/ocr_analyzer.dart';
import 'package:ondevice_image_capstone/service/share_service.dart';

class FakeOcr implements OcrAnalyzer {
  @override
  Future<String> recognize(ImageInput input) async => input.name;
}

void main() {
  testWidgets('delete confirmation stays horizontal on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AnalysisHistoryStore(storage: MemoryHistoryStorage());
    addTearDown(store.dispose);
    await store.load();
    await store.add(
      await AnalysisService(FakeOcr(), FakeClassifier()).analyze(
        const AnalysisRequest(
          method: AnalysisMethod.ocr,
          input: ImageInput(name: 'text.jpg', path: '/tmp/text.jpg'),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HistoryPage(
          historyStore: store,
          shareService: ClipboardShareService(),
        ),
      ),
    );
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    final cancel = find.widgetWithText(TextButton, '취소');
    final delete = find.widgetWithText(FilledButton, '삭제');
    expect(
      tester.getCenter(cancel).dy,
      closeTo(tester.getCenter(delete).dy, 1),
    );
    expect(tester.getCenter(cancel).dx, lessThan(tester.getCenter(delete).dx));
    expect(tester.takeException(), isNull);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(store.entries, hasLength(1));
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(store.entries, isEmpty);
  });
  testWidgets('analysis buttons are dimmed and disabled without a photo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AnalysisPage(inputService: FakeImageInputService()),
      ),
    );
    for (final title in ['사물 분석', '텍스트 분석']) {
      final button = find.ancestor(
        of: find.text(title),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(button).onTap, isNull);
      final opacity = find.ancestor(of: button, matching: find.byType(Opacity));
      expect(tester.widget<Opacity>(opacity).opacity, 0.4);
    }
  });

  testWidgets(
    'consecutive results show their own input and do not persist paths',
    (tester) async {
      final service = AnalysisService(FakeOcr(), FakeClassifier());
      for (final name in ['first.jpg', 'second.jpg']) {
        final result = await service.analyze(
          AnalysisRequest(
            method: AnalysisMethod.ocr,
            input: ImageInput(name: name, path: '/tmp/$name'),
          ),
        );
        expect(result.imagePath, '/tmp/$name');
        expect(result.toJson().containsKey('imagePath'), isFalse);
        await tester.pumpWidget(
          MaterialApp(
            home: ResultPage(
              result: result,
              shareService: ClipboardShareService(),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image));
        expect((image.image as FileImage).file.path, File('/tmp/$name').path);
        await tester.pumpAndSettle();
      }
    },
  );
}

class FakeClassifier implements ImageClassifier {
  @override
  Future<ClassificationOutput> classify(ImageInput input) async =>
      const ClassificationOutput(label: 'cat', confidence: 0.9);
}

class FakeImageInputService implements ImageInputService {
  @override
  Future<ImageInput?> pick(ImageSourceType source) async => null;
}

class MemoryHistoryStorage implements HistoryStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {}
}
