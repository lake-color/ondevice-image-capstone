import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as image_picker;

import '../domain/exceptions.dart';

enum ImageSourceType { camera, gallery }

class ImageInput {
  const ImageInput({required this.name, required this.path});

  final String name;
  final String path;
}

class ImageInputService {
  ImageInputService({
    image_picker.ImagePicker? imagePicker,
    Future<void> Function()? openSettings,
    bool? deleteTemporaryCopies,
  }) : _imagePicker = imagePicker ?? image_picker.ImagePicker(),
       _openSettings = openSettings ?? AppSettings.openAppSettings,
       _deleteTemporaryCopies =
           deleteTemporaryCopies ?? (Platform.isAndroid || Platform.isIOS);

  static const _permissionErrorCodes = {
    'camera_access_denied',
    'camera_access_restricted',
    'photo_access_denied',
    'photo_access_restricted',
  };

  final image_picker.ImagePicker _imagePicker;
  final Future<void> Function() _openSettings;

  // On Android and iOS the picker hands over a copy inside the app's cache,
  // never the file in the user's gallery. Elsewhere the path may be the
  // original, so nothing is deleted there.
  final bool _deleteTemporaryCopies;

  /// Opens this app's page in the OS settings, where a denied permission can
  /// be granted again. Once access is denied the OS stops asking, so this is
  /// the only way back.
  Future<void> openPermissionSettings() => _openSettings();

  /// Removes the picker's temporary copy once the photo is no longer shown,
  /// so the app keeps no image after the analysis is over.
  Future<void> discard(ImageInput input) async {
    if (!_deleteTemporaryCopies) return;
    final file = File(input.path);
    try {
      if (await file.exists()) await file.delete();

      // Because imageQuality is set, the Android picker re-encodes its first
      // copy into `scaled_<name>` and leaves that first copy behind, either
      // beside it (camera) or in a folder of its own (gallery).
      const prefix = 'scaled_';
      final name = file.uri.pathSegments.last;
      if (!name.startsWith(prefix)) return;
      final firstCopy = name.substring(prefix.length);
      final cache = file.parent;
      final beside = File('${cache.path}/$firstCopy');
      if (await beside.exists()) await beside.delete();
      await for (final entry in cache.list()) {
        if (entry is Directory &&
            await File('${entry.path}/$firstCopy').exists()) {
          await entry.delete(recursive: true);
        }
      }
    } on FileSystemException {
      // Already gone, or the OS cleared the cache first.
    }
  }

  Future<ImageInput?> pick(ImageSourceType source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source == ImageSourceType.camera
            ? image_picker.ImageSource.camera
            : image_picker.ImageSource.gallery,
        imageQuality: 95,
      );
      if (image == null) return null;

      return ImageInput(name: image.name, path: image.path);
    } on PlatformException catch (error) {
      if (_permissionErrorCodes.contains(error.code)) {
        throw const ImagePermissionDeniedException();
      }
      // The platform message is untranslated and technical; do not show it.
      throw const ImageInputUnavailableException();
    }
  }
}
