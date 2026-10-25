import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../data/analysis_history_store.dart';
import '../service/analysis_service.dart';

const _analysisAsset = 'docs/design-references/이미지소스/분석 이미지.png';
const _cancelAsset = 'docs/design-references/이미지소스/분석 취소 이미지.png';

class LoadingPage extends StatefulWidget {
  const LoadingPage({
    super.key,
    required this.request,
    required this.analysisService,
    required this.historyStore,
  });

  final AnalysisRequest request;
  final AnalysisService analysisService;
  final AnalysisHistoryStore historyStore;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      final result = await widget.analysisService.analyze(widget.request);
      await widget.historyStore.add(result);
      if (!mounted) return;
      await Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: result,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: _error == null
                    ? _LoadingContent(onCancel: () => Navigator.pop(context))
                    : _AnalysisError(onClose: () => Navigator.pop(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEAE8FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('온디바이스 AI', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 22),
        Flexible(
          child: Image.asset(
            _analysisAsset,
            width: 310,
            fit: BoxFit.contain,
            semanticLabel: '사진을 분석하는 로봇',
          ),
        ),
        const SizedBox(height: 20),
        Text('사진을 분석하고 있어요', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(
          '기기 안에서 처리 중입니다.\n사진은 서버로 전송되지 않아요.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Semantics(
          button: true,
          label: '분석 취소',
          child: InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(_cancelAsset, width: 230, height: 58),
          ),
        ),
      ],
    );
  }
}

class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6B72)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.outlined(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ),
            const _ErrorBadge(),
            const SizedBox(height: 14),
            Text(
              '분석할 정보를 찾지 못했어요',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 18),
            const Text(
              '오류로 처리하지 않고 다시 시도할 수 있게 안내합니다.\n다른 사진을 선택하거나 분석 방식을 바꿔보세요.',
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onClose, child: const Text('다른 사진 분석')),
          ],
        ),
      ),
    );
  }
}

class _ErrorBadge extends StatelessWidget {
  const _ErrorBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC5C8)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text('분석 실패', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
