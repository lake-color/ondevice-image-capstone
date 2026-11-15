import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/domain/exceptions.dart';
import 'package:ondevice_image_capstone/service/analysis_service.dart';

import '../support/fakes.dart';

void main() {
  test('OCR requests run only the OCR analyzer', () async {
    final ocr = FakeOcr(text: '안녕하세요');
    final classifier = FakeClassifier();
    final before = DateTime.now();

    final result = await AnalysisService(ocr, classifier).analyze(
      const AnalysisRequest(method: AnalysisMethod.ocr, input: sampleInput),
    );

    expect(ocr.calls, 1);
    expect(classifier.calls, 0);
    expect(result.method, AnalysisMethod.ocr);
    expect(result.title, '인식된 텍스트');
    expect(result.content, '안녕하세요');
    expect(result.confidence, isNull);
    expect(result.sourceName, sampleInput.name);
    expect(result.imagePath, sampleInput.path);
    expect(result.duration, greaterThanOrEqualTo(Duration.zero));
    expect(result.createdAt.isBefore(before), isFalse);
  });

  test('classification requests run only the classifier', () async {
    final ocr = FakeOcr();
    final classifier = FakeClassifier(label: 'tabby', confidence: 0.42);

    final result = await AnalysisService(ocr, classifier).analyze(
      const AnalysisRequest(
        method: AnalysisMethod.imageClassification,
        input: sampleInput,
      ),
    );

    expect(ocr.calls, 0);
    expect(classifier.calls, 1);
    expect(result.method, AnalysisMethod.imageClassification);
    expect(result.title, '분류 결과');
    expect(result.content, 'tabby');
    expect(result.confidence, 0.42);
  });

  test('the model label and confidence are reported unchanged', () async {
    // No label is translated or replaced, including the apple cultivar class.
    for (final label in ['Granny Smith', 'pomegranate', 'Egyptian cat']) {
      final result =
          await AnalysisService(
            FakeOcr(),
            FakeClassifier(label: label, confidence: 0.789),
          ).analyze(
            const AnalysisRequest(
              method: AnalysisMethod.imageClassification,
              input: sampleInput,
            ),
          );

      expect(result.content, label);
      expect(result.confidence, 0.789);
    }
  });

  test('analyzer failures reach the caller as they were thrown', () async {
    const failure = AnalysisException('사진에서 인식할 텍스트를 찾지 못했습니다.');
    final service = AnalysisService(FakeOcr(error: failure), FakeClassifier());

    await expectLater(
      service.analyze(
        const AnalysisRequest(method: AnalysisMethod.ocr, input: sampleInput),
      ),
      throwsA(same(failure)),
    );
  });
}
