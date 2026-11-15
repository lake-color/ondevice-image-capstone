import 'dart:io';

import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../app/app_theme.dart';
import '../domain/analysis_method.dart';
import '../domain/exceptions.dart';
import '../service/analysis_service.dart';
import '../service/image_input_service.dart';
import 'notice_card.dart';

const _previewAsset = 'assets/images/미리보기 이미지.png';

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
                subtitle: const Text('촬영을 위해 카메라 권한을 요청해요. 사진은 기기 안에서만 사용합니다.'),
                onTap: () => Navigator.pop(context, ImageSourceType.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                subtitle: const Text('직접 고른 사진 한 장만 앱에 전달됩니다.'),
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
    var permissionDenied = false;
    try {
      final input = await widget.inputService.pick(source);
      if (mounted && input != null) {
        await FileImage(File(input.path)).evict();
        if (mounted) setState(() => _input = input);
      }
    } on ImagePermissionDeniedException {
      permissionDenied = true;
    } on ImageInputUnavailableException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
    // Shown after picking has ended so the spinner does not keep running
    // behind the dialog.
    if (permissionDenied && mounted) await _showPermissionDialog(source);
  }

  Future<void> _startAnalysis(AnalysisMethod method) async {
    if (_input == null || _isPicking) return;
    setState(() => _selectedMethod = method);
    await Navigator.pushNamed(
      context,
      AppRoutes.loading,
      arguments: AnalysisRequest(method: method, input: _input!),
    );
  }

  Future<void> _showPermissionDialog(ImageSourceType source) {
    return showDialog<void>(
      context: context,
      builder: (context) => _PermissionDialog(
        source: source,
        onOpenSettings: widget.inputService.openPermissionSettings,
      ),
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
                  imagePath: _input?.path,
                  isLoading: _isPicking,
                  onTap: _showSourcePicker,
                ),
                if (_input != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _input!.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
                              onTap: _input == null || _isPicking
                                  ? null
                                  : () => _startAnalysis(method),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _isPicking ? null : _showSourcePicker,
                  child: Text(_input == null ? '사진 가져오기' : '다른 사진 선택'),
                ),
                const SizedBox(height: 18),
                Text(
                  '사진은 서버로 전송하지 않고 기기 안에서만 분석합니다.',
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
    required this.imagePath,
    required this.isLoading,
    required this.onTap,
  });

  final String? imagePath;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = imagePath != null;
    return AspectRatio(
      aspectRatio: 0.98,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.2),
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
                    child: selected
                        ? Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text('사진을 불러올 수 없습니다. 다시 선택해 주세요.'),
                            ),
                          )
                        : Image.asset(_previewAsset, fit: BoxFit.contain),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Material(
          color: selected ? const Color(0xFFEDEBFF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? primary : AppColors.border,
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
                      color: AppColors.text,
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
        ),
      ),
    );
  }
}

class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog({required this.source, required this.onOpenSettings});

  /// The source whose access was denied; decides which wording is shown.
  final ImageSourceType source;
  final Future<void> Function() onOpenSettings;

  Future<void> _openSettings(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      await onOpenSettings();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('설정을 열지 못했습니다. 기기 설정에서 앱 권한을 직접 변경해 주세요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (source) {
      ImageSourceType.camera => (
        '카메라 권한이 필요해요',
        '사진을 촬영하려면 카메라 접근이 필요합니다.\n'
            '설정 > 권한 > 카메라에서 허용할 수 있어요.\n'
            '허용하지 않아도 갤러리 선택은 계속 사용할 수 있습니다.',
      ),
      ImageSourceType.gallery => (
        '사진 접근 권한이 필요해요',
        '갤러리에서 사진을 선택하려면 사진 접근이 필요합니다.\n'
            '설정 > 권한 > 사진에서 허용할 수 있어요.\n'
            '허용하지 않아도 카메라 촬영은 계속 사용할 수 있습니다.',
      ),
    };
    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: NoticeCard(
        badge: '권한 거부',
        title: title,
        message: body,
        actionLabel: '설정에서 권한 열기',
        onAction: () => _openSettings(context),
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
