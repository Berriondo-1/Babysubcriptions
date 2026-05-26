import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/baby_provider.dart';
import 'package:baby_subscription/screens/baby_list_screen.dart';
import 'package:baby_subscription/screens/login_screen.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:baby_subscription/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProv = context.read<AuthProvider>();
    final ok = await authProv.register(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      await context.read<BabyProvider>().loadProfiles(authProv.currentUser!.id!);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BabyListScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProv.errorMessage ?? 'Error al registrarse'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProv.errorMessage ?? 'Error de inicio de sesión'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
                    'Crear cuenta',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Regístrate para gestionar las suscripciones de tu bebé',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Name (optional)
                _buildLabel('Nombre (opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                _buildLabel('Correo electrónico'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'tucorreo@ejemplo.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo.';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Correo no válido.';
                    }
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
                  decoration: InputDecoration(
                    hintText: 'Mínimo 6 caracteres',
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
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña.';
                    if (v.length < 6) return 'Mínimo 6 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password
                _buildLabel('Confirmar contraseña'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Repite tu contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textHint,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contraseña.';
                    if (v != _passwordController.text) return 'Las contraseñas no coinciden.';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit button
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
                      : const Text('Registrarme'),
                ),
                const SizedBox(height: 24),

                // Social login
                SocialLoginRow(onProviderTap: _socialLogin),
                const SizedBox(height: 28),

                // Already have account
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tienes cuenta? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Inicia sesión',
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
