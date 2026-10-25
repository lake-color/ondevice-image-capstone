import 'analysis_result.dart';

/// A lightweight history entry. The original image is intentionally omitted.
class AnalysisHistory {
  const AnalysisHistory({required this.id, required this.result});

  factory AnalysisHistory.fromResult(AnalysisResult result) {
    return AnalysisHistory(
      id: result.createdAt.microsecondsSinceEpoch.toString(),
      result: result,
    );
  }

  final String id;
  final AnalysisResult result;
}
