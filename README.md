# On-device Image Capstone

사진 속 사물과 텍스트를 기기 내부에서 분석하는 Flutter 기반 캡스톤 프로젝트입니다.
Android와 iOS를 대상으로 하며, 핵심 분석과 이력 관리는 서버 연결 없이 동작합니다.

## 주요 기능

- 카메라 촬영·갤러리 선택 및 사진 미리보기
- MobileNetV3 Small / LiteRT 기반 사물 분류와 신뢰도 표시
- Google ML Kit 기반 한글·영어 OCR
- 분석 결과·처리 시간 표시 및 클립보드 복사
- 로컬 JSON 이력 저장·조회·삭제, 앱 재실행 후 복원
- 권한·분석·저장 오류 안내와 이력 읽기·저장 재시도

원본 사진과 사진 경로는 이력에 저장하지 않습니다.
화면은 **시작 → 사진 선택 → 분석 → 결과** 순서로 이동하며, 사진 선택 화면에서 이력을 조회합니다.

## 개발 환경 및 실행

- Flutter 3.47.5 · Dart 3.13.4 · FVM
- Android API 26 이상 · iOS 15.5 이상

FVM과 대상 플랫폼 개발 도구를 설치하고 기기 또는 에뮬레이터를 연결한 뒤 실행합니다.
iOS 빌드에는 macOS와 Xcode가 필요합니다.

```sh
fvm flutter pub get
fvm flutter run
```

## 프로젝트 구조

```text
lib/
  main.dart    앱 진입점
  app/         서비스 연결, 라우팅, 테마
  page/        시작·사진 선택·로딩·결과·이력 화면
  service/     이미지 입력, OCR, 사물 분류, 결과 복사
  domain/      분석 방식·결과·이력 모델
  data/        로컬 이력 저장소
assets/
  models/      분류 모델, 라벨, 라이선스
  images/      앱 이미지 리소스
test/
  unit/        단위 테스트
  widget/      화면·UI 테스트
  integration/ 기기 통합 테스트
android/, ios/ 플랫폼 설정
docs/
  STATUS.md    진행 현황·검증 기록·남은 작업
  technical/   기술 구성과 모델 사양
  design/      디자인 참고 화면
  submission/  개인정보·프롬프트 기록 제출물
screenshots/   구현 화면 및 디자인 비교 이미지
tool/          모델 검사 도구
```

## 검증 및 남은 작업

```sh
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
```

기기 통합 테스트는 별도로 실행합니다. 명령은 [테스트 안내](test/README.md)를 참고하세요.

- 사물 분류는 ImageNet 클래스 범위이며, 실제 사진 오분류 사례가 있어 정확도 개선이 필요합니다.
- iOS 빌드·실기기 동작과 실제 촬영·권한 흐름은 추가 검증이 필요합니다.
- Firebase를 통한 기기 간 이력 동기화는 미구현입니다.

세부 내용: [문서 안내](docs/README.md) · [진행 현황](docs/STATUS.md) · [기술 구성](docs/technical/ARCHITECTURE.md)
