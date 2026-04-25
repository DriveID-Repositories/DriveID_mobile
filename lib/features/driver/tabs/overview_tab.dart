import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/driver_portal_service.dart';
import '../widgets/driver_dashboard_shared.dart';

class OverviewTab extends StatelessWidget {
  final DriverPortalSnapshot snapshot;

  const OverviewTab({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('overview-tab'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DriverHeroBanner(snapshot: snapshot),
        const SizedBox(height: 18),
        const DriverSectionTitle(
          title: 'Overview',
          subtitle:
              'A quick summary of your license standing and offense totals. Open the License and History tabs for full details.',
        ),
        const SizedBox(height: 12),
        _OverviewStatusCard(snapshot: snapshot),
        const SizedBox(height: 16),
        DriverStatsGrid(snapshot: snapshot),
      ],
    );
  }
}

class _OverviewStatusCard extends StatelessWidget {
  final DriverPortalSnapshot snapshot;

  const _OverviewStatusCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final license = snapshot.license;
    final statusText = license?.statusDisplay ?? 'No license linked';
    final statusColor = switch (statusText.toLowerCase()) {
      'valid' => AppTheme.success,
      'expired' => AppTheme.warning,
      'revoked' => AppTheme.error,
      _ => AppTheme.textLight,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.badge_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'License status: $statusText',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            license == null
                ? 'A driver license record has not been linked to this account yet.'
                : 'Current license number ${license.registerNumber} is the active document associated with this account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
