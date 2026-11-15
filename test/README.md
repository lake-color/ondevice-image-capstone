# 테스트 실행

모든 명령은 프로젝트 루트에서 실행합니다.

## 단위·위젯 테스트

```sh
fvm flutter test
```

| 위치 | 검증 범위 |
|---|---|
| `unit/analysis_result_test.dart` | 저장 JSON 필드, 이전 버전 데이터 호환, 공유 문구 |
| `unit/analysis_history_store_test.dart` | 파일 저장·재열기·삭제, 파일 형식, ID 중복 방지, 저장·읽기 실패와 재시도, 손상 파일 보존 |
| `unit/analysis_service_test.dart` | OCR·분류 분기, 모델 라벨과 신뢰도를 변환 없이 전달, 예외 전달 |
| `unit/image_input_service_test.dart` | 카메라·갤러리 구분, 선택 취소, 권한 거부와 기타 입력 오류 |
| `unit/mobilenet_classifier_test.dart` | 라벨 구성, 전처리(정규화·중앙 자르기·투명 배경·EXIF 방향), 후처리(softmax·잘못된 출력) |
| `widget/analysis_page_test.dart` | 권한 설명 문구, 카메라·갤러리 사진 표시, 선택 취소, 권한 거부 안내·닫기·설정 열기와 실패, 입력 오류 안내, 사진 선택 전 분석 불가, 분석 요청 전달 |
| `widget/loading_page_test.dart` | 분석 후 저장과 결과 이동, 분석 실패 안내, 저장 실패 재시도, 분석 취소 |
| `widget/result_page_test.dart` | 결과·신뢰도 표시, 낮은 신뢰도 안내, OS 공유 시트 호출과 실패 안내 |
| `widget/history_page_test.dart` | 목록 표시, 삭제 확인과 실패, 빈 이력, 최근 항목 공유, 읽기 실패 재시도 |
| `widget/app_flow_test.dart` | 시작부터 이력까지 전체 화면 흐름, 실제 `App` 조립 |

`support/`는 테스트 대역과 공통 준비 코드입니다. 별도 인터페이스 없이 실제 클래스를
`implements`하여 OCR·분류·사진 선택·이력 파일을 대체합니다. 이 테스트들은 ML Kit와
LiteRT 네이티브 코드를 실행하지 않으므로 실제 인식은 아래 기기 통합 테스트에서 확인합니다.

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
