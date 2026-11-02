import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'image_input_service.dart';

abstract interface class OcrAnalyzer {
  Future<String> recognize(ImageInput input);
}

class OcrUnavailableException implements Exception {
  const OcrUnavailableException(this.message);

  final String message;
}

class OcrRecognitionException implements Exception {
  const OcrRecognitionException(this.message);

  final String message;
}

class MlKitOcrAnalyzer implements OcrAnalyzer {
  const MlKitOcrAnalyzer();

  @override
  Future<String> recognize(ImageInput input) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final image = InputImage.fromFilePath(input.path);
      final result = await recognizer.processImage(image);
      final text = result.text.trim();
      if (text.isEmpty) {
        throw const OcrRecognitionException('사진에서 인식할 텍스트를 찾지 못했습니다.');
      }
      return text;
    } on OcrRecognitionException {
      rethrow;
    } catch (_) {
      throw const OcrRecognitionException(
        '텍스트를 인식하지 못했습니다. 다른 사진으로 다시 시도해 주세요.',
      );
    } finally {
      await recognizer.close();
    }
  }
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
