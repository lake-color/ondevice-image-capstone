import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ondevice_image_capstone/domain/exceptions.dart';
import 'package:ondevice_image_capstone/service/image_input_service.dart';

import '../support/fakes.dart';

void main() {
  test('a picked photo is returned with its name and path', () async {
    final file = XFile('/tmp/picked.jpg');
    final picker = FakePicker(file: file);

    final input = await ImageInputService(imagePicker: picker)
        .pick(ImageSourceType.gallery);

    expect(input!.name, file.name);
    expect(input.path, file.path);
  });

  test('camera and gallery map to the matching picker source', () async {
    final picker = FakePicker();
    final service = ImageInputService(imagePicker: picker);

    await service.pick(ImageSourceType.camera);
    expect(picker.lastSource, ImageSource.camera);
    await service.pick(ImageSourceType.gallery);
    expect(picker.lastSource, ImageSource.gallery);
  });

  test('cancelling the picker returns null instead of failing', () async {
    final service = ImageInputService(imagePicker: FakePicker());

    expect(await service.pick(ImageSourceType.gallery), isNull);
  });

  test(
    'denied and restricted access become the permission exception',
    () async {
      for (final code in [
        'camera_access_denied',
        'camera_access_restricted',
        'photo_access_denied',
        'photo_access_restricted',
      ]) {
        final service = ImageInputService(
          imagePicker: FakePicker(error: PlatformException(code: code)),
        );

        await expectLater(
          service.pick(ImageSourceType.camera),
          throwsA(isA<ImagePermissionDeniedException>()),
          reason: code,
        );
      }
    },
  );

  test('other platform errors hide the raw platform message', () async {
    final service = ImageInputService(
      imagePicker: FakePicker(
        error: PlatformException(
          code: 'invalid_image',
          message: 'raw platform text',
        ),
      ),
    );

    await expectLater(
      service.pick(ImageSourceType.gallery),
      throwsA(
        isA<ImageInputUnavailableException>().having(
          (error) => error.message,
          'message',
          '사진을 불러오지 못했습니다. 다시 시도해 주세요.',
        ),
      ),
    );
  });
}
