import 'package:flutter/foundation.dart';

import '../domain/analysis_history.dart';
import '../domain/analysis_result.dart';

/// Storage boundary used by the UI. A persistent implementation can replace
/// this class without changing the pages.
class AnalysisHistoryStore extends ChangeNotifier {
  final List<AnalysisHistory> _entries = <AnalysisHistory>[];

  List<AnalysisHistory> get entries => List.unmodifiable(_entries);

  Future<void> add(AnalysisResult result) async {
    _entries.insert(0, AnalysisHistory.fromResult(result));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  Future<void> clear() async {
    _entries.clear();
    notifyListeners();
  }
}
