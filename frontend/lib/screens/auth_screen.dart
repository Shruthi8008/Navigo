import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

enum AuthMode { login, signup }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.initialMode});

  final AuthMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  late AuthMode _mode = widget.initialMode;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authProvider.notifier)
        .login(
          email: _loginEmailController.text,
          password: _loginPasswordController.text,
        );

    if (mounted && !ref.read(authProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitSignup() async {
    if (!_signupFormKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authProvider.notifier)
        .signup(
          fullName: _signupNameController.text,
          email: _signupEmailController.text,
          password: _signupPasswordController.text,
        );

    if (mounted && !ref.read(authProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  String? _validateRequired(String? value, {int minLength = 1}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < minLength) {
      return minLength > 1
          ? 'Must be at least $minLength characters.'
          : 'This field is required.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final errorText = authState.hasError ? authState.error.toString() : null;
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == AuthMode.login ? 'Login' : 'Sign Up'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mode == AuthMode.login
                          ? 'Welcome back'
                          : 'Create your account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mode == AuthMode.login
                          ? 'Log in to continue to your safety profile.'
                          : 'Sign up to save your routes and profile details.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    errorText,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _mode == AuthMode.login
                    ? _LoginForm(
                        key: const ValueKey('login-form'),
                        formKey: _loginFormKey,
                        isLoading: isLoading,
                        emailController: _loginEmailController,
                        passwordController: _loginPasswordController,
                        validator: _validateRequired,
                        onSubmit: _submitLogin,
                      )
                    : _SignupForm(
                        key: const ValueKey('signup-form'),
                        formKey: _signupFormKey,
                        isLoading: isLoading,
                        nameController: _signupNameController,
                        emailController: _signupEmailController,
                        passwordController: _signupPasswordController,
                        validator: _validateRequired,
                        onSubmit: _submitSignup,
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _mode == AuthMode.login
                        ? "Don't have an account?"
                        : 'Already have an account?',
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _mode = _mode == AuthMode.login
                                  ? AuthMode.signup
                                  : AuthMode.login;
                            });
                          },
                    child: Text(_mode == AuthMode.login ? 'Sign Up' : 'Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
    required this.validator,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? Function(String? value, {int minLength}) validator;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) => validator(value, minLength: 5),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (value) => validator(value, minLength: 8),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: Text(isLoading ? 'Signing in...' : 'Login'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.validator,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? Function(String? value, {int minLength}) validator;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => validator(value, minLength: 2),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) => validator(value, minLength: 5),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (value) => validator(value, minLength: 8),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: Text(isLoading ? 'Creating account...' : 'Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}
