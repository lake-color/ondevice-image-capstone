# On-device Image Capstone

Android와 iOS를 대상으로 하는 Flutter 기반 학교 캡스톤 디자인 프로젝트입니다.
현재는 프로젝트 초기 설정과 기본 구조를 구성하는 단계입니다.

## 개발 환경

- Flutter 3.47.5
- Dart 3.13.4
- FVM
- Android / iOS

## 실행 방법

FVM이 설치된 환경에서 다음 명령어를 실행합니다.

```sh
fvm flutter pub get
fvm flutter run
```

## 프로젝트 구조

```text
android/       Android 플랫폼 프로젝트
ios/           iOS 플랫폼 프로젝트
docs/          과제 요구사항 문서
screenshots/   과제 요구사항 화면 캡처 사진

lib/
  app/         앱 구성 관련 코드
  data/        데이터 관련 코드
  domain/      도메인 모델
  page/        화면 코드
  service/     서비스 코드
  main.dart    앱 진입점

test/          테스트 코드
.fvmrc         프로젝트 Flutter 버전 설정
pubspec.yaml   패키지 및 프로젝트 설정
```
