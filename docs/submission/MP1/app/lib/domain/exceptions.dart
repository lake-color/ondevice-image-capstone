/// Errors the app raises on purpose. [message] is written for the user and can
/// be shown as is; any other error type is unexpected and gets a generic text.
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The user or the OS denied camera or photo library access.
class ImagePermissionDeniedException extends AppException {
  const ImagePermissionDeniedException() : super('사진에 접근할 권한이 없습니다.');
}

/// The camera or gallery failed for a reason other than permission.
class ImageInputUnavailableException extends AppException {
  const ImageInputUnavailableException() : super('사진을 불러오지 못했습니다. 다시 시도해 주세요.');
}
