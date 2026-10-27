import 'image_input_service.dart';

class ClassificationOutput {
  const ClassificationOutput({required this.label, required this.confidence});
  final String label;
  final double confidence;
}

abstract interface class ImageClassifier {
  Future<ClassificationOutput> classify(ImageInput input);
}

class ClassificationException implements Exception {
  const ClassificationException(this.message);
  final String message;
  @override
  String toString() => message;
}
