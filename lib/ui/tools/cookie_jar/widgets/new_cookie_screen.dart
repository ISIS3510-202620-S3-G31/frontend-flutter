import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../domain/cookie_jar/cookie_messages.dart';
import '../../../../domain/cookie_jar/cookie_rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/new_cookie_view_model.dart';

class NewCookieScreen extends StatefulWidget {
  const NewCookieScreen({super.key, this.viewModel});

  final NewCookieViewModel? viewModel;

  static const micKey = ValueKey('cookie-mic');

  @override
  State<NewCookieScreen> createState() => _NewCookieScreenState();
}

class _NewCookieScreenState extends State<NewCookieScreen> {
  late final NewCookieViewModel _viewModel =
      widget.viewModel ?? NewCookieViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  final _title = TextEditingController();
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.prepareDictation();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  /// Set when the screen closes, so a late notification never pops twice.
  bool _closed = false;

  void _onViewModelChanged() {
    if (!mounted || _closed) return;
    final saved = _viewModel.saved;
    if (saved != null) {
      _closed = true;
      Navigator.pop(context, saved);
      return;
    }
    if (_text.text != _viewModel.text) {
      _text.value = TextEditingValue(
        text: _viewModel.text,
        selection: TextSelection.collapsed(offset: _viewModel.textCaret),
      );
    }
    final message = _viewModel.message;
    if (message != null) {
      _viewModel.clearMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// True while the finger slid far enough left to drop the dictation.
  bool _cancelling = false;
  static const _cancelDistance = 80.0;

  int get _caret =>
      _text.selection.isValid ? _text.selection.baseOffset : _text.text.length;

  void _startDictation() {
    _cancelling = false;
    HapticFeedback.mediumImpact();
    _viewModel.startDictation(at: _caret);
  }

  void _moveDictation(LongPressMoveUpdateDetails details) {
    final cancelling = details.offsetFromOrigin.dx < -_cancelDistance;
    if (cancelling != _cancelling) setState(() => _cancelling = cancelling);
  }

  void _endDictation() {
    if (_cancelling) {
      HapticFeedback.lightImpact();
      _viewModel.cancelDictation();
    } else {
      _viewModel.finishDictation();
    }
    setState(() => _cancelling = false);
  }

  void _explainDictation() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(CookieMessages.holdToDictate),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _micButton() {
    final recording = _viewModel.isRecording;
    final background = !recording
        ? AppColors.primary
        : _cancelling
        ? AppColors.surfaceDim
        : AppColors.accent;
    return Semantics(
      key: NewCookieScreen.micKey,
      button: true,
      label: recording ? 'Release to stop dictating' : 'Hold to dictate',
      child: Listener(
        onPointerCancel: (_) => _viewModel.finishDictation(),
        child: RawGestureDetector(
          gestures: {
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(
                    duration: const Duration(milliseconds: 150),
                  ),
                  (recognizer) => recognizer
                    ..onLongPressStart = ((_) => _startDictation())
                    ..onLongPressMoveUpdate = _moveDictation
                    ..onLongPressEnd = ((_) => _endDictation()),
                ),
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  TapGestureRecognizer.new,
                  (recognizer) => recognizer..onTap = _explainDictation,
                ),
          },
          child: AnimatedScale(
            scale: recording ? 1.3 : 1,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: recording && _cancelling
                  ? const Icon(Icons.delete_outline, color: AppColors.text)
                  : SvgPicture.asset(
                      'assets/icons/ic_mic.svg',
                      width: 22,
                      height: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String? get _dictationHelp {
    if (!_viewModel.isRecording) return null;
    return _cancelling
        ? 'Release to cancel'
        : '● Listening… release to finish, slide ← to cancel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Column(
            children: [
              ScreenHeader(
                title: Text('Bake a cookie', style: AppText.h1),
                subtitle: 'Mix in a memory or a win you want to keep',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Text('Title', style: AppText.h3),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _title,
                      onChanged: _viewModel.setTitle,
                      maxLength: CookieRules.maxTitleLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoration(
                        hint: 'My graduation',
                        error: _viewModel.titleError,
                        helper: _viewModel.willBeSavedAs,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text('Your memory', style: AppText.h3)),
                        if (_viewModel.canDictate) ...[
                          if (!_viewModel.isRecording)
                            Text('Hold to dictate', style: AppText.bodyMuted),
                          const SizedBox(width: 12),
                          _micButton(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _text,
                      onChanged: _viewModel.setText,
                      maxLength: CookieRules.maxTextLength,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoration(
                        hint: 'What happened and why it matters to you',
                        error: _viewModel.textError,
                        helper: _dictationHelp,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Photo (optional)', style: AppText.h3),
                    const SizedBox(height: 8),
                    _photo(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _viewModel.saving ? null : _viewModel.save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text,
                    ),
                    child: _viewModel.saving
                        ? const CircularProgressIndicator()
                        : Text('Bake cookie 🍪', style: AppText.h3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo() {
    final photo = _viewModel.photo;
    if (photo == null) {
      return OutlinedButton.icon(
        onPressed: _viewModel.takePhoto,
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Take a photo'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(52),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.memory(
              photo,
              fit: BoxFit.cover,
              semanticLabel: 'Picture for the cookie',
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            tooltip: 'Remove picture',
            onPressed: _viewModel.removePhoto,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.text,
              foregroundColor: AppColors.background,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration({
    required String hint,
    String? error,
    String? helper,
  }) => InputDecoration(
    hintText: hint,
    errorText: error,
    helperText: helper,
    filled: true,
    fillColor: AppColors.surfaceDim,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}
