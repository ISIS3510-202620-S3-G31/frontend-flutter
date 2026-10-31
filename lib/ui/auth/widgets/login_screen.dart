import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../view_model/auth_view_model.dart';
import '../view_model/login_form_view_model.dart';
import 'auth_text_field.dart';
import 'offline_dialog.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.viewModel, this.formViewModel});

  final AuthViewModel? viewModel;

  final LoginFormViewModel? formViewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthViewModel _viewModel = widget.viewModel ?? AuthViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  late final LoginFormViewModel _form =
      widget.formViewModel ?? LoginFormViewModel();
  late final bool _ownsForm = widget.formViewModel == null;

  /// Built once, so a rebuild does not sign the builder up to both view models
  /// again.
  late final Listenable _changes = Listenable.merge([_viewModel, _form]);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    if (_ownsForm) _form.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    _viewModel.clearError();
    if (!_form.isValid) return;

    FocusScope.of(context).unfocus();
    final signedIn = await _viewModel.signIn(
      email: _form.email,
      password: _form.password,
    );
    if (!mounted) return;
    // When it works, the auth gate swaps this screen for the home.
    if (!signedIn && _viewModel.isOffline) await showOfflineDialog(context);
  }

  void _navigateToRegister() {
    _viewModel.clearError();
    // Register gets its own view model: this screen disposes this one as soon
    // as the new account signs in, while Register is still open.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _changes,
      builder: (context, _) {
        final canSubmit = _form.isValid && !_viewModel.isLoading;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                // Lets the phone fill in, and offer to save, the email and
                // password as one account.
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mascot Illustration
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.panel,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceDim,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/illustrations/sprout_mascot.svg',
                              width: 56,
                              height: 56,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title & Subtitle
                      Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: AppText.breathingTitle.copyWith(
                          fontSize: 30,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access your emotional toolbox and saved progress.',
                        textAlign: TextAlign.center,
                        style: AppText.bodyMuted.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      // Error message banner
                      if (_viewModel.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.accent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _viewModel.errorMessage!,
                                  style: AppText.body.copyWith(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Card with Input Fields
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.surfaceDim,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthTextField(
                              label: 'Email',
                              controller: _emailController,
                              hintText: 'name@example.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              onChanged: _form.setEmail,
                              errorText: _form.emailError,
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              label: 'Password',
                              controller: _passwordController,
                              hintText: 'Enter your password',
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              autocorrect: false,
                              enableSuggestions: false,
                              onChanged: _form.setPassword,
                              errorText: _form.passwordError,
                              onFieldSubmitted: (_) {
                                if (canSubmit) _submit();
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: canSubmit ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.text,
                            disabledBackgroundColor: AppColors.surfaceDim,
                            disabledForegroundColor: AppColors.textMuted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _viewModel.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.text,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: AppText.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Navigation to Register Screen
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppText.body.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: _viewModel.isLoading
                                ? null
                                : _navigateToRegister,
                            child: Text(
                              'Sign up',
                              style: AppText.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
