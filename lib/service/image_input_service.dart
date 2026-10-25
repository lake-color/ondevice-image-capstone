enum ImageSourceType { camera, gallery }

class ImagePermissionDeniedException implements Exception {
  const ImagePermissionDeniedException();
}

class ImageInputUnavailableException implements Exception {
  const ImageInputUnavailableException(this.message);

  final String message;
}

class ImageInput {
  const ImageInput({required this.name, required this.source});

  final String name;
  final ImageSourceType source;
}

abstract interface class ImageInputService {
  Future<ImageInput?> pick(ImageSourceType source);
}

/// Explicitly reports that native image input has not been configured yet.
class UnavailableImageInputService implements ImageInputService {
  @override
  Future<ImageInput?> pick(ImageSourceType source) {
    throw const ImageInputUnavailableException('카메라와 갤러리 플러그인이 아직 연결되지 않았습니다.');
  }
}
