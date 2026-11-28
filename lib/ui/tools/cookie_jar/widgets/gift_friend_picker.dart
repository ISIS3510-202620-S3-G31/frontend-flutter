import 'package:flutter/material.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../../data/models/cookie_social_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../view_model/cookie_social_view_model.dart';

Future<void> showGiftFriendPicker(
  BuildContext context,
  CookieSocialViewModel viewModel,
  CookieModel cookie,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (sheetContext) => SafeArea(
      child: FutureBuilder<List<Friend>>(
        future: viewModel.friendsForGift(),
        builder: (context, snapshot) {
          final friends = snapshot.data;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Gift "${cookie.title}"', style: AppText.h3),
                const SizedBox(height: 4),
                Text(
                  'Your friend gets a copy. Yours stays in your jar.',
                  style: AppText.bodyMuted,
                ),
                const SizedBox(height: 12),
                if (friends == null)
                  const Center(child: CircularProgressIndicator())
                else if (friends.isEmpty)
                  Text(
                    'Add friends first, from the friends screen.',
                    style: AppText.body,
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final friend in friends)
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text('@${friend.username}'),
                            trailing: const Text('🎁'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              viewModel.sendGift(cookie, friend);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
