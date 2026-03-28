import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  final String message;

  const EmptyStateCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF5E6B7A),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5E6B7A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
