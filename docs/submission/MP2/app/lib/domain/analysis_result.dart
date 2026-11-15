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

  /// Only used to show the photo next to this result; never saved.
  final String? imagePath;
}
