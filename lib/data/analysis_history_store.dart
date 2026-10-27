import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/analysis_history.dart';
import '../domain/analysis_result.dart';
import 'history_storage.dart';

class HistoryStorageException implements Exception {
  const HistoryStorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AnalysisHistoryStore extends ChangeNotifier {
  AnalysisHistoryStore({HistoryStorage? storage})
    : _storage = storage ?? FileHistoryStorage();

  final HistoryStorage _storage;
  List<AnalysisHistory> _entries = [];
  Future<void> _pending = Future.value();
  bool _loaded = false;
  bool _disposed = false;
  String? _loadError;

  List<AnalysisHistory> get entries => List.unmodifiable(_entries);
  bool get isLoaded => _loaded;
  String? get loadError => _loadError;

  // Serialize operations so a slower write cannot restore stale data.
  Future<void> _enqueue(Future<void> Function() operation) {
    final task = _pending.then((_) => operation());
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<void> load() => _enqueue(_load);

  Future<void> _load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final source = await _storage.read();
      final entries = <AnalysisHistory>[];
      if (source != null) {
        final document = jsonDecode(source) as Map<String, dynamic>;
        if (document['version'] != 1) {
          throw const FormatException('Unsupported history version');
        }
        final ids = <String>{};
        for (final item in document['entries'] as List<dynamic>) {
          final json = item as Map<String, dynamic>;
          final id = json['id'] as String;
          if (!ids.add(id)) throw const FormatException('Duplicate history ID');
          entries.add(
            AnalysisHistory(
              id: id,
              result: AnalysisResult.fromJson(
                json['result'] as Map<String, dynamic>,
              ),
            ),
          );
        }
      }
      _entries = entries;
      _loaded = true;
    } catch (_) {
      // Preserve unreadable files instead of overwriting with empty history.
      _loadError = '저장된 이력을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _notify();
  }

  Future<void> _change(
    List<AnalysisHistory> Function(List<AnalysisHistory>) transform,
  ) => _enqueue(() async {
    await _load();
    if (!_loaded) throw HistoryStorageException(_loadError!);
    final next = transform(List.of(_entries));
    try {
      await _storage.write(
        jsonEncode({
          'version': 1,
          'entries': [
            for (final entry in next)
              {'id': entry.id, 'result': entry.result.toJson()},
          ],
        }),
      );
    } catch (_) {
      throw const HistoryStorageException(
        '이력을 저장하지 못했어요. 저장 공간을 확인하고 다시 시도해 주세요.',
      );
    }
    _entries = next;
    _notify();
  });

  Future<void> add(AnalysisResult result) => _change((entries) {
    final base = result.createdAt.microsecondsSinceEpoch.toString();
    var id = base;
    var suffix = 1;
    while (entries.any((entry) => entry.id == id)) {
      id = '$base-${suffix++}';
    }
    return [AnalysisHistory(id: id, result: result), ...entries];
  });

  Future<void> delete(String id) => _change((entries) {
    entries.removeWhere((entry) => entry.id == id);
    return entries;
  });

  Future<void> clear() => _change((_) => []);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
