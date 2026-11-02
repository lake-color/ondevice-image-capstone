# MobileNetV3 이미지 분류

## 모델 출처 및 고정 사양

- Google MobileNetV3 Small 1.0 / 224 / classification metadata, 버전 1
- 배포: https://www.kaggle.com/models/google/mobilenet-v3/tfLite/small-100-224-classification-metadata/1
- 다운로드: https://www.kaggle.com/api/v1/models/google/mobilenet-v3/tfLite/small-100-224-classification-metadata/1/download
- 아카이브의 `1.tflite`를 `assets/models/mobilenet_v3_small.tflite`로 보관
- 모델 SHA-256: `77c98343789c066287e1a5e85314428f47bd4302f053c920ce00a46d90cb1388`
- 모델 크기: 10,221,882 bytes
- `imagenet_labels.txt`는 모델에 포함된 ZIP의 `labels.txt`를 그대로 추출한 파일
- 라벨 SHA-256: `536feacc519de3d418de26b2effb4d75694a8c4c0063e36499a46fa8061e2da9`
- 모델 메타데이터가 명시하는 라이선스: Apache 2.0 (`assets/models/LICENSE.txt`)

## 실제 파일 검사 결과

`fvm dart run tool/inspect_model.dart`로 텐서와 메타데이터를 확인할 수 있습니다.

| 항목 | 값 |
|---|---|
| 입력 | float32 `[1, 224, 224, 3]`, RGB |
| 메타데이터 정규화 | mean 0, std 255 → `pixel / 255.0` |
| 출력 | float32 `[1, 1001]`, logits |
| 후처리 | 최댓값을 뺀 softmax로 확률 계산 |
| 라벨 | 1,001줄, 인덱스 0은 background, 1~1000은 ImageNet 클래스 |

이 파일에는 SOFTMAX 연산자가 없습니다. 이미 확률인 것으로 취급하거나
다른 MobileNet 버전의 `[-1, 1]` 정규화를 적용하면 안 됩니다.
교체 모델은 입력·출력 형태뿐 아니라 정규화와 출력 의미까지 다시 확인해야 합니다.

## 구현 목표 및 한계

- 앱 자산에서 모델을 로드하고 네트워크 없이 기기 CPU에서 실행합니다.
- EXIF 방향을 적용하고 중앙 정사각형 영역을 224×224 RGB로 축소합니다.
- 투명 픽셀은 미리보기와 같은 흰색 배경에 합성합니다.
- 전처리와 추론은 별도 isolate에서 처리합니다.
- 원본 사진은 이력에 저장하지 않습니다.
- 클래스명은 원본 영어 라벨을 사용하되, `Granny Smith`는 UI에서 `사과`로 표시합니다.
  이 모델에는 일반적인 apple 클래스가 없어 해당 출력으로 품종을 판정할 수 없습니다.
- 신뢰도 50% 미만에는 불확실성 안내를 표시합니다. 이 기준은 정확도 보증이나 보정된 임계값이 아닙니다.
- 일반적인 ImageNet 분류이며, 모든 사물이나 여러 사물의 위치를 인식하는 탐지 모델은 아닙니다.
- 신뢰도는 모델의 상대 점수이며 정답을 보장하지 않습니다.

공식 런타임 문서: https://pub.dev/packages/tflite_flutter
메타데이터 스키마: https://github.com/tensorflow/tflite-support/blob/master/tensorflow_lite_support/metadata/metadata_schema.fbs

## 실행 구성 및 검증 방법

Android는 `tflite_flutter 0.12.1`에 포함된 LiteRT 1.4.0 연결을 사용합니다.
패키지 안내에 따라 최소 Android API를 26으로 설정했습니다.
플러그인 0.12.1의 Java 11 설정과 Kotlin 대상이 달라지는 문제를 막기 위해
루트 Gradle에서 `tflite_flutter` 모듈의 Kotlin 대상만 JVM 11로 명시합니다.
iOS는 패키지의 TensorFlowLiteSwift 의존성을 사용하며 Windows에서는 빌드 검증할 수 없습니다.

모델 바이트와 라벨은 최초 사용 시 로드·캐시하고, 각 분석의 interpreter는
작업 isolate 안에서 생성·해제합니다. 현재 처리 시간에는 디코딩·전처리·모델 초기화도 포함됩니다.
입력은 디코더가 지원하는 사진 형식(JPG/PNG 등), 32MB·4천만 화소 이하입니다.
HEIC 등 미지원 형식은 JPG/PNG 사용을 안내합니다.

실행 명령은 [테스트 안내](../../test/README.md), 검증 이력과 사진별 오분류 사례는
[진행 현황](../STATUS.md)에 모았습니다. 일반 테스트는 전처리·후처리를,
기기 통합 테스트는 네이티브 실행 및 OCR·사진 분류 품질을 확인합니다.
