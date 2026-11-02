import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'image_classifier.dart';

const classificationInputSize = 224;
const classificationLabelCount = 1001;

List<String> parseClassificationLabels(String source) {
  final labels = source.trim().split(RegExp(r'\r?\n'));
  if (labels.length != classificationLabelCount ||
      labels.first != 'background' ||
      labels.any((label) => label.trim().isEmpty)) {
    throw const ClassificationException('분류 모델의 라벨 구성이 올바르지 않습니다.');
  }
  return labels;
}

/// The bundled model metadata specifies mean=0, std=255, RGB float32.
Float32List prepareClassificationInput(Uint8List encoded) {
  final decoder = img.findDecoderForData(encoded);
  final info = decoder?.startDecode(encoded);
  if (info == null) {
    throw const ClassificationException(
      '지원하지 않거나 손상된 사진입니다. JPG 또는 PNG 사진으로 다시 시도해 주세요.',
    );
  }
  if (info.width * info.height > 40000000) {
    throw const ClassificationException(
      '사진 해상도가 너무 큽니다. 4천만 화소 이하 사진을 선택해 주세요.',
    );
  }
  final decoded = decoder!.decodeFrame(0);
  if (decoded == null) {
    throw const ClassificationException('사진을 읽지 못했습니다. 다른 사진으로 다시 시도해 주세요.');
  }
  final oriented = img.bakeOrientation(decoded);
  final side = math.min(oriented.width, oriented.height);
  final cropped = img.copyCrop(
    oriented,
    x: (oriented.width - side) ~/ 2,
    y: (oriented.height - side) ~/ 2,
    width: side,
    height: side,
  );
  // Match the white preview background instead of discarding alpha and
  // feeding invisible RGB values to the classifier.
  final rgb = img.Image(width: side, height: side, numChannels: 3);
  img.fill(rgb, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(rgb, cropped);
  final resized = img.copyResize(
    rgb,
    width: classificationInputSize,
    height: classificationInputSize,
    interpolation: img.Interpolation.linear,
  );
  final values = Float32List(
    classificationInputSize * classificationInputSize * 3,
  );
  var offset = 0;
  for (final pixel in resized) {
    values[offset++] = pixel.r / 255.0;
    values[offset++] = pixel.g / 255.0;
    values[offset++] = pixel.b / 255.0;
  }
  return values;
}

ClassificationOutput decodeClassificationOutput(
  List<double> logits,
  List<String> labels,
) {
  if (logits.length != classificationLabelCount ||
      labels.length != logits.length ||
      logits.any((value) => !value.isFinite)) {
    throw const ClassificationException('분류 결과를 읽지 못했습니다. 다시 시도해 주세요.');
  }
  var best = 0;
  for (var i = 1; i < logits.length; i++) {
    if (logits[i] > logits[best]) best = i;
  }
  if (best == 0) {
    throw const ClassificationException(
      '뚜렷한 사물을 찾지 못했습니다. 사물이 중앙에 보이는 사진을 선택해 주세요.',
    );
  }
  final maximum = logits[best];
  final denominator = logits.fold<double>(
    0,
    (sum, value) => sum + math.exp(value - maximum),
  );
  return ClassificationOutput(label: labels[best], confidence: 1 / denominator);
}
