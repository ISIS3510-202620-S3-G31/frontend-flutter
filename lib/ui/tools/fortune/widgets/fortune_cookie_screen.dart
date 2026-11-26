import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/fortune_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/fortune_cookie_view_model.dart';
import 'fortune_collection_screen.dart';
import 'fortune_paper.dart';
import 'fortune_stage.dart';

class FortuneCookieScreen extends StatefulWidget {
  const FortuneCookieScreen({super.key, this.viewModel});

  final FortuneCookieViewModel? viewModel;

  @override
  State<FortuneCookieScreen> createState() => _FortuneCookieScreenState();
}

class _FortuneCookieScreenState extends State<FortuneCookieScreen> {
  late final FortuneCookieViewModel _viewModel =
      widget.viewModel ?? FortuneCookieViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel
      ..addListener(_showMessage)
      ..load();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_showMessage);
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  /// My collection listens too; only the screen on top shows messages.
  void _showMessage() {
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    final message = _viewModel.takeMessage();
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _leave() => Navigator.maybePop(context, _viewModel.isCompleted);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final previewing = _viewModel.preview != null;
        final shown = _viewModel.shownFortune;
        return PopScope(
          // Back while reading a recent phrase returns to the cookies.
          canPop: !previewing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _viewModel.closeRecent();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              body: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [FortuneColors.backdropTop, AppColors.background],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final choosingHeight = (constraints.maxHeight * 0.42)
                          .clamp(280.0, 420.0);
                      return Column(
                        children: [
                          ScreenHeader(
                            title: Text(
                              'Fortune cookie',
                              style: fortuneHeadline(30),
                            ),
                            onBack: previewing
                                ? _viewModel.closeRecent
                                : _leave,
                          ),
                          if (_viewModel.isChoosing)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _CollectionShortcut(
                                    label: 'Kept',
                                    count: _viewModel.kept.length,
                                    icon: Icons.favorite,
                                    color: AppColors.accent,
                                    onOpen: () => _openCollection(0),
                                  ),
                                  const SizedBox(width: 10),
                                  _CollectionShortcut(
                                    label: 'Shared',
                                    count: _viewModel.cards.length,
                                    icon: Icons.share,
                                    color: AppColors.secondary,
                                    onOpen: () => _openCollection(1),
                                  ),
                                ],
                              ),
                            ),
                          if (!previewing)
                            _ChancesLeft(
                              remaining: _viewModel.chancesLeft,
                              showHint: _viewModel.isChoosing,
                              offlineNotice: _viewModel.isChoosing
                                  ? _viewModel.offlineNotice
                                  : null,
                            ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
                            height: _viewModel.isChoosing
                                ? choosingHeight
                                : 300,
                            child: FortuneStage(
                              phase: _viewModel.phase,
                              chosenIndex: _viewModel.chosenIndex,
                              hasChances: _viewModel.hasChances,
                              previewing: previewing,
                              onCrack: _viewModel.crack,
                              paper: shown == null
                                  ? null
                                  : FortunePaper(quote: shown.quote),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: _viewModel.isChoosing ? 8 : 20,
                            ),
                            child: _bottom(),
                          ),
                          const Spacer(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// What goes under the table changes with the moment.
  Widget _bottom() {
    final preview = _viewModel.preview;
    if (preview != null) {
      return _RevealActions(
        kept: _viewModel.isKept(preview),
        sharing: _viewModel.isSharing,
        onToggleKept: () => _viewModel.toggleKept(preview),
        onShare: () => _viewModel.share(preview),
        mainLabel: 'Back to cookies',
        onMain: _viewModel.closeRecent,
      );
    }
    final opened = _viewModel.opened;
    return switch (_viewModel.phase) {
      FortunePhase.revealed when opened != null => _RevealActions(
        kept: _viewModel.isKept(opened),
        sharing: _viewModel.isSharing,
        onToggleKept: () => _viewModel.toggleKept(opened),
        onShare: () => _viewModel.share(opened),
        mainLabel: "I'm done",
        onMain: _leave,
      ),
      FortunePhase.choosing => _RecentFortunes(
        recents: _viewModel.recents,
        isKept: _viewModel.isKept,
        onOpen: _viewModel.openRecent,
      ),
      _ => const SizedBox(height: 100),
    };
  }

  void _openCollection(int tab) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          FortuneCollectionScreen(viewModel: _viewModel, initialTab: tab),
    ),
  );
}

/// Keep and Share the phrase, and the main button to go on.
class _RevealActions extends StatelessWidget {
  const _RevealActions({
    required this.kept,
    required this.sharing,
    required this.onToggleKept,
    required this.onShare,
    required this.mainLabel,
    required this.onMain,
  });

  final bool kept;
  final bool sharing;
  final VoidCallback onToggleKept;
  final VoidCallback onShare;
  final String mainLabel;
  final VoidCallback onMain;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FortunePill(
              label: kept ? 'Kept' : 'Keep',
              icon: kept ? Icons.favorite : Icons.favorite_border,
              iconColor: AppColors.accent,
              onPressed: onToggleKept,
            ),
            const SizedBox(width: 12),
            FortunePill(
              label: sharing ? 'Preparing…' : 'Share',
              icon: Icons.share,
              iconColor: AppColors.secondary,
              onPressed: sharing ? null : onShare,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FortunePill(
          label: mainLabel,
          solid: true,
          width: 268,
          onPressed: onMain,
        ),
      ],
    );
  }
}

/// A shortcut to one list of My collection, above the cookies.
class _CollectionShortcut extends StatelessWidget {
  const _CollectionShortcut({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onOpen,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Material(
        color: FortuneColors.backdropTop.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's cookies as orange dots, and the hint to pick one.
class _ChancesLeft extends StatelessWidget {
  const _ChancesLeft({
    required this.remaining,
    required this.showHint,
    required this.offlineNotice,
  });

  final int remaining;
  final bool showHint;
  final String? offlineNotice;

  @override
  Widget build(BuildContext context) {
    // Nothing until the count is read from the phone.
    if (remaining < 0) return const SizedBox(height: 48);
    final label = switch (remaining) {
      0 => 'No cookies left today. Come back tomorrow.',
      1 => '1 cookie left today',
      _ => '$remaining cookies left today',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < remaining
                        ? AppColors.primary
                        : AppColors.text.withValues(alpha: 0.14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: FortuneColors.mutedText),
          ),
          if (showHint && remaining > 0) ...[
            const SizedBox(height: 10),
            const Text(
              'Pick one. A little wisdom is waiting inside.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
          if (offlineNotice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: FortuneColors.backdropTop.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      offlineNotice!,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The last phrases opened, to read again without spending a cookie.
class _RecentFortunes extends StatelessWidget {
  const _RecentFortunes({
    required this.recents,
    required this.isKept,
    required this.onOpen,
  });

  final List<Fortune> recents;
  final bool Function(Fortune) isKept;
  final ValueChanged<Fortune> onOpen;

  @override
  Widget build(BuildContext context) {
    if (recents.isEmpty) return const SizedBox(height: 44);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Text('Recent cookies', style: fortuneHeadline(26)),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: recents.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final fortune = recents[index];
              return Material(
                color: FortuneColors.backdropTop.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                elevation: 1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onOpen(fortune),
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fortune.quote,
                          maxLines: isKept(fortune) ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.35),
                        ),
                        if (isKept(fortune)) ...[
                          const SizedBox(height: 6),
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppColors.accent,
                            semanticLabel: 'Kept',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
