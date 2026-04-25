import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../traffic_officer/models/license.dart';
import 'driver_dashboard_shared.dart';

class ProfessionalLicenseCard extends StatelessWidget {
  final License? license;
  final String driverName;
  final ValueNotifier<String> qrData;

  const ProfessionalLicenseCard({
    super.key,
    required this.license,
    required this.driverName,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStatus = license?.statusDisplay ?? 'Not Issued';
    final statusColor = switch (resolvedStatus.toLowerCase()) {
      'valid' => AppTheme.success,
      'expired' => AppTheme.warning,
      'revoked' => AppTheme.error,
      _ => AppTheme.textLight,
    };

    final photoUrl = license?.profilePictureUrl;
    final licenseNumber = license?.registerNumber ?? 'Pending issue';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFD9AE55), Color(0xFFF7E4A6), Color(0xFFE2BF72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          gradient: const LinearGradient(
            colors: [Color(0xFF0C1A2D), Color(0xFF122A49), Color(0xFF173A61)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REPUBLIC OF MALAWI',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.goldLight,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Digital Driving License',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      resolvedStatus,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DriverPhoto(photoUrl: photoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'License No. $licenseNumber',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            InfoPill(
                              icon: Icons.badge_outlined,
                              label: license?.licenseType ?? 'Not assigned',
                            ),
                            InfoPill(
                              icon: Icons.event_available_outlined,
                              label: license == null
                                  ? 'No expiry record'
                                  : formatDriverDate(license!.expiryDate),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        runSpacing: 14,
                        spacing: 18,
                        children: [
                          LicenseMetric(
                            label: 'License Class',
                            value: license?.licenseType ?? 'Not assigned',
                          ),
                          LicenseMetric(
                            label: 'Expires',
                            value: license == null
                                ? 'No record'
                                : formatDriverDate(license!.expiryDate),
                          ),
                          LicenseMetric(
                            label: 'Validity',
                            value: license?.daysUntilExpiry ??
                                'Awaiting license record',
                          ),
                          const LicenseMetric(
                            label: 'Verification',
                            value: 'QR enabled',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ValueListenableBuilder<String>(
                            valueListenable: qrData,
                            builder: (context, data, child) {
                              return QrImageView(
                                data: data,
                                version: QrVersions.auto,
                                size: 124,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF132844),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF132844),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Scan to verify',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverPhoto extends StatelessWidget {
  final String? photoUrl;

  const DriverPhoto({
    super.key,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 88,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: const Icon(Icons.person_rounded, size: 42, color: Colors.white60),
    );

    if (photoUrl == null || photoUrl!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        photoUrl!,
        width: 88,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LicenseMetric extends StatelessWidget {
  final String label;
  final String value;

  const LicenseMetric({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class LicenseSupportCard extends StatelessWidget {
  final License? license;

  const LicenseSupportCard({
    super.key,
    required this.license,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Card Notes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const SimpleBullet(
            text:
                'The QR contains a live license payload for mobile verification.',
          ),
          const SimpleBullet(
            text:
                'Traffic officers confirm the live license status from Supabase during verification.',
          ),
          SimpleBullet(
            text: license == null
                ? 'No active license record is linked to this account yet.'
                : 'This license currently shows as ${license!.statusDisplay.toLowerCase()}.',
          ),
        ],
      ),
    );
  }
}

class SimpleBullet extends StatelessWidget {
  final String text;

  const SimpleBullet({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: AppTheme.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textLight,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
