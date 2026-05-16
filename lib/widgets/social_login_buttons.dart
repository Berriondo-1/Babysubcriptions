import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLoginRow extends StatelessWidget {
  final Function(SocialProvider) onProviderTap;

  const SocialLoginRow({super.key, required this.onProviderTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'o continúa con',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ]),
        const SizedBox(height: 16),
        Row(
          children: [
            _SocialBtn(
              icon: FontAwesomeIcons.google,
              color: const Color(0xFFEA4335),
              onTap: () => onProviderTap(SocialProvider.google),
            ),
            const SizedBox(width: 12),
            _SocialBtn(
              icon: FontAwesomeIcons.apple,
              color: const Color(0xFF000000),
              onTap: () => onProviderTap(SocialProvider.apple),
            ),
            const SizedBox(width: 12),
            _SocialBtn(
              icon: FontAwesomeIcons.github,
              color: const Color(0xFF24292E),
              onTap: () => onProviderTap(SocialProvider.github),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.divider, width: 1.5),
            ),
          ),
          child: Center(child: FaIcon(icon, size: 22, color: color)),
        ),
      ),
    );
  }
}
