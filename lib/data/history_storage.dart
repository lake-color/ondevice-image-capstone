import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class HistoryStorage {
  Future<String?> read();
  Future<void> write(String value);
}

/// Writes a complete snapshot before replacing the previous file.
class FileHistoryStorage implements HistoryStorage {
  FileHistoryStorage({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/analysis_history.json');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(value, flush: true);
    await temporary.rename(file.path);
  }
}
