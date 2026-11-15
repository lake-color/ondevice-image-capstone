import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/data/analysis_history_store.dart';
import 'package:ondevice_image_capstone/data/history_storage.dart';
import 'package:ondevice_image_capstone/domain/exceptions.dart';

import '../support/fakes.dart';

void main() {
  test(
    'entries written to a real file survive reopening and deletion',
    () async {
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
      final first = sampleResult('한글\nOCR 텍스트');
      final second = sampleResult('고양이', confidence: 0.95);
      await store.add(first);
      await store.add(second);

      final reopened = AnalysisHistoryStore(storage: storage);
      addTearDown(reopened.dispose);
      await reopened.load();
      // Newest first.
      expect(reopened.entries.map((entry) => entry.result.toJson()), [
        second.toJson(),
        first.toJson(),
      ]);

      await reopened.delete(reopened.entries.first.id);
      final afterDelete = AnalysisHistoryStore(storage: storage);
      addTearDown(afterDelete.dispose);
      await afterDelete.load();
      expect(afterDelete.entries.single.result.content, first.content);
      // The temporary file used for the atomic replace is not left behind.
      expect(directory.listSync().map((file) => file.uri.pathSegments.last), [
        'analysis_history.json',
      ]);
    },
  );

  test('the file format is version 1 with id and result per entry', () async {
    final storage = MemoryStorage();
    final store = AnalysisHistoryStore(storage: storage);
    addTearDown(store.dispose);
    final result = sampleResult('고양이', confidence: 0.95);
    await store.add(result);

    final document = jsonDecode(storage.value!) as Map<String, dynamic>;
    expect(document.keys.toSet(), {'version', 'entries'});
    expect(document['version'], 1);
    final entry = (document['entries'] as List).single as Map<String, dynamic>;
    expect(entry.keys.toSet(), {'id', 'result'});
    expect(entry['id'], store.entries.single.id);
    expect(entry['result'], result.toJson());
  });

  test(
    'simultaneous results with the same timestamp get distinct ids',
    () async {
      final store = AnalysisHistoryStore(storage: MemoryStorage());
      addTearDown(store.dispose);
      await Future.wait([
        for (var i = 0; i < 3; i++) store.add(sampleResult('결과 $i')),
      ]);

      expect(store.entries.map((entry) => entry.id).toSet(), hasLength(3));
      expect(store.entries.map((entry) => entry.result.content), [
        '결과 2',
        '결과 1',
        '결과 0',
      ]);
    },
  );

  test('listeners are notified after load, add and delete', () async {
    final store = AnalysisHistoryStore(storage: MemoryStorage());
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.load();
    await store.add(sampleResult('결과'));
    await store.delete(store.entries.single.id);

    expect(notifications, 3);
  });

  test(
    'a failed write keeps memory and file unchanged and can be retried',
    () async {
      final storage = MemoryStorage();
      final store = AnalysisHistoryStore(storage: storage);
      addTearDown(store.dispose);
      await store.add(sampleResult('기존 결과'));
      final saved = storage.value;

      storage.failWrite = true;
      await expectLater(
        store.add(sampleResult('새 결과')),
        throwsA(isA<HistoryStorageException>()),
      );
      await expectLater(
        store.delete(store.entries.single.id),
        throwsA(isA<HistoryStorageException>()),
      );
      expect(store.entries.single.result.content, '기존 결과');
      expect(storage.value, saved);

      storage.failWrite = false;
      await store.add(sampleResult('재시도'));
      expect(store.entries, hasLength(2));
    },
  );

  for (final (reason, source) in [
    ('broken JSON', '{broken'),
    ('unsupported version', '{"version":2,"entries":[]}'),
    ('entry without fields', '{"version":1,"entries":[{}]}'),
    (
      'duplicate ids',
      '{"version":1,"entries":[{"id":"1","result":{}},{"id":"1","result":{}}]}',
    ),
  ]) {
    test('unreadable history is never overwritten: $reason', () async {
      final storage = MemoryStorage()..value = source;
      final store = AnalysisHistoryStore(storage: storage);
      addTearDown(store.dispose);

      await store.load();
      expect(store.isLoaded, isFalse);
      expect(store.loadError, isNotNull);
      await expectLater(
        store.add(sampleResult('새 결과')),
        throwsA(isA<HistoryStorageException>()),
      );
      expect(storage.value, source);
    });
  }

  test('a failed read can be retried without losing stored data', () async {
    final storage = MemoryStorage();
    final original = AnalysisHistoryStore(storage: storage);
    addTearDown(original.dispose);
    await original.add(sampleResult('보존할 결과'));

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
