import 'package:flutter/material.dart';

class SsoLoginPage extends StatefulWidget {
  const SsoLoginPage({super.key});

  @override
  State<SsoLoginPage> createState() => _SsoLoginPageState();
}

class _SsoLoginPageState extends State<SsoLoginPage> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    // SSO redirect — placeholder
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SSO login is not configured yet.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Blue header ──────────────────────────────────────────────────
          Container(
            color: const Color(0xFF2196F3),
            width: double.infinity,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Aplano',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      fontFamily: 'Georgia',
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(1, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── White body ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // E-Mail label
                  const Text(
                    'E-Mail',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // E-Mail field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      hintText: 'E-Mail',
                      hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SSO Login button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _submit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        side: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF2196F3)),
                            )
                          : const Text(
                              'SSO Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back to email/password
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Zurück zum Login mit Email & Passwort',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Color(0xFF424242), fontSize: 13),
                            children: [
                              TextSpan(text: 'Made with '),
                              TextSpan(
                                text: '❤',
                                style: TextStyle(color: Color(0xFFE53935)),
                              ),
                              TextSpan(text: ' in Germany'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Imprint & Contact',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'v18.68',
                          style: TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
