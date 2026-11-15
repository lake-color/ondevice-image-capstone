import 'analysis_result.dart';

/// A lightweight history entry. The original image is intentionally omitted.
class AnalysisHistory {
  const AnalysisHistory({required this.id, required this.result});

  final String id;
  final AnalysisResult result;
}
