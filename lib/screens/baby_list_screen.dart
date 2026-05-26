import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/baby_provider.dart';
import 'package:baby_subscription/screens/baby_form_screen.dart';
import 'package:baby_subscription/screens/catalog_screen.dart';
import 'package:baby_subscription/screens/subscription_screen.dart';
import 'package:baby_subscription/screens/welcome_screen.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BabyListScreen extends StatefulWidget {
  const BabyListScreen({super.key});

  @override
  State<BabyListScreen> createState() => _BabyListScreenState();
}

class _BabyListScreenState extends State<BabyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<BabyProvider>().loadProfiles(userId);
      }
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 38),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    context.read<BabyProvider>().clearProfiles();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteProfile(BabyProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar perfil'),
        content: Text('¿Eliminar el perfil de ${profile.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 38),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<BabyProvider>().deleteProfile(profile.id!);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final babyProv = context.watch<BabyProvider>();
    final profiles = babyProv.profiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🍼', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            const Text('BabySubscription'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Catálogo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CatalogScreen()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: babyProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profiles.isEmpty
                              ? 'Hola ${user?.displayName ?? ''}! 👋'
                              : 'Perfiles de bebés',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profiles.isEmpty
                              ? 'Registra el perfil de tu bebé para comenzar'
                              : '${profiles.length} ${profiles.length == 1 ? 'perfil registrado' : 'perfiles registrados'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                if (profiles.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('👶', style: TextStyle(fontSize: 48)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Sin perfiles aún',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca el botón + para registrar\nel perfil de tu bebé',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _BabyProfileCard(
                            profile: profiles[i],
                            onSubscription: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => SubscriptionProvider(),
                                  child: SubscriptionScreen(babyProfile: profiles[i]),
                                ),
                              ),
                            ),
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BabyFormScreen(existingProfile: profiles[i]),
                              ),
                            ),
                            onDelete: () => _deleteProfile(profiles[i]),
                          ),
                        ),
                        childCount: profiles.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BabyFormScreen()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo bebé'),
        elevation: 4,
      ),
    );
  }
}

class _BabyProfileCard extends StatelessWidget {
  final BabyProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSubscription;

  const _BabyProfileCard({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    required this.onSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.ageLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.monitor_weight_outlined,
                        label: '${profile.weightKg} kg',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.auto_fix_high_rounded,
                        label: profile.sizeShort,
                        highlighted: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: onSubscription,
                  icon: const Icon(Icons.subscriptions_outlined, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Suscripción',
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.error,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: highlighted ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: highlighted ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}