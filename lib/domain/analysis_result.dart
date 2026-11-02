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
    this.imagePath,
  });

  final AnalysisMethod method;
  final String sourceName;
  final String title;
  final String content;
  final Duration duration;
  final DateTime createdAt;
  final double? confidence;

  /// Only used for the current preview; never serialized into history.
  final String? imagePath;

  Map<String, Object?> toJson() => {
    'method': method.name,
    'sourceName': sourceName,
    'title': title,
    'content': content,
    'durationMicroseconds': duration.inMicroseconds,
    'createdAt': createdAt.toIso8601String(),
    'confidence': confidence,
  };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      method: AnalysisMethod.values.byName(json['method'] as String),
      sourceName: json['sourceName'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      duration: Duration(microseconds: json['durationMicroseconds'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  String get shareText {
    final confidenceText = confidence == null
        ? ''
        : '\n신뢰도: ${(confidence! * 100).toStringAsFixed(1)}%';
    return '$title\n$content$confidenceText\n분석 시간: ${duration.inMilliseconds}ms';
  }
}
