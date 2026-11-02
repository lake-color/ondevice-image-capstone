import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';
import 'package:ondevice_image_capstone/service/mobilenet_classifier.dart';
import 'package:ondevice_image_capstone/service/ocr_analyzer.dart';
import 'package:path_provider/path_provider.dart';

// Network access is only used to obtain validation fixtures, never for inference.
const photoUrls = {
  'cat': 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg',
  'apple': 'https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg',
};

ImageInput input(String path) =>
    ImageInput(name: path.split('/').last, path: path);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'natural cat and apple photos run through native classification',
    (tester) async {
      final classifier = MobileNetClassifier();
      final directory = await getTemporaryDirectory();
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      for (final name in ['cat', 'apple']) {
        final request = await client.getUrl(Uri.parse(photoUrls[name]!));
        final response = await request.close();
        expect(response.statusCode, 200);
        final file = File('${directory.path}/quality_$name.jpg');
        await response.pipe(file.openWrite());
        addTearDown(() => file.delete());
        final result = await classifier.classify(input(file.path));
        // ignore: avoid_print
        print(
          'QUALITY $name: ${result.label}, confidence=${result.confidence}',
        );
        expect(result.confidence, inInclusiveRange(0, 1));
        if (name == 'cat') {
          expect(
            result.label,
            isIn([
              'tabby',
              'tiger cat',
              'Persian cat',
              'Siamese cat',
              'Egyptian cat',
            ]),
          );
        } else {
          // ImageNet has one apple class: this is not proof of the cultivar.
          expect(result.label, 'Granny Smith');
        }
      }
    },
  );

  testWidgets('native Korean OCR recognizes mixed Korean and English', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final painter = TextPainter(
      text: const TextSpan(
        text: '안녕하세요\n사과와 고양이\nHello World 123',
        style: TextStyle(color: Color(0xFF000000), fontSize: 64, height: 1.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 1100);
    painter.paint(canvas, const Offset(50, 50));
    final picture = recorder.endRecording();
    final image = await picture.toImage(1200, 500);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/mixed_ocr.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    addTearDown(() => file.delete());
    image.dispose();
    picture.dispose();
    painter.dispose();
    final text = await const MlKitOcrAnalyzer().recognize(input(file.path));
    // ignore: avoid_print
    print('QUALITY OCR: $text');
    expect(text, contains('안녕하세요'));
    expect(text, contains('사과와 고양이'));
    expect(text, contains('Hello World 123'));
  });
}
