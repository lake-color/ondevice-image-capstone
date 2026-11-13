import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/domain/analysis_result.dart';

void main() {
  final classification = AnalysisResult(
    method: AnalysisMethod.imageClassification,
    sourceName: 'cat.jpg',
    title: '분류 결과',
    content: 'tabby',
    duration: const Duration(milliseconds: 615),
    createdAt: DateTime.utc(2026, 11, 14, 3, 13),
    confidence: 0.306,
    imagePath: '/data/cache/cat.jpg',
  );

  test('JSON keeps the stored fields and never the photo path', () {
    expect(classification.toJson().keys.toSet(), {
      'method',
      'sourceName',
      'title',
      'content',
      'durationMicroseconds',
      'createdAt',
      'confidence',
    });

    final restored = AnalysisResult.fromJson(classification.toJson());
    expect(restored.toJson(), classification.toJson());
    expect(restored.imagePath, isNull);
  });

  test('a history entry written by an earlier build still loads', () {
    final restored = AnalysisResult.fromJson({
      'method': 'ocr',
      'sourceName': 'text.png',
      'title': '인식된 텍스트',
      'content': '안녕하세요',
      'durationMicroseconds': 684000,
      'createdAt': '2026-10-30T09:19:00.000Z',
      'confidence': null,
    });

    expect(restored.method, AnalysisMethod.ocr);
    expect(restored.content, '안녕하세요');
    expect(restored.duration, const Duration(milliseconds: 684));
    expect(restored.createdAt, DateTime.utc(2026, 10, 30, 9, 19));
    expect(restored.confidence, isNull);
  });

  test('share text includes confidence only for classification', () {
    expect(classification.shareText, '분류 결과\ntabby\n신뢰도: 30.6%\n분석 시간: 615ms');

    final ocr = AnalysisResult(
      method: AnalysisMethod.ocr,
      sourceName: 'text.png',
      title: '인식된 텍스트',
      content: '안녕하세요',
      duration: const Duration(milliseconds: 684),
      createdAt: DateTime.utc(2026, 11, 14),
    );
    expect(ocr.shareText, '인식된 텍스트\n안녕하세요\n분석 시간: 684ms');
  });
}
