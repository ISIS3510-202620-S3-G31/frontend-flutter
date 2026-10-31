import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../home/widgets/tool_hub_screen.dart';
import '../view_model/auth_gate_view_model.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.viewModel});

  final AuthGateViewModel? viewModel;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthGateViewModel _viewModel =
      widget.viewModel ?? AuthGateViewModel();


  late final Stream<User?> _authChanges = _viewModel.authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = snapshot.data;
        if (snapshot.hasData && user != null) {
          _viewModel.syncAnalyticsUser(user.uid);
          return const ToolHubScreen();
        }

        _viewModel.syncAnalyticsUser(null);
        return const LoginScreen();
      },
    );
  }
}
