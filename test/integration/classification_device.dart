import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:ondevice_image_capstone/service/image_classifier.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';
import 'package:ondevice_image_capstone/service/mobilenet_classifier.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'bundled model executes in a worker and releases native resources',
    (tester) async {
      final directory = await getTemporaryDirectory();
      final fixture = File('${directory.path}/classification_smoke.png');
      final image = img.Image(width: 224, height: 224);
      img.fill(image, color: img.ColorRgb8(200, 100, 30));
      await fixture.writeAsBytes(img.encodePng(image));
      addTearDown(() => fixture.delete());
      final classifier = MobileNetClassifier();
      final input = ImageInput(name: 'smoke.png', path: fixture.path);
      final first = await classifier.classify(input);
      final second = await classifier.classify(input);
      expect(first.label, isNotEmpty);
      expect(first.confidence, inExclusiveRange(0, 1));
      expect(second.label, first.label);
      expect(second.confidence, closeTo(first.confidence, 1e-5));
      // ignore: avoid_print
      print('MobileNetV3 native smoke: ${first.label} (${first.confidence})');
      await fixture.writeAsBytes([1, 2, 3]);
      await expectLater(
        classifier.classify(input),
        throwsA(isA<ClassificationException>()),
      );
    },
  );
}
