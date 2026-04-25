import 'package:flutter/material.dart';

import '../services/driver_portal_service.dart';
import '../widgets/driver_dashboard_shared.dart';
import '../widgets/professional_license_card.dart';

class LicenseTab extends StatelessWidget {
  final DriverPortalSnapshot snapshot;
  final ValueNotifier<String> qrData;

  const LicenseTab({
    super.key,
    required this.snapshot,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('license-tab'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const DriverSectionTitle(
          title: 'Digital License',
          subtitle:
              'Present this official card for identity and live license verification.',
        ),
        const SizedBox(height: 14),
        ProfessionalLicenseCard(
          license: snapshot.license,
          driverName: snapshot.user.displayName,
          qrData: qrData,
        ),
        const SizedBox(height: 18),
        LicenseSupportCard(license: snapshot.license),
      ],
    );
  }
}
