import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ondevice_image_capstone/service/classification_processing.dart';
import 'package:ondevice_image_capstone/service/image_classifier.dart';

void main() {
  final labels = parseClassificationLabels(
    File('assets/models/imagenet_labels.txt').readAsStringSync(),
  );

  test('bundled labels preserve background and class indices', () {
    expect(labels, hasLength(1001));
    expect(labels[1], 'tench');
    expect(labels[2], 'goldfish');
    expect(
      () => parseClassificationLabels('tench\ngoldfish'),
      throwsA(isA<ClassificationException>()),
    );
  });

  test('RGB input uses 0..1 normalization and NHWC channel order', () {
    final image = img.Image(width: 3, height: 3);
    img.fill(image, color: img.ColorRgb8(255, 128, 0));
    final input = prepareClassificationInput(img.encodePng(image));
    expect(input, hasLength(224 * 224 * 3));
    expect(input[0], 1);
    expect(input[1], closeTo(128 / 255, 1e-7));
    expect(input[2], 0);
    expect(input[input.length - 2], closeTo(128 / 255, 1e-7));
  });

  test('non-square images use center crop', () {
    final image = img.Image(width: 6, height: 2);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    for (var y = 0; y < 2; y++) {
      for (var x = 2; x < 4; x++) {
        image.setPixelRgb(x, y, 0, 255, 0);
      }
    }
    final input = prepareClassificationInput(img.encodePng(image));
    expect(input.take(3), [0, 1, 0]);
    expect(input.skip(input.length - 3), [0, 1, 0]);
  });

  test('JPEG EXIF orientation rotates the image before inference', () {
    final image = img.Image(width: 32, height: 32);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        image.setPixelRgb(x, y, y < 16 ? 255 : 0, 0, y < 16 ? 0 : 255);
      }
    }
    image.exif.imageIfd.orientation = 6;
    final input = prepareClassificationInput(
      img.encodeJpg(image, quality: 100),
    );
    // 90 degrees clockwise: bottom blue becomes the left half.
    final left = (112 * 224 + 20) * 3;
    final right = (112 * 224 + 200) * 3;
    expect(input[left + 2], greaterThan(0.9));
    expect(input[right], greaterThan(0.9));
  });

  test('damaged and unsupported images return an actionable error', () {
    expect(
      () => prepareClassificationInput(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<ClassificationException>()),
    );
  });

  test(
    'stable softmax includes background and retains the exact label index',
    () {
      final logits = List<double>.filled(1001, 10000);
      logits[2] = 10002;
      final output = decodeClassificationOutput(logits, labels);
      expect(output.label, 'goldfish');
      expect(output.confidence, closeTo(1 / (1 + 1000 * math.exp(-2)), 1e-12));
    },
  );

  test('invalid logits and background winners are not shown as objects', () {
    final logits = List<double>.filled(1001, 0);
    expect(
      () => decodeClassificationOutput(logits, labels),
      throwsA(isA<ClassificationException>()),
    );
    logits[1] = double.nan;
    expect(
      () => decodeClassificationOutput(logits, labels),
      throwsA(isA<ClassificationException>()),
    );
    expect(
      () => decodeClassificationOutput([1], labels),
      throwsA(isA<ClassificationException>()),
    );
  });
}
