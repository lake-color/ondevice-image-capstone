import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/analysis_result.dart';

/// Opens the OS share sheet with the result text.
///
/// The sheet itself is the user feedback, so only failures are reported.
Future<void> shareResult(BuildContext context, AnalysisResult result) async {
  final messenger = ScaffoldMessenger.of(context);
  // iPad presents the sheet as a popover and requires an anchor rectangle.
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null || !box.hasSize
      ? null
      : box.localToGlobal(Offset.zero) & box.size;
  try {
    await SharePlus.instance.share(
      ShareParams(text: result.shareText, sharePositionOrigin: origin),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('공유 화면을 열지 못했습니다. 다시 시도해 주세요.')),
    );
  }
}
