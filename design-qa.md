# Design QA

## Evidence

- Source visual truth:
  - `docs/design-references/화면 UI/화면1_시작.png` (255 × 557)
  - `docs/design-references/화면 UI/화면2_사진선택 및 분석설정.png` (531 × 1131)
  - `docs/design-references/화면 UI/화면4_로딩.png`
  - `docs/design-references/화면 UI/화면5_결과.png`
  - `docs/design-references/화면 UI/화면6_이력.png`
  - `docs/design-references/화면 UI/권한 거부.png`
  - `docs/design-references/화면 UI/분석 실패.png`
  - `docs/design-references/화면 UI/빈 이력.png`
- Rendered implementation:
  - `screenshots/implementation-start-final.png` (1280 × 2856)
  - `screenshots/implementation-analysis-final.png` (1280 × 2856)
  - `screenshots/implementation-history-empty.png` (1280 × 2856)
- Same-input comparisons:
  - `screenshots/design-qa-start-final-comparison.png`
  - `screenshots/design-qa-analysis-final-comparison.png`
- Runtime: Pixel 9 Pro Android emulator, Android 16 API 36, portrait, 1280 × 2856 physical pixels.
- Density normalization: source images were proportionally scaled to the 2856px implementation height and placed beside the implementation capture. Android status/navigation chrome is runtime-owned and excluded from mismatch findings.
- States exercised: start, navigation to photo selection, navigation to empty history, back/navigation controls, small test viewport.
- Console/runtime: no Flutter exceptions in the captured Android states. Initial Gradle transform-cache corruption was cleared and the debug APK subsequently built and installed successfully.

## Findings

- [P0] Actual image input and analysis cannot complete.
  - Location: image selection and analysis flow.
  - Evidence: the repository has no image-picker plugin, ML Kit plugin, LiteRT runtime, MobileNetV3 `.tflite` model, or label file. The app reports the unavailable dependency instead of returning fabricated output.
  - Impact: loading, successful result, populated history, and real permission-denied states cannot be reached with real input.
  - Fix: add the approved packages and a verified MobileNetV3 model/labels, then replace the unavailable implementations.
- [P1] Analysis history is session-only.
  - Location: `AnalysisHistoryStore`.
  - Evidence: entries are held in memory and the UI explicitly labels this limitation.
  - Impact: results do not survive app restart, so the required local-data behavior is incomplete.
  - Fix: connect a local persistence package and serialize only result metadata/text, never the original image.
- [P2] Full visual QA is blocked for loading, result, populated history, permission denial, and analysis failure.
  - Evidence: their code follows the supplied references, but real input/analysis dependencies are absent, so equivalent runtime captures were not produced.
  - Fix: complete the native integrations, capture each state at the same emulator viewport, and run another comparison pass.
- Available start, photo-selection, and empty-history states have no remaining actionable P0/P1/P2 visual mismatch. Typography, spacing, purple/neutral/red tokens, supplied raster assets, and Korean copy were checked against the references.

## Focused Comparison

The final captures are high-resolution and the combined comparisons keep text, buttons, borders, and illustration treatment readable, so separate region crops were not necessary. The photo-selection preview opacity/scale, analysis card selection border, CTA widths, and title hierarchy were inspected in the full comparison.

## Comparison History

1. Start screen: the first capture had excess space above the illustration and undersized title/hero treatment. The hero was given a proportional height, scaled slightly, and the heading increased. The final comparison shows the intended illustration-led hierarchy.
2. Photo-selection screen: the first capture showed a smaller, overly saturated preview and low-contrast analysis-card text. Preview opacity/scale, box ratio, card text colors, and CTA copy were corrected. The final comparison aligns with the supplied reference.
3. Empty history: the default test viewport exposed a 24px vertical overflow. The state panel was made scrollable and the widget test then passed.

## Verification

- `dart analyze`: passed with no issues.
- `flutter test`: passed, 1 test.
- Android debug build/install: passed on the Pixel 9 Pro emulator.
- Primary interactions tested: start → photo selection → empty history.

## Follow-up Polish

- Recheck exact Korean font metrics on physical Android and iOS devices because the design reference does not identify a bundled font.
- `화면8_결합.png` was not present in the provided directory; no inferred screen7 or screen8 was created.

final result: blocked
