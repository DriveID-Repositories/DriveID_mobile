import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../traffic_officer/services/auth_service.dart';
import '../traffic_officer/models/driver_license.dart' as local;

class MyLicenseTab extends StatefulWidget {
  const MyLicenseTab({super.key});

  @override
  State<MyLicenseTab> createState() => _MyLicenseTabState();
}

class _MyLicenseTabState extends State<MyLicenseTab> {
  late Future<local.DriverLicense> _licenseFuture;
  late Timer _qrRefreshTimer;
  final ValueNotifier<String> _qrData = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _licenseFuture = _fetchLicenseFromAuth();
    _generateQRData();
    _qrRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _generateQRData();
    });
  }

  @override
  void dispose() {
    _qrRefreshTimer.cancel();
    _qrData.dispose();
    super.dispose();
  }

  Future<local.DriverLicense> _fetchLicenseFromAuth() async {
    final appUser = await AuthService.currentUser;
    if (appUser == null) throw Exception('Not logged in');
    if (appUser.role != 'driver') throw Exception('User is not a driver');
    if (appUser.license == null) throw Exception('No license found');
    
    // Convert the license map to local.DriverLicense
    final licenseData = appUser.license!;
    return local.DriverLicense.fromJson(licenseData);
  }

  void _generateQRData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _qrData.value = 'loading|$timestamp';
  }

  void _updateQRData(String registerNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _qrData.value = '$registerNumber|$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<local.DriverLicense>(
      future: _licenseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC124)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _licenseFuture = _fetchLicenseFromAuth()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC124),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final license = snapshot.data!;
        _updateQRData(license.registerNumber);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Your official driving license',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildLicenseCard(license),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLicenseCard(local.DriverLicense license) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Gold Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(color: Color(0xFFFFC124)),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.drive_eta, color: Colors.black87, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REPUBLIC OF MALAWI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Digital Driving License',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _statusChip(license.status),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver photo and name
                  Row(
                    children: [
                      ClipOval(
                        child: license.photoUrl != null && license.photoUrl!.isNotEmpty
                            ? Image.network(
                                license.photoUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultAvatar(),
                              )
                            : _defaultAvatar(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              license.ownerName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reg: ${license.registerNumber}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 20),
                  // License details
                  Row(
                    children: [
                      Expanded(child: _infoColumn(Icons.category, 'CATEGORY', license.licenseType)),
                      Expanded(child: _infoColumn(Icons.calendar_today, 'VALID FROM', _formatDate(license.issueDate))),
                      Expanded(
                        child: _infoColumn(
                          Icons.event_busy,
                          'EXPIRES',
                          _formatDate(license.expiryDate),
                          valueColor: (license.expiryDate != null && license.expiryDate!.isBefore(DateTime.now()))
                              ? Colors.redAccent
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 24),
                  // Dynamic QR Code
                  Center(
                    child: Column(
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: _qrData,
                          builder: (context, data, child) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                              ),
                              child: QrImageView(
                                data: data,
                                version: QrVersions.auto,
                                size: 160,
                                gapless: false,
                                errorStateBuilder: (ctx, err) =>
                                    const Icon(Icons.error, size: 50, color: Colors.red),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          license.registerNumber,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'QR code refreshes every 5 minutes',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(IconData icon, String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFFC124)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.white),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 36, color: Colors.white54),
    );
  }

  Widget _statusChip(String status) {
    final lower = status.toLowerCase();
    Color bgColor, textColor;
    if (lower == 'active') {
      bgColor = Colors.green.shade700;
      textColor = Colors.white;
    } else if (lower == 'expired') {
      bgColor = Colors.red.shade700;
      textColor = Colors.white;
    } else {
      bgColor = Colors.orange.shade700;
      textColor = Colors.white;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}