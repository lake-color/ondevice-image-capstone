import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ondevice_image_capstone/data/history_storage.dart';
import 'package:ondevice_image_capstone/domain/analysis_method.dart';
import 'package:ondevice_image_capstone/domain/analysis_result.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';
import 'package:ondevice_image_capstone/service/mobilenet_classifier.dart';
import 'package:ondevice_image_capstone/service/ocr_analyzer.dart';

// Test doubles implement the concrete classes directly: every Dart class is
// also an interface, so the app needs no separate abstract types for this.

class FakeOcr implements MlKitOcrAnalyzer {
  FakeOcr({this.text = '인식된 글자', this.error, this.gate});

  final String text;
  final Object? error;

  /// When set, recognition waits for this future (to hold the loading state).
  final Future<void>? gate;
  int calls = 0;

  @override
  Future<String> recognize(ImageInput input) async {
    calls++;
    await gate;
    if (error != null) throw error!;
    return text;
  }
}

class FakeClassifier implements MobileNetClassifier {
  FakeClassifier({this.label = 'tabby', this.confidence = 0.9, this.error});

  final String label;
  final double confidence;
  final Object? error;
  int calls = 0;

  @override
  Future<ClassificationOutput> classify(ImageInput input) async {
    calls++;
    if (error != null) throw error!;
    return ClassificationOutput(label: label, confidence: confidence);
  }
}

/// In-memory history file with switchable read and write failures.
class MemoryStorage implements FileHistoryStorage {
  String? value;
  bool failRead = false;
  bool failWrite = false;

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

/// Stands in for the platform picker: returns [file] or throws [error].
class FakePicker extends Fake implements ImagePicker {
  FakePicker({this.file, this.error});

  final XFile? file;
  final PlatformException? error;
  ImageSource? lastSource;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    if (error != null) throw error!;
    return file;
  }
}

const sampleInput = ImageInput(name: 'photo.jpg', path: '/tmp/photo.jpg');

AnalysisResult sampleResult(
  String content, {
  double? confidence,
  DateTime? createdAt,
}) => AnalysisResult(
  method: confidence == null
      ? AnalysisMethod.ocr
      : AnalysisMethod.imageClassification,
  sourceName: '사진.jpg',
  title: confidence == null ? '인식된 텍스트' : '분류 결과',
  content: content,
  duration: const Duration(microseconds: 123456),
  createdAt: createdAt ?? DateTime.utc(2026, 10, 27),
  confidence: confidence,
);

/// Records calls made to the share plugin instead of opening a share sheet.
List<MethodCall> mockShareChannel(WidgetTester tester) {
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  final calls = <MethodCall>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    calls.add(call);
    return 'dev.fluttercommunity.plus/share/unavailable';
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return calls;
}
