import 'package:flutter/material.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../view_model/cookie_jar_view_model.dart';
import 'cookie_detail_dialog.dart';

Future<void> showCookieList(
  BuildContext context,
  CookieJarViewModel viewModel,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: CookieListSheet(viewModel: viewModel),
    ),
  );
}

/// Asks before deleting a cookie forever. True when the user confirms.
Future<bool> confirmDeleteForever(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text('Delete forever?'),
      content: const Text(
        'This memory and its picture will be deleted. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Two tabs, "In the jar" and "Eaten", with the titles of every cookie.
class CookieListSheet extends StatelessWidget {
  const CookieListSheet({super.key, required this.viewModel});

  final CookieJarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final inJar = viewModel.inJar;
        final eaten = viewModel.eaten;
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelStyle: AppText.h3,
                unselectedLabelStyle: AppText.body,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.text,
                tabs: [
                  Tab(text: 'In the jar (${inJar.length})'),
                  Tab(text: 'Eaten (${eaten.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CookieList(
                      cookies: inJar,
                      empty: 'No cookies in the jar yet.',
                      viewModel: viewModel,
                    ),
                    _CookieList(
                      cookies: eaten,
                      empty: "You haven't eaten any cookie yet.",
                      viewModel: viewModel,
                      showHistoryActions: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CookieList extends StatelessWidget {
  const _CookieList({
    required this.cookies,
    required this.empty,
    required this.viewModel,
    this.showHistoryActions = false,
  });

  final List<CookieModel> cookies;
  final String empty;
  final CookieJarViewModel viewModel;
  final bool showHistoryActions;

  @override
  Widget build(BuildContext context) {
    if (cookies.isEmpty) {
      return Center(child: Text(empty, style: AppText.bodyMuted));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cookies.length,
      itemBuilder: (context, index) => _CookieRow(
        cookie: cookies[index],
        viewModel: viewModel,
        showHistoryActions: showHistoryActions,
      ),
    );
  }
}

class _CookieRow extends StatelessWidget {
  const _CookieRow({
    required this.cookie,
    required this.viewModel,
    required this.showHistoryActions,
  });

  final CookieModel cookie;
  final CookieJarViewModel viewModel;
  final bool showHistoryActions;

  Future<void> _delete(BuildContext context) async {
    if (await confirmDeleteForever(context)) {
      await viewModel.deleteForever(cookie);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 12),
      title: Text(
        cookie.title,
        style: AppText.body.copyWith(fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => showCookieDetail(context, viewModel, cookie),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cookie.hasImage)
            Icon(
              Icons.photo_camera_outlined,
              size: 20,
              color: AppColors.textMuted,
              semanticLabel: 'Has a picture',
            ),
          if (cookie.receivedFrom != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Semantics(
                label: 'Gift from @${cookie.receivedFrom}',
                child: const Text('🎁'),
              ),
            ),
          if (showHistoryActions) ...[
            IconButton(
              tooltip: 'Return to jar',
              icon: const Icon(Icons.undo),
              onPressed: () => viewModel.returnToJar(cookie),
            ),
            IconButton(
              tooltip: 'Delete forever',
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _delete(context),
            ),
          ],
        ],
      ),
    );
  }
}
