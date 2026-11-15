import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/domain/exceptions.dart';
import 'package:ondevice_image_capstone/service/analysis_service.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';
import 'package:ondevice_image_capstone/service/mobilenet_classifier.dart';
import 'package:ondevice_image_capstone/service/ocr_analyzer.dart';
import 'package:path_provider/path_provider.dart';

// Measures the same duration the result page shows: the time spent inside
// AnalysisService.analyze. Fixtures are drawn on the device, so the run needs
// no network and no photo.

const runs = 10;

/// Draws [text] on a white 1200x800 canvas and saves it as a PNG.
Future<ImageInput> drawFixture(String name, String text) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF000000),
        fontSize: 56,
        height: 1.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 1100);
  painter.paint(canvas, const Offset(50, 50));
  final picture = recorder.endRecording();
  final image = await picture.toImage(1200, 800);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$name.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  addTearDown(() => file.delete());
  image.dispose();
  picture.dispose();
  painter.dispose();
  return ImageInput(name: '$name.png', path: file.path);
}

void report(String label, List<int> milliseconds) {
  final sorted = [...milliseconds]..sort();
  final mean = milliseconds.reduce((a, b) => a + b) / milliseconds.length;
  // ignore: avoid_print
  print(
    'TIMING $label: runs=$milliseconds ms, first=${milliseconds.first} ms, '
    'mean=${mean.toStringAsFixed(1)} ms, min=${sorted.first} ms, '
    'max=${sorted.last} ms',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final service = AnalysisService(
    const MlKitOcrAnalyzer(),
    MobileNetClassifier(),
  );

  testWidgets('text recognition time over repeated runs', (tester) async {
    final input = await drawFixture(
      'timing_text',
      '온디바이스 텍스트 인식\n처리 시간 측정\nOn-device OCR 2026\n사진은 서버로 전송하지 않습니다',
    );
    final times = <int>[];
    for (var i = 0; i < runs; i++) {
      final result = await service.analyze(
        AnalysisRequest(method: AnalysisMethod.ocr, input: input),
      );
      expect(result.content, contains('처리 시간 측정'));
      times.add(result.duration.inMilliseconds);
    }
    report('ocr', times);
  });

  testWidgets('a photo without text is reported as unrecognisable', (
    tester,
  ) async {
    final input = await drawFixture('timing_blank', '');
    final stopwatch = Stopwatch()..start();
    await expectLater(
      service.analyze(
        AnalysisRequest(method: AnalysisMethod.ocr, input: input),
      ),
      throwsA(isA<AnalysisException>()),
    );
    report('ocr-no-text', [stopwatch.elapsedMilliseconds]);
  });

  testWidgets('object classification time over repeated runs', (tester) async {
    final input = await drawFixture('timing_object', 'A');
    final times = <int>[];
    for (var i = 0; i < runs; i++) {
      final result = await service.analyze(
        AnalysisRequest(
          method: AnalysisMethod.imageClassification,
          input: input,
        ),
      );
      times.add(result.duration.inMilliseconds);
    }
    report('classification', times);
  });
}
