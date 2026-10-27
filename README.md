# On-device Image Capstone

Android와 iOS를 대상으로 하는 Flutter 기반 학교 캡스톤 디자인 프로젝트입니다.
카메라·갤러리 입력, ML Kit OCR, 결과 화면과 로컬 분석 이력 저장을 구현했습니다.
MobileNetV3 Small 모델을 앱에 포함하여 네트워크 없이 이미지 분류를 실행합니다.

## 개발 환경

- Flutter 3.47.5
- Dart 3.13.4
- FVM
- Android API 26 이상 / iOS (빌드·실기기 검증 대기)

## 실행 방법

FVM이 설치된 환경에서 다음 명령어를 실행합니다.

```sh
fvm flutter pub get
fvm flutter run
```

## 현재 구현 상태

- 이미지 분류: MobileNetV3 Small / LiteRT, ImageNet 영어 클래스명·신뢰도 표시
- OCR: 기기 내 텍스트 인식, 결과 복사. 현재 Latin 설정이며 한글·영어 지원으로 확장 예정
- 이력: 결과 텍스트·분석 종류·처리 시간·날짜·신뢰도를 기기에 저장, 조회·삭제 및 재실행 후 복원
- 저장 오류: 읽기 재시도, 분석 결과 저장 재시도, 손상 파일 덮어쓰기 방지
- 원본 사진은 분석 이력에 저장하지 않음
- Firebase 동기화는 미구현

이력은 앱 지원 디렉터리의 `analysis_history.json`에 저장합니다. 임시 파일을
완전히 기록한 뒤 교체하고, 저장 성공 후 메모리를 갱신합니다.
앱 삭제 또는 앱 데이터 초기화 시 이력이 사라질 수 있습니다.

검증 명령: `fvm flutter analyze`, `fvm flutter test`, `fvm flutter build apk --debug`.
실제 기기에서 사진 선택 → OCR → 앱 종료·재실행 → 이력 조회·삭제를 추가 확인해야 합니다.

모델 출처·정규화·테스트 방법은 [이미지 분류 문서](docs/IMAGE_CLASSIFICATION.md)에 기록했습니다.
다음 작업은 한글·영어 OCR 지원과 실제 입력 이미지 표시 보완입니다.
로컬 저장 경로는 [path_provider 공식 문서](https://pub.dev/packages/path_provider)를 기준으로 구성했습니다.

## 프로젝트 구조

```text
android/       Android 플랫폼 프로젝트
ios/           iOS 플랫폼 프로젝트
docs/          과제 요구사항 문서
assets/models/ 분류 모델, 라벨, 라이선스
screenshots/   과제 요구사항 화면 캡처 사진

lib/
  app/         앱 구성 관련 코드
  data/        데이터 관련 코드
  domain/      도메인 모델
  page/        화면 코드
  service/     서비스 코드
  main.dart    앱 진입점

test/          테스트 코드
integration_test/ Android/iOS 네이티브 분류 실행 테스트
.fvmrc         프로젝트 Flutter 버전 설정
pubspec.yaml   패키지 및 프로젝트 설정
```
