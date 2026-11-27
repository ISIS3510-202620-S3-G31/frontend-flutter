import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/fortune_card_model.dart';
import '../../../../data/models/fortune_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/fortune_cookie_view_model.dart';
import 'fortune_paper.dart';

/// "My collection": the fortunes the user kept and the cards they shared.
///
/// It shares the Fortune Cookie's view model, so a change here shows on the
/// cookie screen too.
class FortuneCollectionScreen extends StatefulWidget {
  const FortuneCollectionScreen({
    super.key,
    required this.viewModel,
    this.initialTab = 0,
  });

  final FortuneCookieViewModel viewModel;

  /// 0 for Kept, 1 for Shared.
  final int initialTab;

  @override
  State<FortuneCollectionScreen> createState() =>
      _FortuneCollectionScreenState();
}

class _FortuneCollectionScreenState extends State<FortuneCollectionScreen> {
  static final _day = DateFormat('MMM d');

  late int _tab = widget.initialTab;

  FortuneCookieViewModel get _viewModel => widget.viewModel;

  Future<bool> _confirm({
    required String title,
    required String body,
    required String keep,
    required String remove,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(title, style: fortuneHeadline(22)),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(keep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(remove),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _letGo(Fortune fortune) async {
    final confirmed = await _confirm(
      title: 'Let this fortune go?',
      body:
          'It will leave your Kept list. You can keep it again the next time '
          'you see it.',
      keep: 'Keep it',
      remove: 'Let it go',
    );
    if (confirmed) await _viewModel.toggleKept(fortune);
  }

  Future<void> _removeCard(FortuneCard card) async {
    final confirmed = await _confirm(
      title: 'Remove this image?',
      body:
          "It will leave your Shared list. The copy in your phone's gallery "
          'stays.',
      keep: 'Keep it',
      remove: 'Remove',
    );
    if (confirmed) await _viewModel.removeCard(card);
  }

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_showMessage);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_showMessage);
    super.dispose();
  }

  /// The cookie screen listens too; only the screen on top shows messages.
  void _showMessage() {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final message = _viewModel.takeMessage();
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [FortuneColors.backdropTop, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: Text('My collection', style: fortuneHeadline(30)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: _Tabs(
                    selected: _tab,
                    kept: _viewModel.kept.length,
                    shared: _viewModel.cards.length,
                    onSelect: (tab) => setState(() => _tab = tab),
                  ),
                ),
                Expanded(child: _tab == 0 ? _keptList() : _sharedGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _keptList() {
    final kept = _viewModel.kept;
    if (kept.isEmpty) {
      return const _Empty(
        title: 'Nothing kept yet',
        body:
            'Open a cookie and tap Keep to save the fortunes you want to '
            'remember.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: kept.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final fortune = kept[index];
        return _KeptCard(
          fortune: fortune,
          day: _day.format(fortune.savedAt),
          sharing: _viewModel.isSharing,
          onShare: () => _viewModel.share(fortune),
          onRemove: () => _letGo(fortune),
        );
      },
    );
  }

  Widget _sharedGrid() {
    final cards = _viewModel.cards;
    if (cards.isEmpty) {
      return const _Empty(
        title: 'Nothing shared yet',
        body: 'When you share a fortune, its image waits for you here.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final tileWidth = (constraints.maxWidth - 48 - spacing) / 2;
        // Decoded at the size of the tile, not at the card's 1080 px.
        final decodeWidth = (tileWidth * MediaQuery.devicePixelRatioOf(context))
            .round();
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1080 / 1350,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _SharedTile(
              card: card,
              day: _day.format(card.savedAt),
              decodeWidth: decodeWidth,
              onOpen: () => _showCard(card),
              onShare: () => _viewModel.shareAgain(card),
              onRemove: () => _removeCard(card),
            );
          },
        );
      },
    );
  }

  void _showCard(FortuneCard card) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(File(card.localPath)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  tooltip: 'Share again',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                  onPressed: () => _viewModel.shareAgain(card),
                  icon: const Icon(Icons.share, color: AppColors.background),
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.kept,
    required this.shared,
    required this.onSelect,
  });

  final int selected;
  final int kept;
  final int shared;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tab(int index, IconData icon, String label, int count) {
      final active = index == selected;
      return Expanded(
        child: Material(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onSelect(index),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FortuneColors.backdropTop.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          tab(0, Icons.favorite, 'Kept', kept),
          tab(1, Icons.share, 'Shared', shared),
        ],
      ),
    );
  }
}

class _KeptCard extends StatelessWidget {
  const _KeptCard({
    required this.fortune,
    required this.day,
    required this.sharing,
    required this.onShare,
    required this.onRemove,
  });

  final Fortune fortune;
  final String day;
  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [FortuneColors.paperTop, FortuneColors.paperBottom],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            fortune.quote,
            textAlign: TextAlign.center,
            style: fortuneHeadline(18),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    color: FortuneColors.mutedText,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Share this fortune',
                onPressed: sharing ? null : onShare,
                icon: const Icon(Icons.share, color: AppColors.secondary),
              ),
              IconButton(
                tooltip: 'Remove from Kept',
                onPressed: onRemove,
                icon: const Icon(Icons.favorite, color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharedTile extends StatelessWidget {
  const _SharedTile({
    required this.card,
    required this.day,
    required this.decodeWidth,
    required this.onOpen,
    required this.onShare,
    required this.onRemove,
  });

  final FortuneCard card;
  final String day;
  final int decodeWidth;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onOpen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(card.localPath),
              fit: BoxFit.cover,
              cacheWidth: decodeWidth,
              semanticLabel: card.quote,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 16, 4, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.text.withValues(alpha: 0),
                      AppColors.text.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Share again',
                      visualDensity: VisualDensity.compact,
                      onPressed: onShare,
                      icon: const Icon(
                        Icons.share,
                        size: 18,
                        color: AppColors.background,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove from Shared',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: fortuneHeadline(22)),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: FortuneColors.mutedText),
          ),
        ],
      ),
    );
  }
}
