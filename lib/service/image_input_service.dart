import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as image_picker;

enum ImageSourceType { camera, gallery }

class ImagePermissionDeniedException implements Exception {
  const ImagePermissionDeniedException();
}

class ImageInputUnavailableException implements Exception {
  const ImageInputUnavailableException(this.message);

  final String message;
}

class ImageInput {
  const ImageInput({
    required this.name,
    required this.path,
    required this.source,
  });

  final String name;
  final String path;
  final ImageSourceType source;
}

abstract interface class ImageInputService {
  Future<ImageInput?> pick(ImageSourceType source);
}

class DeviceImageInputService implements ImageInputService {
  DeviceImageInputService({image_picker.ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? image_picker.ImagePicker();

  static const _permissionErrorCodes = {
    'camera_access_denied',
    'camera_access_restricted',
    'photo_access_denied',
    'photo_access_restricted',
  };

  final image_picker.ImagePicker _imagePicker;

  @override
  Future<ImageInput?> pick(ImageSourceType source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source == ImageSourceType.camera
            ? image_picker.ImageSource.camera
            : image_picker.ImageSource.gallery,
        imageQuality: 95,
      );
      if (image == null) return null;

      return ImageInput(name: image.name, path: image.path, source: source);
    } on PlatformException catch (error) {
      if (_permissionErrorCodes.contains(error.code)) {
        throw const ImagePermissionDeniedException();
      }
      throw ImageInputUnavailableException(
        error.message ?? '사진을 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    }
  }
}

/// Explicitly reports that native image input has not been configured yet.
class UnavailableImageInputService implements ImageInputService {
  @override
  Future<ImageInput?> pick(ImageSourceType source) {
    throw const ImageInputUnavailableException('카메라와 갤러리 플러그인이 아직 연결되지 않았습니다.');
  }
}
