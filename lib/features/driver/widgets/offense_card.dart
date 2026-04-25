import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../traffic_officer/models/offense.dart';
import 'driver_dashboard_shared.dart';

class OffenseCard extends StatelessWidget {
  final Offense offense;

  const OffenseCard({
    super.key,
    required this.offense,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = offense.status.trim().toLowerCase();
    final isPending = normalizedStatus != 'paid' &&
        normalizedStatus != 'resolved' &&
        normalizedStatus != 'cleared';
    final accent = isPending ? AppTheme.warning : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  offense.offenseType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  offense.status,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offense.location,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DriverInfoChip(
                  icon: Icons.event_note_rounded,
                  text: formatDriverDate(offense.createdAt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DriverInfoChip(
                  icon: Icons.payments_rounded,
                  text: offense.fine,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
