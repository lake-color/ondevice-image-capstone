import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/exceptions.dart';
import 'image_input_service.dart';

// Bundled MobileNetV3 Small: 224x224 RGB float32 in, 1001 ImageNet logits out
// (index 0 is "background").
const classificationInputSize = 224;
const classificationLabelCount = 1001;

class ClassificationOutput {
  const ClassificationOutput({required this.label, required this.confidence});
  final String label;
  final double confidence;
}

/// Classifies a photo with the bundled model.
///
/// Flow: load assets (cached) -> background isolate -> preprocess -> inference
/// -> postprocess. Each step below is its own top-level function.
class MobileNetClassifier {
  static const modelAsset = 'assets/models/mobilenet_v3_small.tflite';
  static const labelsAsset = 'assets/models/imagenet_labels.txt';
  Future<(Uint8List, List<String>)>? _assets;

  Future<(Uint8List, List<String>)> _loadAssets() async {
    try {
      final model = await rootBundle.load(modelAsset);
      final labels = parseClassificationLabels(
        await rootBundle.loadString(labelsAsset),
      );
      return (
        model.buffer.asUint8List(model.offsetInBytes, model.lengthInBytes),
        labels,
      );
    } catch (_) {
      _assets = null;
      throw const AnalysisException('분류 모델을 불러오지 못했습니다. 앱을 다시 실행해 주세요.');
    }
  }

  Future<ClassificationOutput> classify(ImageInput input) async {
    try {
      final (model, labels) = await (_assets ??= _loadAssets());
      return await compute(_classify, (model, labels, input.path));
    } on AnalysisException {
      rethrow;
    } catch (_) {
      throw const AnalysisException('사진을 분류하지 못했습니다. 다른 사진으로 다시 시도해 주세요.');
    }
  }
}

// Isolate entry point. Decoding, native allocation and inference all happen
// off the UI isolate.
ClassificationOutput _classify((Uint8List, List<String>, String) request) {
  final (model, labels, path) = request;
  final file = File(path);
  if (file.lengthSync() > 32 * 1024 * 1024) {
    throw const AnalysisException('사진 파일이 너무 큽니다. 32MB 이하 사진을 선택해 주세요.');
  }
  final input = prepareClassificationInput(file.readAsBytesSync());
  final logits = _runInference(model, input);
  return decodeClassificationOutput(logits, labels);
}

List<String> parseClassificationLabels(String source) {
  final labels = source.trim().split(RegExp(r'\r?\n'));
  if (labels.length != classificationLabelCount ||
      labels.first != 'background' ||
      labels.any((label) => label.trim().isEmpty)) {
    throw const AnalysisException('분류 모델의 라벨 구성이 올바르지 않습니다.');
  }
  return labels;
}

/// Preprocessing: decode, apply EXIF orientation, center-crop, resize and
/// normalize. The bundled model metadata specifies mean=0, std=255, RGB float32.
Float32List prepareClassificationInput(Uint8List encoded) {
  final decoder = img.findDecoderForData(encoded);
  final info = decoder?.startDecode(encoded);
  if (info == null) {
    throw const AnalysisException(
      '지원하지 않거나 손상된 사진입니다. JPG 또는 PNG 사진으로 다시 시도해 주세요.',
    );
  }
  if (info.width * info.height > 40000000) {
    throw const AnalysisException('사진 해상도가 너무 큽니다. 4천만 화소 이하 사진을 선택해 주세요.');
  }
  final decoded = decoder!.decodeFrame(0);
  if (decoded == null) {
    throw const AnalysisException('사진을 읽지 못했습니다. 다른 사진으로 다시 시도해 주세요.');
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

/// Inference: each request owns its interpreter, and native resources are
/// always released, including when the model does not match the expected spec.
List<double> _runInference(Uint8List model, Float32List input) {
  final options = InterpreterOptions()..threads = 2;
  Interpreter? interpreter;
  try {
    interpreter = Interpreter.fromBuffer(model, options: options);
    final inputs = interpreter.getInputTensors();
    final outputs = interpreter.getOutputTensors();
    if (inputs.length != 1 ||
        outputs.length != 1 ||
        inputs.single.type != TensorType.float32 ||
        outputs.single.type != TensorType.float32 ||
        !listEquals(inputs.single.shape, [
          1,
          classificationInputSize,
          classificationInputSize,
          3,
        ]) ||
        !listEquals(outputs.single.shape, [1, classificationLabelCount])) {
      throw const AnalysisException('분류 모델의 입력·출력 사양이 올바르지 않습니다.');
    }
    final output = [List<double>.filled(classificationLabelCount, 0)];
    interpreter.run(input.buffer, output);
    return output.single;
  } finally {
    interpreter?.close();
    options.delete();
  }
}

/// Postprocessing: validate the logits, pick the best class and convert its
/// score to a softmax probability. The model's label is returned unchanged.
ClassificationOutput decodeClassificationOutput(
  List<double> logits,
  List<String> labels,
) {
  if (logits.length != classificationLabelCount ||
      labels.length != logits.length ||
      logits.any((value) => !value.isFinite)) {
    throw const AnalysisException('분류 결과를 읽지 못했습니다. 다시 시도해 주세요.');
  }
  var best = 0;
  for (var i = 1; i < logits.length; i++) {
    if (logits[i] > logits[best]) best = i;
  }
  if (best == 0) {
    throw const AnalysisException('뚜렷한 사물을 찾지 못했습니다. 사물이 중앙에 보이는 사진을 선택해 주세요.');
  }
  final maximum = logits[best];
  final denominator = logits.fold<double>(
    0,
    (sum, value) => sum + math.exp(value - maximum),
  );
  return ClassificationOutput(label: labels[best], confidence: 1 / denominator);
}
