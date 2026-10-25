/// The analysis capabilities presented by the application.
enum AnalysisMethod {
  ocr,
  imageClassification;

  String get title => switch (this) {
    AnalysisMethod.ocr => '텍스트 분석',
    AnalysisMethod.imageClassification => '사물 분석',
  };

  String get description => switch (this) {
    AnalysisMethod.ocr => '사진 속 글자 인식',
    AnalysisMethod.imageClassification => '사진 속 주요 사물',
  };
}
