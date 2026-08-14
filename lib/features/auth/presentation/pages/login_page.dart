import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:io';

import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/oauth_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
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
                      const SizedBox(height: AppSpacing.xxxl),

                      // Logo and title
                      Center(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              child: SvgPicture.asset(
                                'assets/icons/app_icon.svg',
                                width: 100,
                                height: 100,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              l.authWelcomeBack,
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
                              l.authLoginSubtitle,
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

                      const SizedBox(height: AppSpacing.xxxl),

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

                      const SizedBox(height: AppSpacing.sm),

                      // Remember me — whole row is tappable.
                      // TODO(password-recovery): re-add the "Forgot password?"
                      // action (l.authForgotPassword) at the trailing end of
                      // this row once the password-reset flow exists. Hidden
                      // for now instead of showing a "coming soon" snackbar.
                      InkWell(
                        borderRadius:
                            const BorderRadius.all(AppRadius.rButton),
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Text(
                                l.authRememberMe,
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Login button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return LoadingButton(
                            onPressed: isLoading ? null : _handleLogin,
                            isLoading: isLoading,
                            child: Text(l.authSignIn),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.base),
                            child: Text(
                              l.authOrDivider,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // OAuth buttons (third-party sign-in)
                      OAuthButton.google(
                        onPressed: () {
                          context
                              .read<AuthBloc>()
                              .add(AuthGoogleSignInRequested());
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Apple sign-in: native on iOS; shown elsewhere with a
                      // note since the Android/Web flow needs extra config.
                      OAuthButton.apple(
                        onPressed: () {
                          context
                              .read<AuthBloc>()
                              .add(AuthAppleSignInRequested());
                        },
                      ),

                      if (!Platform.isIOS)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            l.authAppleIosNote,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.xl),

                      // Sign up link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/register'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 44),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: '${l.authNoAccount} ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              children: [
                                TextSpan(
                                  text: l.authCreateAccount,
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

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              rememberMe: _rememberMe,
            ),
          );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
