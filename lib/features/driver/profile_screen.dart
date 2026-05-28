import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:driveid_app/features/driver/services/user_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<Map<String, dynamic>>> _offensesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _profileFuture = _fetchDriverFullProfile();
    _offensesFuture = _fetchOffenses();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await Future.wait([_profileFuture, _offensesFuture]);
  }

  Future<Map<String, dynamic>?> _fetchDriverFullProfile() async {
    final supabase = Supabase.instance.client;
    final driverId = UserSession().userId;  // ✅ Use stored driver ID

    if (driverId == null) return null;

    final response = await supabase
        .from('drivers')
        .select('''
          full_name,
          email,
          phone_number,
          driver_photo_url,
          national_id,
          date_of_birth,
          licenses!inner(
            license_number,
            license_class,
            issue_date,
            expiry_date,
            license_status
          )
        ''')
        .eq('id', driverId)  // ✅ Query by driver ID, not auth_user_id
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchOffenses() async {
    final supabase = Supabase.instance.client;
    final driverId = UserSession().driverId;
    if (driverId == null) return [];

    final license = await supabase
        .from('licenses')
        .select('license_number')
        .eq('driver_id', driverId)
        .maybeSingle();
    if (license == null) return [];

    final offenses = await supabase
        .from('offenses')
        .select()
        .eq('registration_number', license['license_number'])
        .order('created_at', ascending: false);
    return offenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16161C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC124)));
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(snapshot.hasError ? 'Error: ${snapshot.error}' : 'No profile found', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC124), foregroundColor: Colors.black87),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final profile = snapshot.data!;
            final license = profile['licenses'] as List<dynamic>?;
            final licenseData = (license != null && license.isNotEmpty) ? license.first as Map<String, dynamic> : null;

            final photoUrl = profile['driver_photo_url'];
            final fullName = profile['full_name'] ?? 'Not set';
            final email = profile['email'] ?? 'Not set';
            final phone = profile['phone_number'] ?? 'Not set';
            final nationalId = profile['national_id'] ?? 'Not set';
            final dob = profile['date_of_birth'] != null ? _formatDate(DateTime.parse(profile['date_of_birth'])) : 'Not set';
            final licenseNumber = licenseData?['license_number'] ?? 'Not issued';
            final licenseClass = licenseData?['license_class'] ?? 'None';
            final issueDate = licenseData?['issue_date'] != null ? _formatDate(DateTime.parse(licenseData!['issue_date'])) : 'None';
            final expiryDate = licenseData?['expiry_date'] != null ? _formatDate(DateTime.parse(licenseData!['expiry_date'])) : 'None';
            final licenseStatus = licenseData?['license_status'] ?? 'None';

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photoUrl != null && photoUrl.toString().isNotEmpty
                        ? Image.network(photoUrl, width: 150, height: 150, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar())
                        : _defaultAvatar(),
                  ),
                  const SizedBox(height: 16),

                  _infoCard('Personal Information', [
                    _infoTile('Full Name', fullName),
                    _infoTile('National ID', nationalId),
                    _infoTile('Date of Birth', dob),
                    _infoTile('Email', email),
                    _infoTile('Phone Number', phone),
                  ]),

                  const SizedBox(height: 24),

                  _infoCard('Driving License Information', [
                    _infoTile('License Number', licenseNumber),
                    _infoTile('License Class', licenseClass),
                    _infoTile('Issue Date', issueDate),
                    _infoTile('Expiry Date', expiryDate),
                    _statusTile('Status', licenseStatus),
                  ]),

                  const SizedBox(height: 24),

                  _infoCard('Offenses', [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _offensesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        if (snapshot.hasError || snapshot.data == null) return const Padding(padding: EdgeInsets.all(16), child: Text('Failed to load offenses', style: TextStyle(color: Colors.white70)));
                        final offenses = snapshot.data!;
                        if (offenses.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No offenses recorded', style: TextStyle(color: Colors.white54)));
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offenses.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                          itemBuilder: (context, index) {
                            final off = offenses[index];
                            final status = off['status'] ?? 'Pending';
                            final isPaidOrResolved = status.toLowerCase() == 'paid' || status.toLowerCase() == 'resolved';
                            return ListTile(
                              leading: Icon(isPaidOrResolved ? Icons.check_circle : Icons.warning_amber, color: isPaidOrResolved ? Colors.green : Colors.orange),
                              title: Text(off['offense_type'], style: const TextStyle(color: Colors.white)),
                              subtitle: Text('${off['location']} • ${_formatDateString(off['created_at'])}', style: const TextStyle(color: Colors.white54)),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('MK ${off['fine']}', style: const TextStyle(color: Color(0xFFFFC124))),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: isPaidOrResolved ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: Text(status.toUpperCase(), style: TextStyle(color: isPaidOrResolved ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 32),
                  const Text('This information is managed by the government registry.', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) => Container(
        decoration: BoxDecoration(color: const Color(0xFF1C1C24), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text(title, style: const TextStyle(color: Color(0xFFFFC124), fontSize: 16, fontWeight: FontWeight.bold))),
            const Divider(color: Colors.white24, height: 24, indent: 16, endIndent: 16),
            ...children.map((child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child)),
            const SizedBox(height: 8),
          ],
        ),
      );

  Widget _infoTile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500))),
            Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.right)),
          ],
        ),
      );

  Widget _statusTile(String label, String status) {
    Color? color;
    switch (status.toLowerCase()) {
      case 'valid':
        color = Colors.green.shade400;
        break;
      case 'expired':
        color = Colors.red.shade400;
        break;
      case 'suspended':
        color = Colors.orange.shade400;
        break;
      default:
        color = Colors.white70;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500))),
          Expanded(child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatDateString(String iso) => _formatDate(DateTime.parse(iso));

  Widget _defaultAvatar() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person, size: 60, color: Color(0xFFFFC124)),
    );
  }
}