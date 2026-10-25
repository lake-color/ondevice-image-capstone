import 'analysis_method.dart';

/// Immutable output of a single analysis operation.
class AnalysisResult {
  const AnalysisResult({
    required this.method,
    required this.sourceName,
    required this.title,
    required this.content,
    required this.duration,
    required this.createdAt,
    this.confidence,
  });

  final AnalysisMethod method;
  final String sourceName;
  final String title;
  final String content;
  final Duration duration;
  final DateTime createdAt;
  final double? confidence;

  String get shareText {
    final confidenceText = confidence == null
        ? ''
        : '\n신뢰도: ${(confidence! * 100).toStringAsFixed(1)}%';
    return '$title\n$content$confidenceText\n분석 시간: ${duration.inMilliseconds}ms';
  }
}
