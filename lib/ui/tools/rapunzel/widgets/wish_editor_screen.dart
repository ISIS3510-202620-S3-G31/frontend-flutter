import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/wish_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/wish_editor_view_model.dart';
import 'lantern_icon.dart';

/// Shown when the phone has no connection, on the editor and the list.
const String kEditorOfflineMessage =
    "You're offline. Your wish will be saved when you're back online.";

class WishEditorScreen extends StatefulWidget {
  const WishEditorScreen({super.key, this.editing, this.viewModel});

  /// The wish being changed, or null when writing a new one.
  final Wish? editing;

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final WishEditorViewModel? viewModel;

  @override
  State<WishEditorScreen> createState() => _WishEditorScreenState();
}

class _WishEditorScreenState extends State<WishEditorScreen> {
  late final WishEditorViewModel _viewModel =
      widget.viewModel ?? WishEditorViewModel(editing: widget.editing);
  late final bool _ownsViewModel = widget.viewModel == null;
  late final TextEditingController _controller = TextEditingController(
    text: _viewModel.text,
  );

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _controller.dispose();
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    // The view model caps the text; the field follows, so the counter and
    // the field never disagree.
    if (_controller.text != _viewModel.text) {
      _controller.value = TextEditingValue(
        text: _viewModel.text,
        selection: TextSelection.collapsed(offset: _viewModel.text.length),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final saved = await _viewModel.save();
    if (saved && mounted) Navigator.maybePop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = _viewModel.isEditing;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                children: [
                  ScreenHeader(
                    title: Text(
                      editing ? 'Edit wish' : 'Write a wish',
                      style: AppText.h1,
                    ),
                  ),
                  _OfflineBanner(offline: _viewModel.isOffline),
                  const SizedBox(height: 16),
                  const LanternIcon(lit: false, width: 80, height: 100),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 4,
                      maxLength: Wish.maxLength,
                      // The counter is drawn below, like the Kotlin app.
                      decoration: InputDecoration(
                        hintText: 'I wish...',
                        hintStyle: AppText.bodyMuted,
                        filled: true,
                        fillColor: AppColors.surfaceDim,
                        counterText: '',
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      style: AppText.body,
                      onChanged: _viewModel.onTextChange,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_viewModel.text.length}/${Wish.maxLength}',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                  if (_viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _viewModel.errorMessage!,
                        style: AppText.body.copyWith(color: AppColors.accent),
                      ),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _viewModel.canSave ? _save : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.text,
                          disabledBackgroundColor: AppColors.surfaceDim,
                          disabledForegroundColor: AppColors.textMuted,
                          shape: const StadiumBorder(),
                          textStyle: AppText.h3.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _viewModel.isSaving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.text,
                                ),
                              )
                            : Text(
                                editing
                                    ? 'Save changes'
                                    : 'Save and light the lantern',
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The offline notice at the top of the editor and the list, drawn only
/// while there is no connection.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.offline,
    required this.message,
  });

  final bool offline;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!offline) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 20, color: AppColors.text),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: AppText.body)),
          ],
        ),
      ),
    );
  }
}

/// A small [OfflineBanner] bound to a message constant.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) =>
      OfflineBanner(offline: offline, message: kEditorOfflineMessage);
}
