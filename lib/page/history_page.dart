import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/analysis_history_store.dart';
import '../domain/analysis_history.dart';
import '../domain/exceptions.dart';
import '../service/share_service.dart';
import 'notice_card.dart';

const _trashAsset = 'assets/images/휴지통 아이콘.png';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.historyStore});

  final AnalysisHistoryStore historyStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: historyStore,
      builder: (context, _) {
        final entries = historyStore.entries;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 54, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '분석 이력',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '분석 결과는 이 기기에 저장됩니다.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: historyStore.loadError != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(historyStore.loadError!),
                                    TextButton(
                                      onPressed: historyStore.load,
                                      child: const Text('다시 시도'),
                                    ),
                                  ],
                                ),
                              )
                            : !historyStore.isLoaded
                            ? const Center(child: CircularProgressIndicator())
                            : entries.isEmpty
                            ? _EmptyHistory(
                                onStart: () => Navigator.pop(context),
                              )
                            : ListView.separated(
                                itemCount: entries.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) => _HistoryCard(
                                  entry: entries[index],
                                  onDelete: () =>
                                      _confirmDelete(context, entries[index]),
                                ),
                              ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: entries.isEmpty
                            ? null
                            : () => shareResult(context, entries.first.result),
                        child: const Text('결과 공유하기'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('돌아가기'),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '앱을 다시 실행해도 이력이 유지됩니다. 원본 사진은 저장하지 않아요.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AnalysisHistory entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Image.asset(_trashAsset, width: 72, height: 72),
        title: const Text('이 기록을 삭제할까요?'),
        content: const Text('삭제한 분석 결과는 복구할 수 없습니다.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('삭제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await historyStore.delete(entry.id);
    } on HistoryStorageException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.onDelete});

  final AnalysisHistory entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final result = entry.result;
    final confidence = result.confidence;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF20232D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.method.title, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  result.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${confidence == null ? '' : '신뢰도 ${(confidence * 100).toStringAsFixed(0)}% · '}'
                  '${(result.duration.inMilliseconds / 1000).toStringAsFixed(2)}초',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5D64),
                  backgroundColor: AppColors.dangerSoft,
                  minimumSize: const Size(68, 34),
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0xFFFFB4B8)),
                  ),
                ),
                child: const Text('삭제'),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(result.createdAt),
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final time =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      return '오늘 $time';
    }
    return '${date.month}월 ${date.day}일 $time';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: NoticeCard(
          badge: '빈이력',
          title: '아직 분석 이력이 없어요',
          message: '분석을 완료하면 결과 텍스트와 처리 시간이 이곳에 저장됩니다.\n원본 사진은 저장하지 않아요.',
          actionLabel: '사진 분석 시작',
          onAction: onStart,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
