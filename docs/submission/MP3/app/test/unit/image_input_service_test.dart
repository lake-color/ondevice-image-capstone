import 'dart:io';

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

  test('discarding deletes the temporary copy of the photo', () async {
    final directory = await Directory.systemTemp.createTemp('picker_copy');
    addTearDown(() => directory.delete(recursive: true));
    final copy = File('${directory.path}/scaled_photo.jpg');
    await copy.writeAsBytes([1, 2, 3]);
    final input = ImageInput(name: 'scaled_photo.jpg', path: copy.path);
    final service = ImageInputService(
      imagePicker: FakePicker(),
      deleteTemporaryCopies: true,
    );

    await service.discard(input);
    expect(await copy.exists(), isFalse);

    // A copy the OS already removed is not an error.
    await service.discard(input);
  });

  test(
    'discarding also deletes the first copy the picker left behind',
    () async {
      final cache = await Directory.systemTemp.createTemp('picker_cache');
      addTearDown(() => cache.delete(recursive: true));
      File create(String path) => File('${cache.path}/$path')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      // Gallery: first copy in its own folder. Camera: first copy alongside.
      final galleryScaled = create('scaled_49.png');
      final galleryFirst = create('folder-a/49.png');
      final cameraScaled = create('scaled_shot.jpg');
      final cameraFirst = create('shot.jpg');
      final unrelated = create('folder-b/50.png');
      final service = ImageInputService(
        imagePicker: FakePicker(),
        deleteTemporaryCopies: true,
      );

      await service.discard(
        ImageInput(name: 'scaled_49.png', path: galleryScaled.path),
      );
      expect(galleryScaled.existsSync(), isFalse);
      expect(galleryFirst.parent.existsSync(), isFalse);
      expect(unrelated.existsSync(), isTrue);
      expect(cameraFirst.existsSync(), isTrue);

      await service.discard(
        ImageInput(name: 'scaled_shot.jpg', path: cameraScaled.path),
      );
      expect(cameraScaled.existsSync(), isFalse);
      expect(cameraFirst.existsSync(), isFalse);
      expect(unrelated.existsSync(), isTrue);
    },
  );

  test('nothing is deleted where the path may be the original file', () async {
    final directory = await Directory.systemTemp.createTemp('picker_original');
    addTearDown(() => directory.delete(recursive: true));
    final original = File('${directory.path}/photo.jpg');
    await original.writeAsBytes([1, 2, 3]);
    final service = ImageInputService(
      imagePicker: FakePicker(),
      deleteTemporaryCopies: false,
    );

    await service.discard(ImageInput(name: 'photo.jpg', path: original.path));
    expect(await original.exists(), isTrue);
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
