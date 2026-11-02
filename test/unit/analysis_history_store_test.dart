import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/data/analysis_history_store.dart';
import 'package:ondevice_image_capstone/data/history_storage.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/domain/analysis_result.dart';

AnalysisResult result(String content, {double? confidence}) => AnalysisResult(
  method: confidence == null
      ? AnalysisMethod.ocr
      : AnalysisMethod.imageClassification,
  sourceName: '사진.jpg',
  title: '분석 결과',
  content: content,
  duration: const Duration(microseconds: 123456),
  createdAt: DateTime.utc(2026, 10, 27),
  confidence: confidence,
);

class MemoryStorage implements HistoryStorage {
  String? value;
  bool failWrite = false;
  bool failRead = false;
  @override
  Future<String?> read() async {
    if (failRead) throw const FileSystemException('read failed');
    return value;
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw const FileSystemException('disk full');
    this.value = value;
  }
}

void main() {
  test('file snapshots survive reopening, deletion and clearing', () async {
    final directory = await Directory.systemTemp.createTemp(
      'analysis_history_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = FileHistoryStorage(directory: () async => directory);
    final store = AnalysisHistoryStore(storage: storage);
    addTearDown(store.dispose);
    await store.load();
    expect(store.isLoaded, isTrue);
    expect(store.entries, isEmpty);
    final first = result('한글\nOCR 텍스트');
    final second = result('고양이', confidence: 0.95);
    await Future.wait([store.add(first), store.add(second)]);
    expect(store.entries.map((entry) => entry.id).toSet(), hasLength(2));

    final reopened = AnalysisHistoryStore(storage: storage);
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.entries.map((entry) => entry.result.toJson()), [
      second.toJson(),
      first.toJson(),
    ]);
    await reopened.delete(reopened.entries.first.id);
    final afterDelete = AnalysisHistoryStore(storage: storage);
    addTearDown(afterDelete.dispose);
    await afterDelete.load();
    expect(afterDelete.entries.single.result.content, first.content);
    await afterDelete.clear();
    final afterClear = AnalysisHistoryStore(storage: storage);
    addTearDown(afterClear.dispose);
    await afterClear.load();
    expect(afterClear.entries, isEmpty);
  });

  test(
    'failed writes preserve memory and disk; later operations recover',
    () async {
      final storage = MemoryStorage();
      final store = AnalysisHistoryStore(storage: storage);
      addTearDown(store.dispose);
      await store.add(result('기존 결과'));
      final saved = storage.value;
      storage.failWrite = true;
      await expectLater(
        store.add(result('새 결과')),
        throwsA(isA<HistoryStorageException>()),
      );
      await expectLater(
        store.delete(store.entries.single.id),
        throwsA(isA<HistoryStorageException>()),
      );
      expect(store.entries.single.result.content, '기존 결과');
      expect(storage.value, saved);
      storage.failWrite = false;
      await store.add(result('재시도'));
      expect(store.entries, hasLength(2));
    },
  );

  for (final source in [
    '{broken',
    '{"version":2,"entries":[]}',
    '{"version":1,"entries":[{}]}',
  ]) {
    test('invalid history is preserved: $source', () async {
      final storage = MemoryStorage()..value = source;
      final store = AnalysisHistoryStore(storage: storage);
      addTearDown(store.dispose);
      await store.load();
      expect(store.isLoaded, isFalse);
      expect(store.loadError, isNotNull);
      await expectLater(
        store.add(result('새 결과')),
        throwsA(isA<HistoryStorageException>()),
      );
      expect(storage.value, source);
    });
  }

  test('read failures can be retried without changing stored data', () async {
    final storage = MemoryStorage();
    final original = AnalysisHistoryStore(storage: storage);
    addTearDown(original.dispose);
    await original.add(result('보존할 결과'));
    storage.failRead = true;
    final store = AnalysisHistoryStore(storage: storage);
    addTearDown(store.dispose);
    await store.load();
    expect(store.loadError, isNotNull);
    storage.failRead = false;
    await store.load();
    expect(store.loadError, isNull);
    expect(store.entries.single.result.content, '보존할 결과');
  });
}
