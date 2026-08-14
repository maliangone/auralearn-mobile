import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/presentation/pages/adult_ownership_ack_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  /// TODO(legal): replace with the real Terms of Service URL once published.
  static const String termsUrl = 'https://auralearn.example.com/terms';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  String get _password => _passwordController.text;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(RegisterPage.termsUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(AdultOwnershipAckPage.privacyPolicyUrl);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.commonBack,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Title
                      Center(
                        child: Column(
                          children: [
                            Text(
                              l.registerTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l.registerSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Name field
                      AuthTextField(
                        controller: _nameController,
                        label: l.registerName,
                        hintText: l.registerNameHint,
                        prefixIcon: Icons.person_outlined,
                        validator: Validators.name,
                      ),

                      const SizedBox(height: AppSpacing.base),

                      // Email field
                      AuthTextField(
                        controller: _emailController,
                        label: l.authEmail,
                        hintText: l.authEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: Validators.email,
                      ),

                      const SizedBox(height: AppSpacing.base),

                      // Password field
                      AuthTextField(
                        controller: _passwordController,
                        label: l.authPassword,
                        hintText: l.authPasswordHint,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outlined,
                        onChanged: (_) => setState(() {}),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? l.authShowPassword
                              : l.authHidePassword,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: Validators.password,
                      ),

                      const SizedBox(height: AppSpacing.base),

                      // Confirm password field
                      AuthTextField(
                        controller: _confirmPasswordController,
                        label: l.registerConfirmPassword,
                        hintText: l.registerConfirmPasswordHint,
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? l.authShowPassword
                              : l.authHidePassword,
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.base),

                      // Password requirements — live checklist
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.all(AppRadius.rCard),
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.registerPasswordRequirements,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildPasswordRequirement(
                              l.registerReqLength,
                              _password.length >= 8,
                            ),
                            _buildPasswordRequirement(
                              l.registerReqLetter,
                              RegExp(r'[A-Za-z]').hasMatch(_password),
                            ),
                            _buildPasswordRequirement(
                              l.registerReqNumber,
                              RegExp(r'\d').hasMatch(_password),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.base),

                      // Terms and conditions — row toggles the checkbox;
                      // the Terms / Privacy spans open their URLs.
                      InkWell(
                        borderRadius:
                            const BorderRadius.all(AppRadius.rButton),
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: AppSpacing.md),
                                  child: RichText(
                                    text: TextSpan(
                                      text: '${l.registerAcceptPrefix} ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                      children: [
                                        TextSpan(
                                          text: l.registerTerms,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: _termsRecognizer,
                                        ),
                                        TextSpan(text: ' ${l.registerAnd} '),
                                        TextSpan(
                                          text: l.registerPrivacy,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: _privacyRecognizer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Register button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return LoadingButton(
                            onPressed: isLoading || !_acceptTerms
                                ? null
                                : _handleRegister,
                            isLoading: isLoading,
                            child: Text(l.registerButton),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Sign in link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 44),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: '${l.registerHaveAccount} ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              children: [
                                TextSpan(
                                  text: l.registerGoLogin,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? AppColors.encourage : AppColors.textHint,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            requirement,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: met ? AppColors.textPrimary : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).commonErrorTitle),
          ),
        );
      }
    }
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).registerAcceptTermsError),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim(),
              acceptTerms: _acceptTerms,
            ),
          );
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
