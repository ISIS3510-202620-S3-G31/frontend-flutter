import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../home/widgets/tool_hub_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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
          AnalyticsService().setUserId(user.uid);
          return const ToolHubScreen();
        }

        AnalyticsService().setUserId(null);
        return const LoginScreen();
      },
    );
  }
}
