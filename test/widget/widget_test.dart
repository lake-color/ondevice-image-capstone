import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => null,
        );
  });
  testWidgets('시작 화면에서 사진 선택과 이력 로드 실패 안내로 이동한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('사진 속 정보를\n기기에서 바로 분석해요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('사진 선택'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('분석 이력 보기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('사물 분석'), findsOneWidget);
    expect(find.text('텍스트 분석'), findsOneWidget);

    await tester.tap(find.text('분석 이력 보기'));
    await tester.pumpAndSettle();

    expect(find.text('분석 이력'), findsOneWidget);
    expect(find.text('저장된 이력을 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
