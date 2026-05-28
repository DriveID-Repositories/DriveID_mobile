// lib/features/driver/my_license_tab.dart
// ignore_for_file: dead_code

import 'dart:async';
import 'package:driveid_app/features/driver/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../traffic_officer/services/auth_service.dart';
import '../traffic_officer/models/driver_license.dart' as local;

class DriverFullProfile {
  final local.DriverLicense license;
  final String sex;
  final String nationality;
  final DateTime? dob;
  DriverFullProfile({
    required this.license,
    required this.sex,
    required this.nationality,
    required this.dob,
  });
}

class MyLicenseTab extends StatefulWidget {
  const MyLicenseTab({super.key});

  @override
  State<MyLicenseTab> createState() => _MyLicenseTabState();
}

class _MyLicenseTabState extends State<MyLicenseTab> {
  late Future<DriverFullProfile> _profileFuture;
  late Timer _qrRefreshTimer;
  final ValueNotifier<String> _qrData = ValueNotifier<String>('');
  bool _sessionSet = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchFullProfile();
    _qrRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_qrData.value.isNotEmpty) {
        final reg = _qrData.value.split('|')[0];
        _generateQRData(reg);
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _fetchFullProfile();
    });
    await _profileFuture;
  }

  @override
  void dispose() {
    _qrRefreshTimer.cancel();
    _qrData.dispose();
    super.dispose();
  }

  Future<DriverFullProfile> _fetchFullProfile() async {
    final hasBackendSession = await AuthService.appToken != null;
    if (hasBackendSession) {
      final backendData = await AuthService.fetchDriverLicenseFromBackend();
      return _profileFromBackendPayload(backendData);
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final driverResponse = await supabase
        .from('drivers')
        .select('id, full_name, driver_photo_url, national_id')
        .eq('auth_user_id', user.id)
        .maybeSingle();
    if (driverResponse == null) throw Exception('No driver profile found');

    final driverId = driverResponse['id'];
    final fullName = driverResponse['full_name'];
    final photoUrl = driverResponse['driver_photo_url'];
    final nationalId = driverResponse['national_id'];

    Map<String, dynamic>? citizenData;
    if (nationalId != null) {
      citizenData = await supabase
          .from('citizens')
          .select('sex, nationality, dob')
          .eq('national_id_number', nationalId)
          .maybeSingle();
    }

    final sex = _firstNonEmpty([
      citizenData?['sex']?.toString(),
      driverResponse['sex']?.toString(),
    ]);
    final nationality = _firstNonEmpty([
      citizenData?['nationality']?.toString(),
      driverResponse['nationality']?.toString(),
    ]);
    final dobRaw = citizenData?['dob'] ?? driverResponse['date_of_birth'];
    final dob = dobRaw != null ? DateTime.tryParse(dobRaw.toString()) : null;

    final licenseResponse = await supabase
        .from('licenses')
        .select()
        .eq('driver_id', driverId)
        .maybeSingle();
    if (licenseResponse == null) throw Exception('No license found');

    return _profileFromRows(
      licenseResponse: licenseResponse,
      fullName: fullName,
      photoUrl: photoUrl,
      sex: sex,
      nationality: nationality,
      dob: dob,
    );
  }

  DriverFullProfile _profileFromBackendPayload(Map<String, dynamic> data) {
    final driver = Map<String, dynamic>.from(data['driver'] as Map);
    final licenseResponse = Map<String, dynamic>.from(data['license'] as Map);
    final citizen = data['citizen'] is Map
        ? Map<String, dynamic>.from(data['citizen'] as Map)
        : null;

    final sex = _firstNonEmpty([
      citizen?['sex']?.toString(),
      driver['sex']?.toString(),
    ]);
    final nationality = _firstNonEmpty([
      citizen?['nationality']?.toString(),
      driver['nationality']?.toString(),
    ]);
    final dobRaw = citizen?['dob'] ?? driver['date_of_birth'];
    final dob = dobRaw != null ? DateTime.tryParse(dobRaw.toString()) : null;

    return _profileFromRows(
      licenseResponse: licenseResponse,
      fullName: driver['full_name']?.toString() ?? '',
      photoUrl: driver['driver_photo_url']?.toString(),
      sex: sex,
      nationality: nationality,
      dob: dob,
    );
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'Not available';
  }

  DriverFullProfile _profileFromRows({
    required Map<String, dynamic> licenseResponse,
    required String fullName,
    String? photoUrl,
    required String sex,
    required String nationality,
    DateTime? dob,
  }) {
    final combined = {
      ...licenseResponse,
      'full_name': fullName,
      'photo_url': photoUrl,
      'register_number': licenseResponse['license_number'],
      'license_type': licenseResponse['license_class'],
      'status': licenseResponse['license_status'],
    };
    final license = local.DriverLicense.fromJson(combined);
    return DriverFullProfile(
      license: license,
      sex: sex,
      nationality: nationality,
      dob: dob,
    );
  }

  void _generateQRData(String registerNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final verificationUrl = 'https://driveid.gov.mw/verify/$registerNumber?t=$timestamp';
    _qrData.value = verificationUrl;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DriverFullProfile>(
      future: _profileFuture,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _profileFuture = _fetchFullProfile();
                    });
                  },
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

        final profile = snapshot.data!;
        final license = profile.license;
        if (!_sessionSet) {
          _sessionSet = true;
          UserSession().setUser(license.driverId ?? '', reg: license.registerNumber);
          _generateQRData(license.registerNumber);
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                
                _buildLicenseCard(profile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLicenseCard(DriverFullProfile profile) {
    final license = profile.license;

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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(color: Color(0xFFFFC124)),
              child: Stack(
                children: [
                  Row(
                    children: [
                      const Text('🇲🇼', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REPUBLIC OF MALAWI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 0.8),
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
                  Positioned(top: 0, right: 0, child: _statusChip(license.status)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo and name
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: license.photoUrl != null && license.photoUrl!.isNotEmpty
                            ? Image.network(license.photoUrl!, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar())
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
                  // License details row
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
                  const SizedBox(height: 16),
                  // Citizen details row
                  Row(
                    children: [
                      Expanded(child: _infoColumn(Icons.person, 'SEX', profile.sex)),
                      Expanded(child: _infoColumn(Icons.flag, 'NATIONALITY', profile.nationality)),
                      Expanded(child: _infoColumn(Icons.cake, 'DATE OF BIRTH', _formatDate(profile.dob))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 24),
                  // QR Code inside the license card
                  Center(
                    child: Column(
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: _qrData,
                          builder: (context, data, child) {
                            final qrData = data.isNotEmpty ? data : 'https://driveid.gov.mw/verify';
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                              ),
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 160,
                                gapless: false,
                                errorStateBuilder: (ctx, err) => const Icon(Icons.error, size: 50, color: Colors.red),
                              ),
                            );
                          },
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
            Icon(icon, size: 14, color: const Color(0xFFFFC124)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? Colors.white),
          overflow: TextOverflow.ellipsis,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person, size: 36, color: Colors.white54),
    );
  }

  Widget _statusChip(String status) {
    final lower = status.toLowerCase();
    Color bgColor, textColor;
    if (lower == 'valid' || lower == 'active') {
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
    return '${date.day} ${_monthAbbr(date.month)} ${date.year}';
  }

  String _monthAbbr(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

}