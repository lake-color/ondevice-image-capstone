import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../app/app_theme.dart';
import '../data/analysis_history_store.dart';
import '../domain/analysis_result.dart';
import '../domain/exceptions.dart';
import '../service/analysis_service.dart';
import 'notice_card.dart';

const _analysisAsset = 'assets/images/분석 이미지.png';
const _cancelAsset = 'assets/images/분석 취소 이미지.png';

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
  AnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    setState(() => _error = null);
    try {
      final result = _result ??= await widget.analysisService.analyze(
        widget.request,
      );
      if (!mounted) return;
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: _error == null
                  ? _LoadingContent(onCancel: () => Navigator.pop(context))
                  : _error is HistoryStorageException
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('분석은 완료했지만 이력을 저장하지 못했어요.'),
                        const SizedBox(height: 12),
                        Text((_error as HistoryStorageException).message),
                        FilledButton(
                          onPressed: _runAnalysis,
                          child: const Text('저장 다시 시도'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('돌아가기'),
                        ),
                      ],
                    )
                  : NoticeCard(
                      badge: '분석 실패',
                      title: '분석할 정보를 찾지 못했어요',
                      message: switch (_error) {
                        AnalysisException error => error.message,
                        _ => '다른 사진을 선택하거나 분석 방식을 바꿔보세요.',
                      },
                      actionLabel: '다른 사진 분석',
                      onAction: () => Navigator.pop(context),
                      onClose: () => Navigator.pop(context),
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
            color: AppColors.primarySoft,
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
