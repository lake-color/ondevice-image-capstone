import 'package:flutter/services.dart';

import '../domain/analysis_result.dart';

abstract interface class ShareService {
  Future<void> share(AnalysisResult result);
}

/// Copies a result without requiring an external share plugin.
class ClipboardShareService implements ShareService {
  @override
  Future<void> share(AnalysisResult result) {
    return Clipboard.setData(ClipboardData(text: result.shareText));
  }
}
