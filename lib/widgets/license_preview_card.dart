import 'package:flutter/material.dart';
import '../models/TrafficOfficerModels/license.dart';
import '../theme/app_theme.dart';

class LicensePreviewCard extends StatelessWidget {
  final License license;
  final VoidCallback onEdit;

  const LicensePreviewCard({
    super.key,
    required this.license,
    required this.onEdit,
  });

  Color _getStatusColor() {
    if (license.isRevoked) return Colors.red;
    if (license.isExpired) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (license.isRevoked) return 'Revoked';
    if (license.isExpired) return 'Expired';
    return 'Valid';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              color: statusColor.withOpacity(0.15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'License #${license.registerNumber}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // License Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner Name
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Owner: ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: license.ownerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // License Type
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Type: ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: license.licenseType,
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Expiry Date
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Expires: ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: license.daysUntilExpiry,
                        style: TextStyle(
                          color:
                              license.isExpired
                                  ? Colors.red[300]
                                  : Colors.green[300],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Edit Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Change License'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
