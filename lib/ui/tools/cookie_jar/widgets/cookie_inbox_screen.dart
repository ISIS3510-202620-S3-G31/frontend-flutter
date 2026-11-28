import 'package:flutter/material.dart';

import '../../../../data/models/cookie_social_models.dart';
import '../../../../domain/cookie_jar/cookie_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/cookie_social_view_model.dart';

class CookieInboxScreen extends StatelessWidget {
  const CookieInboxScreen({super.key, required this.viewModel});

  final CookieSocialViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => Column(
            children: [
              ScreenHeader(
                title: Text('Gift inbox', style: AppText.h1),
                subtitle: 'Cookies your friends sent you',
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (viewModel.inboxOffline) {
      return _Notice(
        icon: Icons.wifi_off,
        text: CookieMessages.giftsNeedConnection,
      );
    }
    if (!viewModel.inboxLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final gifts = viewModel.inbox;
    if (gifts.isEmpty) {
      return const _Notice(
        icon: Icons.inbox_outlined,
        text: 'No gifts right now. They last 7 days here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: gifts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _GiftCard(gift: gifts[index], viewModel: viewModel),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({required this.gift, required this.viewModel});

  final Gift gift;
  final CookieSocialViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final accepting = viewModel.isAccepting(gift);
    final enabled = !accepting && !viewModel.busy;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🎁 from @${gift.fromUsername}', style: AppText.bodyMuted),
          const SizedBox(height: 4),
          Text(gift.title, style: AppText.h3),
          const SizedBox(height: 8),
          Text(gift.text, style: AppText.body),
          if (gift.hasImage) ...[
            const SizedBox(height: 8),
            Text('📷 includes a photo', style: AppText.bodyMuted),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: enabled ? () => viewModel.declineGift(gift) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: enabled ? () => viewModel.acceptGift(gift) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.text,
                  ),
                  child: accepting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(text, style: AppText.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
