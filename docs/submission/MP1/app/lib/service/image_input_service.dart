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
  }) : _imagePicker = imagePicker ?? image_picker.ImagePicker(),
       _openSettings = openSettings ?? AppSettings.openAppSettings;

  static const _permissionErrorCodes = {
    'camera_access_denied',
    'camera_access_restricted',
    'photo_access_denied',
    'photo_access_restricted',
  };

  final image_picker.ImagePicker _imagePicker;
  final Future<void> Function() _openSettings;

  /// Opens this app's page in the OS settings, where a denied permission can
  /// be granted again. Once access is denied the OS stops asking, so this is
  /// the only way back.
  Future<void> openPermissionSettings() => _openSettings();

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
