import 'package:flutter/material.dart';

import '../../../../domain/cookie_jar/cookie_social_rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/cookie_social_view_model.dart';

class CookieFriendsScreen extends StatefulWidget {
  const CookieFriendsScreen({super.key, required this.viewModel});

  final CookieSocialViewModel viewModel;

  @override
  State<CookieFriendsScreen> createState() => _CookieFriendsScreenState();
}

class _CookieFriendsScreenState extends State<CookieFriendsScreen> {
  final _username = TextEditingController();
  final _search = TextEditingController();
  String? _usernameError;

  CookieSocialViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.loadFriends();
  }

  @override
  void dispose() {
    _username.dispose();
    _search.dispose();
    super.dispose();
  }

  void _activate() {
    final error = CookieSocialRules.usernameError(_username.text);
    setState(() => _usernameError = error);
    if (error == null) _viewModel.activate(_username.text);
  }

  Future<void> _sendRequest() async {
    if (CookieSocialRules.usernameError(_search.text) != null) return;
    await _viewModel.sendRequest(_search.text);
    _search.clear();
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
                title: Text('Friends', style: AppText.h1),
                subtitle: 'Share cookies with people you trust',
              ),
              if (!_viewModel.isOnline) const _OfflineStrip(),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_viewModel.loadingFriends && !_viewModel.friendsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_viewModel.friendsLoaded) {
      return Center(
        child: TextButton.icon(
          onPressed: _viewModel.loadFriends,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }
    final profile = _viewModel.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: profile == null ? _activation() : _activated(profile.username),
    );
  }

  List<Widget> _activation() => [
    _Card(
      children: [
        Text('Turn on friends', style: AppText.h3),
        const SizedBox(height: 8),
        Text(
          'Pick a username so friends can find you. They will only see your '
          'username, never your name, email or birth date. Gifts you get wait '
          'in your inbox for 7 days.',
          style: AppText.body,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _username,
          maxLength: 20,
          autocorrect: false,
          decoration: _decoration(
            'your_username',
            prefix: '@',
          ).copyWith(errorText: _usernameError),
        ),
        FilledButton(
          onPressed: _viewModel.busy ? null : _activate,
          style: _primary,
          child: const Text('Turn on friends'),
        ),
      ],
    ),
  ];

  List<Widget> _activated(String username) => [
    _Card(
      children: [
        Text('Your username', style: AppText.bodyMuted),
        Text('@$username', style: AppText.h2),
      ],
    ),
    const SizedBox(height: 16),
    Text('Add a friend', style: AppText.h3),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _search,
            autocorrect: false,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendRequest(),
            decoration: _decoration('exact username', prefix: '@'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Send request',
          onPressed: _viewModel.busy ? null : _sendRequest,
          icon: const Icon(Icons.person_add_alt_1),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.text,
          ),
        ),
      ],
    ),
    if (_viewModel.requests.isNotEmpty) ...[
      _Section('Requests (${_viewModel.requests.length})'),
      for (final request in _viewModel.requests)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text('@${request.fromUsername}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Decline',
                onPressed: _viewModel.busy
                    ? null
                    : () => _viewModel.declineRequest(request),
                icon: const Icon(Icons.close),
              ),
              IconButton(
                tooltip: 'Accept',
                onPressed: _viewModel.busy
                    ? null
                    : () => _viewModel.acceptRequest(request),
                icon: const Icon(Icons.check, color: AppColors.secondary),
              ),
            ],
          ),
        ),
    ],
    _Section('Friends (${_viewModel.friends.length})'),
    if (_viewModel.friends.isEmpty)
      Text(
        'No friends yet. Add one by their username.',
        style: AppText.bodyMuted,
      ),
    for (final friend in _viewModel.friends)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person),
        title: Text('@${friend.username}'),
        trailing: PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (choice) => choice == 'block'
              ? _viewModel.block(friend)
              : _viewModel.removeFriend(friend),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'remove', child: Text('Remove friend')),
            PopupMenuItem(value: 'block', child: Text('Block')),
          ],
        ),
      ),
    if (_viewModel.sentGifts.isNotEmpty) ...[
      _Section('Gifts sent'),
      for (final gift in _viewModel.sentGifts)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Text('🎁', style: TextStyle(fontSize: 20)),
          title: Text(gift.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('Sent to @${gift.toUsername} ✓'),
          trailing: TextButton(
            onPressed: _viewModel.busy
                ? null
                : () => _viewModel.cancelGift(gift),
            child: const Text('Cancel'),
          ),
        ),
    ],
    if (_viewModel.blocked.isNotEmpty) ...[
      _Section('Blocked'),
      for (final user in _viewModel.blocked)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.block),
          title: Text('@${user.username}'),
          trailing: TextButton(
            onPressed: _viewModel.busy ? null : () => _viewModel.unblock(user),
            child: const Text('Unblock'),
          ),
        ),
    ],
  ];

  static final _primary = FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.text,
    minimumSize: const Size.fromHeight(48),
  );

  InputDecoration _decoration(String hint, {String? prefix}) => InputDecoration(
    hintText: hint,
    prefixText: prefix,
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}

class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Friends and gifts need internet.',
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Text(title, style: AppText.h3),
    );
  }
}
