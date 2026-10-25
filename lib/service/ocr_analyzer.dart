import 'image_input_service.dart';

abstract interface class OcrAnalyzer {
  Future<String> recognize(ImageInput input);
}

class OcrUnavailableException implements Exception {
  const OcrUnavailableException(this.message);

  final String message;
}

/// Used until Google ML Kit OCR is configured for Android and iOS.
class UnavailableOcrAnalyzer implements OcrAnalyzer {
  const UnavailableOcrAnalyzer();

  @override
  Future<String> recognize(ImageInput input) {
    throw const OcrUnavailableException(
      'Google ML Kit 텍스트 인식 기능이 아직 연결되지 않았습니다.',
    );
  }
}
