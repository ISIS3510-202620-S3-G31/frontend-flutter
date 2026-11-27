import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../../domain/cookie_jar/cookie_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../view_model/cookie_jar_view_model.dart';
import 'cookie_list_sheet.dart';

Future<void> showCookieDetail(
  BuildContext context,
  CookieJarViewModel viewModel,
  CookieModel cookie,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => CookieDetailDialog(viewModel: viewModel, cookie: cookie),
  );
}

/// A cookie opened: title, who gave it, photo and text, plus its actions.
class CookieDetailDialog extends StatefulWidget {
  const CookieDetailDialog({
    super.key,
    required this.viewModel,
    required this.cookie,
  });

  final CookieJarViewModel viewModel;
  final CookieModel cookie;

  @override
  State<CookieDetailDialog> createState() => _CookieDetailDialogState();
}

class _CookieDetailDialogState extends State<CookieDetailDialog> {
  /// Read once when the dialog opens: from RAM, then the private file.
  late final Future<Uint8List?> _photo = widget.viewModel.photoOf(
    widget.cookie,
  );

  @override
  void initState() {
    super.initState();
    widget.viewModel.opened(widget.cookie);
  }

  Future<void> _run(Future<void> Function(CookieModel) action) async {
    final cookie = widget.cookie;
    Navigator.pop(context);
    await action(cookie);
  }

  Future<void> _deleteForever() async {
    if (!await confirmDeleteForever(context) || !mounted) return;
    await _run(widget.viewModel.deleteForever);
  }

  @override
  Widget build(BuildContext context) {
    final cookie = widget.cookie;
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(cookie.title, style: AppText.h2),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (cookie.receivedFrom != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '🎁 from @${cookie.receivedFrom}',
                        style: AppText.bodyMuted,
                      ),
                    ),
                  if (cookie.hasImage) ...[
                    const SizedBox(height: 16),
                    _CookiePhoto(photo: _photo),
                  ],
                  const SizedBox(height: 16),
                  Text(cookie.text, style: AppText.body.copyWith(fontSize: 16)),
                  const SizedBox(height: 24),
                  if (cookie.isActive)
                    _ActionButton(
                      label: 'Eat 🍪',
                      color: AppColors.primary,
                      onPressed: () => _run(widget.viewModel.eat),
                    )
                  else ...[
                    _ActionButton(
                      label: 'Return to jar',
                      color: AppColors.secondary,
                      onPressed: () => _run(widget.viewModel.returnToJar),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _deleteForever,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete forever'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CookiePhoto extends StatelessWidget {
  const _CookiePhoto({required this.photo});

  final Future<Uint8List?> photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: FutureBuilder<Uint8List?>(
          future: photo,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes != null) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                semanticLabel: 'Picture of the cookie',
                gaplessPlayback: true,
              );
            }
            return ColoredBox(
              color: AppColors.surfaceDim,
              child: Center(
                child: snapshot.connectionState == ConnectionState.done
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          CookieMessages.pictureNotHere,
                          style: AppText.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.text,
        ),
        child: Text(label, style: AppText.h3),
      ),
    );
  }
}
