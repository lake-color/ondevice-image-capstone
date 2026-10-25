import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../domain/analysis_method.dart';
import '../service/analysis_service.dart';
import '../service/image_input_service.dart';

const _previewAsset = 'docs/design-references/이미지소스/미리보기 이미지.png';
const _samplePhotoAsset = 'docs/design-references/이미지소스/타이틀이미지.png';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key, required this.inputService});

  final ImageInputService inputService;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  ImageInput? _input;
  AnalysisMethod _selectedMethod = AnalysisMethod.imageClassification;
  bool _isPicking = false;

  Future<void> _showSourcePicker() async {
    if (_isPicking) return;
    final source = await showModalBottomSheet<ImageSourceType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('사진 가져오기', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () => Navigator.pop(context, ImageSourceType.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () => Navigator.pop(context, ImageSourceType.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _selectImage(source);
  }

  Future<void> _selectImage(ImageSourceType source) async {
    setState(() => _isPicking = true);
    try {
      final input = await widget.inputService.pick(source);
      if (mounted && input != null) setState(() => _input = input);
    } on ImagePermissionDeniedException {
      if (mounted) await _showPermissionDialog();
    } on ImageInputUnavailableException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _startAnalysis(AnalysisMethod method) async {
    setState(() => _selectedMethod = method);
    if (_input == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('먼저 분석할 사진을 추가해 주세요.')));
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.loading,
      arguments: AnalysisRequest(method: method, input: _input!),
    );
  }

  Future<void> _showPermissionDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => const _PermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(30, 64, 30, 30),
              children: [
                Text(
                  '사진 선택',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 6),
                Text(
                  '촬영하거나 갤러리에서 사진을 선택하세요.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: const Color(0xFF737784)),
                ),
                const SizedBox(height: 32),
                _PhotoPicker(
                  selected: _input != null,
                  isLoading: _isPicking,
                  onTap: _showSourcePicker,
                ),
                const SizedBox(height: 26),
                Row(
                  children: AnalysisMethod.values.reversed
                      .map(
                        (method) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right:
                                  method == AnalysisMethod.imageClassification
                                  ? 10
                                  : 0,
                            ),
                            child: _AnalysisMethodButton(
                              method: method,
                              selected: method == _selectedMethod,
                              onTap: () => _startAnalysis(method),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _isPicking ? null : _showSourcePicker,
                  child: const Text('다른 사진 선택'),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.history),
                  child: const Text('분석 이력 보기'),
                ),
                const SizedBox(height: 18),
                Text(
                  '원본 사진은 이력에 저장되지 않습니다.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.selected,
    required this.isLoading,
    required this.onTap,
  });

  final bool selected;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.98,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFABADB5), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: selected
                    ? EdgeInsets.zero
                    : const EdgeInsets.fromLTRB(30, 34, 30, 22),
                child: Opacity(
                  opacity: selected ? 1 : 0.3,
                  child: Transform.scale(
                    scale: selected ? 1 : 1.25,
                    child: Image.asset(
                      selected ? _samplePhotoAsset : _previewAsset,
                      fit: selected ? BoxFit.cover : BoxFit.contain,
                    ),
                  ),
                ),
              ),
              if (!selected)
                Center(
                  child: Text(
                    '분석할 사진을 추가해 주세요',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 20),
                  ),
                ),
              if (isLoading)
                const ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisMethodButton extends StatelessWidget {
  const _AnalysisMethodButton({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final AnalysisMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? const Color(0xFFEDEBFF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? primary : const Color(0xFFD9DCE6),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 22),
          child: Column(
            children: [
              Text(
                method.title,
                style: const TextStyle(
                  color: Color(0xFF151927),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                method.description,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF777B88)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      backgroundColor: const Color(0xFFFFFBFB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF6B72)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.outlined(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            const _StatusBadge(label: '권한 거부'),
            const SizedBox(height: 12),
            Text('카메라 권한이 필요해요', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 18),
            const Text(
              '사진을 촬영하려면 카메라 접근이 필요합니다.\n권한을 허용하지 않아도 갤러리 선택은 계속 사용할 수 있어요.',
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('설정에서 권한 열기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC5C8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
