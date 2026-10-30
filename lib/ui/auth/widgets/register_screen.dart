import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/auth/registration_rules.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../view_model/auth_view_model.dart';
import '../view_model/register_form_view_model.dart';
import 'auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.viewModel, this.formViewModel});

  final AuthViewModel? viewModel;

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final RegisterFormViewModel? formViewModel;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final _dateFormat = DateFormat('d MMM yyyy');

  late final AuthViewModel _viewModel = widget.viewModel ?? AuthViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  late final RegisterFormViewModel _form =
      widget.formViewModel ?? RegisterFormViewModel();
  late final bool _ownsForm = widget.formViewModel == null;

  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    if (_ownsForm) _form.dispose();
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _form.birthDate ?? _form.suggestedBirthDate,
      firstDate: _form.earliestBirthDate,
      lastDate: _form.latestBirthDate,
      helpText: 'Date of birth',
    );
    if (picked == null) return;
    _form.setBirthDate(picked);
    _birthDateController.text = _dateFormat.format(picked);
  }

  Future<void> _submit() async {
    _viewModel.clearError();
    final age = _form.age;
    if (!_form.isValid || age == null) return;

    FocusScope.of(context).unfocus();
    final success = await _viewModel.signUp(
      email: _form.email.trim(),
      password: _form.password,
      name: _form.name.trim(),
      age: age,
    );

    if (success && mounted) {
      // If we pushed RegisterScreen on top of LoginScreen, pop so AuthGate takes over cleanly
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String get _birthDateHelper {
    final age = _form.age;
    if (age != null && _form.birthDateError == null) {
      return 'You are $age years old.';
    }
    return 'You must be at least ${RegistrationRules.minAgeYears} years old.';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _form]),
      builder: (context, _) {
        final canSubmit = _form.isValid && !_viewModel.isLoading;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button row
                  Row(
                    children: [
                      CircleIconButton(
                        asset: 'assets/icons/ic_chevron_left.svg',
                        semanticLabel: 'Back to Login',
                        onPressed: () {
                          _viewModel.clearError();
                          Navigator.maybePop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Header title
                  Text(
                    'Create Account',
                    style: AppText.breathingTitle.copyWith(
                      fontSize: 30,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join to personalize your experience and track your emotional wellness.',
                    style: AppText.bodyMuted.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Error banner
                  if (_viewModel.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accent, width: 1),
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

                  // Input Form Fields Card
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
                          label: 'Full Name',
                          controller: _nameController,
                          hintText: 'Your name or nickname',
                          textInputAction: TextInputAction.next,
                          onChanged: _form.setName,
                          errorText: _form.nameError,
                          helperText:
                              '${RegistrationRules.minNameLength} to '
                              '${RegistrationRules.maxNameLength} characters, '
                              'letters and spaces only.',
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Date of Birth',
                          controller: _birthDateController,
                          hintText: 'Tap to pick a date',
                          readOnly: true,
                          onTap: _pickBirthDate,
                          suffixIcon: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          errorText: _form.birthDateError,
                          helperText: _birthDateHelper,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Email',
                          controller: _emailController,
                          hintText: 'name@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: _form.setEmail,
                          errorText: _form.emailError,
                          helperText: 'We use it only to sign you in.',
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Password',
                          controller: _passwordController,
                          hintText: 'At least 8 characters',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            _form.setPassword(value);
                            // The confirmation depends on this one.
                            if (_confirmPasswordController.text.isNotEmpty) {
                              _form.setConfirmPassword(
                                _confirmPasswordController.text,
                              );
                            }
                          },
                          errorText: _form.passwordError,
                          helperText:
                              '${RegistrationRules.minPasswordLength}+ '
                              'characters, one uppercase and one number.',
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
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          hintText: 'Re-enter your password',
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onChanged: _form.setConfirmPassword,
                          onFieldSubmitted: (_) {
                            if (canSubmit) _submit();
                          },
                          errorText: _form.confirmPasswordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
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
                              'Create Account',
                              style: AppText.h3.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Switch back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppText.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _viewModel.clearError();
                          Navigator.maybePop(context);
                        },
                        child: Text(
                          'Sign in',
                          style: AppText.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
