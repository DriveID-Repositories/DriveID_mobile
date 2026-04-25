import 'package:flutter/material.dart';

import '../services/driver_portal_service.dart';
import '../widgets/driver_dashboard_shared.dart';
import '../widgets/offense_card.dart';

class HistoryTab extends StatelessWidget {
  final DriverPortalSnapshot snapshot;

  const HistoryTab({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('history-tab'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DriverSectionTitle(
          title: 'Offense History',
          subtitle: snapshot.offenses.isEmpty
              ? 'Your account has no traffic offense records at the moment.'
              : 'Browse every recorded offense and track the current status of each case.',
        ),
        const SizedBox(height: 14),
        if (snapshot.offenses.isEmpty)
          const EmptyOffensesCard()
        else
          ...snapshot.offenses.map(
            (offense) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OffenseCard(offense: offense),
            ),
          ),
      ],
    );
  }
}
