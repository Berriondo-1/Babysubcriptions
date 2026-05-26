import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/baby_provider.dart';
import 'package:baby_subscription/screens/baby_list_screen.dart';
import 'package:baby_subscription/screens/register_screen.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:baby_subscription/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProv = context.read<AuthProvider>();
    final ok = await authProv.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (ok) {
      await context.read<BabyProvider>().loadProfiles(authProv.currentUser!.id!);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BabyListScreen()),
        (_) => false,
      );
    }
    // Error shown via listener on authProv.errorMessage
  }

  Future<void> _socialLogin(SocialProvider provider) async {
    final authProv = context.read<AuthProvider>();
    final ok = await authProv.loginWithSocial(provider);
    if (!mounted) return;
    if (ok) {
      await context.read<BabyProvider>().loadProfiles(authProv.currentUser!.id!);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BabyListScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final isLoading = authProv.isLoading;
    final errorMessage = authProv.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text('🍼', style: TextStyle(fontSize: 30))),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Bienvenido de nuevo',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Inicia sesión para continuar',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 32),

                // Error banner
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Email
                _buildLabel('Correo electrónico'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                  decoration: const InputDecoration(
                    hintText: 'tucorreo@ejemplo.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                _buildLabel('Contraseña'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                  decoration: InputDecoration(
                    hintText: 'Tu contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textHint,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña.';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 24),

                // Social login
                SocialLoginRow(onProviderTap: _socialLogin),
                const SizedBox(height: 28),

                // Register link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Regístrate',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
    );
  }
}
