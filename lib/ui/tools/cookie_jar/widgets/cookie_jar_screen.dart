import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../../data/repositories/cookie_repository.dart';
import '../../../../domain/cookie_jar/cookie_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/cookie_jar_view_model.dart';
import '../view_model/cookie_social_view_model.dart';
import 'cookie_detail_dialog.dart';
import 'cookie_friends_screen.dart';
import 'cookie_inbox_screen.dart';
import 'cookie_jar_drawing.dart';
import 'cookie_list_sheet.dart';
import 'new_cookie_screen.dart';

class CookieJarScreen extends StatefulWidget {
  const CookieJarScreen({super.key, this.viewModel, this.socialViewModel});

  final CookieJarViewModel? viewModel;
  final CookieSocialViewModel? socialViewModel;

  @override
  State<CookieJarScreen> createState() => _CookieJarScreenState();
}

class _CookieJarScreenState extends State<CookieJarScreen> {
  late final CookieJarViewModel _viewModel =
      widget.viewModel ?? CookieJarViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  late final CookieSocialViewModel _social =
      widget.socialViewModel ?? CookieSocialViewModel();
  late final bool _ownsSocial = widget.socialViewModel == null;
  StreamSubscription<CookieMessage>? _messages;
  StreamSubscription<CookieMessage>? _socialMessages;

  @override
  void initState() {
    super.initState();
    _messages = _viewModel.messages.listen(_showMessage);
    _socialMessages = _social.messages.listen(_showMessage);
    _social.onOpenInbox = _openInbox;
    _viewModel.start();
    _social.start();
  }

  @override
  void dispose() {
    _messages?.cancel();
    _socialMessages?.cancel();
    if (_ownsViewModel) _viewModel.dispose();
    if (_ownsSocial) _social.dispose();
    super.dispose();
  }

  void _openInbox() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookieInboxScreen(viewModel: _social),
        settings: const RouteSettings(name: '/tools/cookie_jar/inbox'),
      ),
    );
  }

  void _openFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookieFriendsScreen(viewModel: _social),
        settings: const RouteSettings(name: '/tools/cookie_jar/friends'),
      ),
    );
  }

  void _openDetail(CookieModel cookie) =>
      showCookieDetail(context, _viewModel, cookie, social: _social);

  /// Every notice of the tool is a Snackbar at the bottom.
  void _showMessage(CookieMessage message) {
    if (!mounted) return;
    final onAction = message.onAction;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message.text),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: message.long ? 6 : 3),
          action: message.actionLabel != null && onAction != null
              ? SnackBarAction(label: message.actionLabel!, onPressed: onAction)
              : null,
        ),
      );
  }

  Future<void> _newCookie() async {
    final created = await Navigator.push<CreatedCookie>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewCookieScreen(),
        settings: const RouteSettings(name: '/tools/cookie_jar/new'),
      ),
    );
    if (created != null) _viewModel.created(created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_viewModel, _social]),
          builder: (context, _) => Column(
            children: [
              ScreenHeader(
                title: Text('Cookie jar', style: AppText.h1),
                subtitle: 'Your memories and wins, one cookie each',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () => showCookieList(
                            context,
                            _viewModel,
                            social: _social,
                          ),
                          icon: const Icon(Icons.list_alt),
                          label: Text(
                            'All my cookies (${_viewModel.inJar.length + _viewModel.eaten.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surfaceDim,
                            foregroundColor: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    if (_social.isAdult) ...[
                      const SizedBox(width: 8),
                      _SocialButton(
                        tooltip: 'Gift inbox',
                        icon: Icons.redeem,
                        badge: _social.badgeCount,
                        online: _social.isOnline,
                        onPressed: _openInbox,
                      ),
                      const SizedBox(width: 8),
                      _SocialButton(
                        tooltip: 'Friends',
                        icon: Icons.people_alt_outlined,
                        online: _social.isOnline,
                        onPressed: _openFriends,
                      ),
                    ],
                  ],
                ),
              ),
              if (_viewModel.pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text(
                    CookieMessages.waitingToUpload(_viewModel.pendingCount),
                    style: AppText.bodyMuted,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
                  child: Center(child: _jar()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _newCookie,
                    icon: const Icon(Icons.add),
                    label: Text('Bake a cookie', style: AppText.h3),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jar() {
    if (_viewModel.loading) return const CircularProgressIndicator();
    final today = _viewModel.today;
    return Stack(
      alignment: Alignment.center,
      children: [
        CookieJarDrawing(cookies: today, onCookieTap: _openDetail),
        if (today.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _viewModel.eaten.isEmpty
                  ? 'Your jar is empty.\nBake your first cookie: a memory or a win you want to keep.'
                  : 'Your jar is empty.\nBake a new cookie or return one you ate.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.tooltip,
    required this.icon,
    required this.online,
    required this.onPressed,
    this.badge = 0,
  });

  final String tooltip;
  final IconData icon;
  final bool online;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: online ? 1 : 0.45,
      child: IconButton.filled(
        tooltip: online ? tooltip : '$tooltip (offline)',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.text,
        ),
        icon: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          backgroundColor: AppColors.accent,
          child: Icon(online ? icon : Icons.wifi_off),
        ),
      ),
    );
  }
}
