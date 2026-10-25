import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondevice_image_capstone/main.dart';

void main() {
  testWidgets('시작 화면에서 사진 선택과 빈 이력 화면으로 이동한다', (tester) async {
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
    expect(find.text('아직 분석 이력이 없어요'), findsOneWidget);
  });
}
