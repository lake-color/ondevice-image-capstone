import 'package:flutter/material.dart';

import '../app/app_router.dart';

const _titleAsset = 'docs/design-references/이미지소스/타이틀이미지.png';

class TitlePage extends StatelessWidget {
  const TitlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.58,
                    child: Transform.scale(
                      scale: 1.08,
                      child: Image.asset(
                        _titleAsset,
                        fit: BoxFit.contain,
                        semanticLabel: '고양이를 촬영하고 분석하는 모습',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '사진 속 정보를\n기기에서 바로 분석해요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontSize: 30, height: 1.28),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.analysis),
                    child: const Text('시작하기'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '사진은 서버에 전송하지 않고, 분석 결과만 저장합니다.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8A8E9A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
