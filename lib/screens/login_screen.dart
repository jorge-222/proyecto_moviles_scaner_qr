import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleSocialSignIn(Future<void> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      await signInMethod();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade400,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o Icono
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'StyleStock QR',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'Tu inventario en un escaneo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 80),

                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  // Botón de Google
                  _SocialLoginButton(
                    icon: FontAwesomeIcons.google,
                    text: 'Continuar con Google',
                    color: Colors.white,
                    textColor: Colors.black87,
                    onPressed: () => _handleSocialSignIn(_authService.signInWithGoogle),
                  ),
                  const SizedBox(height: 15),

                  // Botón de GitHub
                  _SocialLoginButton(
                    icon: FontAwesomeIcons.github,
                    text: 'Continuar con GitHub',
                    color: Colors.black,
                    textColor: Colors.white,
                    onPressed: () => _handleSocialSignIn(_authService.signInWithGithub),
                  ),
                  const SizedBox(height: 15),

                  // Botón de Apple (Placeholder)
                  _SocialLoginButton(
                    icon: FontAwesomeIcons.apple,
                    text: 'Continuar con Apple',
                    color: Colors.white,
                    textColor: Colors.black,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Apple Login requiere membresía de desarrollador.')),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final FaIconData icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 20, color: textColor),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
