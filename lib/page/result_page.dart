import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/analysis_result.dart';
import '../service/share_service.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.result,
    required this.shareService,
  });

  final AnalysisResult result;
  final ShareService shareService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
              children: [
                Text('분석 결과', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  '${result.method.title} 결과를 확인하세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 26),
                Container(
                  height: 210,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFABADB5)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (result.imagePath != null)
                        Image.file(
                          File(result.imagePath!),
                          key: ValueKey(result.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Center(child: Text('원본 사진을 불러올 수 없습니다.')),
                        )
                      else
                        const Center(child: Text('원본 사진은 이력에 저장되지 않습니다.')),
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: ColoredBox(
                          color: Color(0xAAFFFFFF),
                          child: SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: Center(
                              child: Text(
                                '원본 사진',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ResultCard(result: result),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _share(context),
                  child: const Text('결과 공유하기'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('다른 사진 분석'),
                ),
                const SizedBox(height: 16),
                Text(
                  '분석 결과는 이 기기에 저장되었습니다.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    await shareService.share(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('분석 결과를 클립보드에 복사했습니다.')));
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final confidence = result.confidence;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFABADB5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEAE8FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Text(
                result.method.title,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            result.content,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontSize: 25),
          ),
          if (confidence != null && confidence < 0.5) ...[
            const SizedBox(height: 10),
            const Text('신뢰도가 낮은 추정 결과입니다. 사물이 크게 보이는 사진으로 다시 분석해 주세요.'),
          ],
          const Divider(height: 18),
          _MetaRow(label: '처리 시간', value: _formatDuration(result.duration)),
          if (confidence != null)
            _MetaRow(
              label: '인식 신뢰도',
              value: '${(confidence * 100).toStringAsFixed(0)}%',
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}초';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
