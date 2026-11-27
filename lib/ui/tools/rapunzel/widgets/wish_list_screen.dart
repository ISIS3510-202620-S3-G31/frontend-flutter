import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/wish_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/wish_list_view_model.dart';
import 'lantern_icon.dart';
import 'wish_editor_screen.dart';

/// Shown when the phone has no connection, on the list and the sky.
const String kWishesOfflineMessage =
    "You're offline. Your wishes may not be up to date.";

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key, this.viewModel});

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final WishListViewModel? viewModel;

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  static final _dateFormat = DateFormat('MMM d, yyyy');

  late final WishListViewModel _viewModel =
      widget.viewModel ?? WishListViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  String? _shownDeleteId;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    unawaited(_viewModel.load());
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final message = _viewModel.takeMessage();
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    final toDelete = _viewModel.wishToDelete;
    if (toDelete == null) {
      _shownDeleteId = null;
    } else if (mounted && _shownDeleteId != toDelete.id) {
      _shownDeleteId = toDelete.id;
      unawaited(_showDeleteConfirmation(toDelete));
    }
  }

  Future<void> _showDeleteConfirmation(Wish wish) async {
    await showDialog<void>(
      context: context,
      builder: (context) => DeleteWishDialog(
        wish: wish,
        onConfirm: () {
          Navigator.maybePop(context);
          unawaited(_viewModel.confirmDelete());
        },
        onCancel: () {
          Navigator.maybePop(context);
          _viewModel.cancelDelete();
        },
      ),
    );
    _viewModel.cancelDelete();
  }

  /// Opens the editor — empty for a new wish, with [wish] to change it — and
  /// reloads the list when it closes.
  Future<void> _openEditor({Wish? wish}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WishEditorScreen(editing: wish)),
    );
    if (mounted) unawaited(_viewModel.refresh());
  }

  @override
  Widget build(BuildContext context) {
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
                  ScreenHeader(title: Text('All my wishes', style: AppText.h1)),
                  OfflineBanner(
                    offline: _viewModel.isOffline,
                    message: kWishesOfflineMessage,
                  ),
                  Expanded(
                    child: switch ((
                      _viewModel.isLoading,
                      _viewModel.wishes.isEmpty,
                    )) {
                      (true, _) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      (false, true) => _EmptyWishes(
                        onWriteWish: () => _openEditor(),
                      ),
                      (false, false) => ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: _viewModel.wishes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final wish = _viewModel.wishes[index];
                          return _WishRow(
                            wish: wish,
                            onEdit: () => _openEditor(wish: wish),
                            onDelete: () => _viewModel.askToDelete(wish),
                          );
                        },
                      ),
                    },
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

/// One row of the list: the wish, its date and the edit and delete buttons.
class _WishRow extends StatelessWidget {
  const _WishRow({
    required this.wish,
    required this.onEdit,
    required this.onDelete,
  });

  final Wish wish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          const LanternIcon(lit: true, width: 28, height: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wish.text, style: AppText.body),
                Text(
                  _WishListScreenState._dateFormat.format(wish.createdAt),
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.text),
            tooltip: 'Edit wish',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.accent),
            tooltip: 'Delete wish',
          ),
        ],
      ),
    );
  }
}

/// When there are no wishes yet: an unlit lantern and a way to write one.
class _EmptyWishes extends StatelessWidget {
  const _EmptyWishes({required this.onWriteWish});

  final VoidCallback onWriteWish;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LanternIcon(lit: false, width: 80, height: 100),
            const SizedBox(height: 16),
            Text(
              "You haven't written any wishes yet.",
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onWriteWish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text,
                shape: const StadiumBorder(),
                textStyle: AppText.h3.copyWith(fontWeight: FontWeight.w600),
              ),
              child: const Text('Write a wish'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks before deleting: the wish's lantern disappears from the sky too.
class DeleteWishDialog extends StatelessWidget {
  const DeleteWishDialog({
    super.key,
    required this.wish,
    required this.onConfirm,
    required this.onCancel,
  });

  final Wish wish;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDim,
      title: Text('Delete this wish?', style: AppText.h3),
      content: Text(
        '"${wish.text}" will be deleted and its lantern will disappear from the sky.',
        style: AppText.body,
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel', style: AppText.body),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            'Delete',
            style: AppText.body.copyWith(color: AppColors.accent),
          ),
        ),
      ],
    );
  }
}
