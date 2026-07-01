import 'package:provider/provider.dart';
import 'package:aplano/pages/navigation_shell.dart' show NavigationShell;
import 'package:aplano/providers/auth_provider.dart';
import 'package:flutter/material.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  AuthProvider? _auth; // saved so dispose() never calls context.read()

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _auth = context.read<AuthProvider>()..addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _orgNameController.dispose();
    _passwordController.dispose();
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();

      if (auth.status == AuthStatus.authenticated) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NavigationShell()),
          (route) => false,
        );
        return;
      }

      if (auth.status == AuthStatus.error && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
      }
    });
  }

  Future<void> _onCreateAccountPressed() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final orgName = _orgNameController.text.trim();
    final password = _passwordController.text;
    final orgSlug = orgName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-').replaceAll(RegExp(r'-+'), '-');

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || orgName.isEmpty || password.isEmpty) return;

    await context.read<AuthProvider>().register(
      orgName:   orgName,
      orgSlug:   orgSlug,
      email:     email,
      password:  password,
      firstName: firstName,
      lastName:  lastName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create your organization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              const SizedBox(height: 16),
              Text(
                'Set up your company',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your organization and admin account to get started.',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Organization Name
              _buildLabel('Organization Name', cs),
              const SizedBox(height: 8),
              TextField(
                controller: _orgNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'e.g. Acme Corp',
                ),
              ),
              const SizedBox(height: 20),
              // First Name
              _buildLabel('First Name', cs),
              const SizedBox(height: 8),
              TextField(
                controller: _firstNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'e.g. John',
                ),
              ),
              const SizedBox(height: 20),
              // Last Name
              _buildLabel('Last Name', cs),
              const SizedBox(height: 8),
              TextField(
                controller: _lastNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'e.g. Doe',
                ),
              ),
              const SizedBox(height: 20),
              // Work Email
              _buildLabel('Work Email', cs),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'name@company.com',
                ),
              ),
              const SizedBox(height: 20),
              // Password
              _buildLabel('Password', cs),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: 'Minimum 8 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: isLoading ? null : () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Create Account Button
              ElevatedButton(
                onPressed: isLoading ? null : _onCreateAccountPressed,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 16),
              // Terms Text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'By signing up, you agree to our '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '\nand '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
