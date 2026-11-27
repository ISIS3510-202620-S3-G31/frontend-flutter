import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/repositories/cookie_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/cookie_jar_view_model.dart';
import 'cookie_detail_dialog.dart';
import 'cookie_jar_drawing.dart';
import 'cookie_list_sheet.dart';
import 'new_cookie_screen.dart';

class CookieJarScreen extends StatefulWidget {
  const CookieJarScreen({super.key, this.viewModel});

  final CookieJarViewModel? viewModel;

  @override
  State<CookieJarScreen> createState() => _CookieJarScreenState();
}

class _CookieJarScreenState extends State<CookieJarScreen> {
  late final CookieJarViewModel _viewModel =
      widget.viewModel ?? CookieJarViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  StreamSubscription<CookieMessage>? _messages;

  @override
  void initState() {
    super.initState();
    _messages = _viewModel.messages.listen(_showMessage);
    _viewModel.start();
  }

  @override
  void dispose() {
    _messages?.cancel();
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

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
      MaterialPageRoute(builder: (_) => const NewCookieScreen()),
    );
    if (created != null) _viewModel.created(created);
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
                title: Text('Cookie jar', style: AppText.h1),
                subtitle: 'Your memories and wins, one cookie each',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => showCookieList(context, _viewModel),
                    icon: const Icon(Icons.list_alt),
                    label: Text(
                      'All my cookies (${_viewModel.inJar.length + _viewModel.eaten.length})',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surfaceDim,
                      foregroundColor: AppColors.text,
                    ),
                  ),
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
        CookieJarDrawing(
          cookies: today,
          onCookieTap: (cookie) => showCookieDetail(context, _viewModel, cookie),
        ),
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
