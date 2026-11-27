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
  /// RAM, then the private file, then the cloud.
  late Future<PhotoLoad> _photo = _load();
  PhotoStatus? _status;

  Future<PhotoLoad> _load() async {
    final load = await widget.viewModel.loadPhoto(widget.cookie);
    _status = load.status;
    return load;
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.opened(widget.cookie);
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_status == PhotoStatus.offline && widget.viewModel.isOnline) _retry();
  }

  void _retry() => setState(() => _photo = _load());

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
                    _CookiePhoto(photo: _photo, onRetry: _retry),
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
  const _CookiePhoto({required this.photo, required this.onRetry});

  final Future<PhotoLoad> photo;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: FutureBuilder<PhotoLoad>(
          future: photo,
          builder: (context, snapshot) {
            final load = snapshot.data;
            final bytes = load?.bytes;
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
                child: load == null
                    ? const CircularProgressIndicator()
                    : _notice(load.status),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _notice(PhotoStatus status) {
    final text = switch (status) {
      PhotoStatus.offline => CookieMessages.pictureWhenOnline,
      PhotoStatus.failed => CookieMessages.pictureFailed,
      _ => CookieMessages.pictureNotHere,
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cookie_outlined, size: 40),
          const SizedBox(height: 8),
          Text(text, style: AppText.bodyMuted, textAlign: TextAlign.center),
          if (status == PhotoStatus.failed)
            TextButton(
              onPressed: onRetry,
              child: const Text(CookieMessages.retry),
            ),
        ],
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
