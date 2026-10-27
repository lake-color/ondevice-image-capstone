import '../domain/analysis_method.dart';
import '../domain/analysis_result.dart';
import 'image_input_service.dart';
import 'ocr_analyzer.dart';
import 'image_classifier.dart';

class AnalysisRequest {
  const AnalysisRequest({required this.method, required this.input});

  final AnalysisMethod method;
  final ImageInput input;
}

class AnalysisService {
  const AnalysisService(this._ocr, this._classifier);

  final OcrAnalyzer _ocr;
  final ImageClassifier _classifier;

  Future<AnalysisResult> analyze(AnalysisRequest request) async {
    final stopwatch = Stopwatch()..start();

    final (title, content, confidence) = switch (request.method) {
      AnalysisMethod.ocr => (
        '인식된 텍스트',
        await _ocr.recognize(request.input),
        null,
      ),
      AnalysisMethod.imageClassification => await _classify(request.input),
    };

    stopwatch.stop();
    return AnalysisResult(
      method: request.method,
      sourceName: request.input.name,
      title: title,
      content: content,
      confidence: confidence,
      duration: stopwatch.elapsed,
      createdAt: DateTime.now(),
    );
  }

  Future<(String, String, double?)> _classify(ImageInput input) async {
    final output = await _classifier.classify(input);
    return ('분류 결과', output.label, output.confidence);
  }
}
