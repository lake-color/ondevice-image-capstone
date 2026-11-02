# 테스트 실행

모든 명령은 프로젝트 루트에서 실행합니다.

## 단위·위젯 테스트

```sh
fvm flutter test
```

- `unit/`: 이력 저장, 이미지 전처리와 분류 후처리
- `widget/`: 화면 이동과 UI 회귀 검증

## 기기 통합 테스트

`integration/`은 Android/iOS 기기 또는 에뮬레이터가 필요합니다.
Flutter가 일반 테스트로 자동 수집하지 않도록 파일명을 `*_device.dart`로
구분하며, 공통 `driver.dart`를 통해 실행합니다. Flutter의 `flutter test`는
루트 `integration_test/` 경로만 기기 테스트로 판별하므로 여기서는
`flutter drive`를 사용합니다.

네이티브 분류 실행·반복 추론·손상 입력 검증:

```sh
fvm flutter drive --driver=test/integration/driver.dart --target=test/integration/classification_device.dart -d <device-id>
```

사진 분류 정확도와 한영 OCR 검증:

```sh
fvm flutter drive --driver=test/integration/driver.dart --target=test/integration/recognition_quality_device.dart -d <device-id>
```

품질 테스트는 사진 다운로드에 네트워크가 필요합니다. 빨간 사과를 석류로
오분류하여 실패한 기록이 있으며, 상세 내용은
[진행 현황](../docs/STATUS.md)를 참고하세요.
