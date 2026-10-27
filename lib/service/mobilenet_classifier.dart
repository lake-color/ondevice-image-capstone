import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'classification_processing.dart';
import 'image_classifier.dart';
import 'image_input_service.dart';

class MobileNetClassifier implements ImageClassifier {
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
      throw const ClassificationException('분류 모델을 불러오지 못했습니다. 앱을 다시 실행해 주세요.');
    }
  }

  @override
  Future<ClassificationOutput> classify(ImageInput input) async {
    try {
      final (model, labels) = await (_assets ??= _loadAssets());
      return await compute(_classify, (model, labels, input.path));
    } on ClassificationException {
      rethrow;
    } catch (_) {
      throw const ClassificationException(
        '사진을 분류하지 못했습니다. 다른 사진으로 다시 시도해 주세요.',
      );
    }
  }
}

// Each request owns its interpreter. All decoding, native allocation and
// inference happen off the UI isolate; native resources are always released.
ClassificationOutput _classify((Uint8List, List<String>, String) request) {
  final (model, labels, path) = request;
  final file = File(path);
  if (file.lengthSync() > 32 * 1024 * 1024) {
    throw const ClassificationException('사진 파일이 너무 큽니다. 32MB 이하 사진을 선택해 주세요.');
  }
  final input = prepareClassificationInput(file.readAsBytesSync());
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
        !listEquals(inputs.single.shape, [1, 224, 224, 3]) ||
        !listEquals(outputs.single.shape, [1, classificationLabelCount])) {
      throw const ClassificationException('분류 모델의 입력·출력 사양이 올바르지 않습니다.');
    }
    final output = [List<double>.filled(classificationLabelCount, 0)];
    interpreter.run(input.buffer, output);
    return decodeClassificationOutput(output.single, labels);
  } finally {
    interpreter?.close();
    options.delete();
  }
}
