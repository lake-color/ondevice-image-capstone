import 'image_input_service.dart';

class ClassificationOutput {
  const ClassificationOutput({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

abstract interface class TextAnalyzer {
  Future<ClassificationOutput> classify(ImageInput input);
}

class ClassificationUnavailableException implements Exception {
  const ClassificationUnavailableException(this.message);

  final String message;
}

/// Used until a LiteRT-compatible MobileNetV3 model is bundled.
class UnavailableTextAnalyzer implements TextAnalyzer {
  const UnavailableTextAnalyzer();

  @override
  Future<ClassificationOutput> classify(ImageInput input) {
    throw const ClassificationUnavailableException(
      'LiteRT MobileNetV3 모델이 아직 준비되지 않았습니다.',
    );
  }
}
