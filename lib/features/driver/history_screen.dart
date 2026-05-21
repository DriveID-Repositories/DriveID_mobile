import 'package:driveid_app/features/driver/services/activity_service.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    _activitiesFuture = ActivityService().fetchUserActivities();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadActivities();
    });
    await _activitiesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC124)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
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
          final activities = snapshot.data!;
          if (activities.isEmpty) {
            return const Center(child: Text('No activities recorded', style: TextStyle(color: Colors.white54)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white24),
            itemBuilder: (context, index) {
              final item = activities[index];
              final action = item['action'];
              final details = item['details'];
              final createdAt = DateTime.parse(item['created_at']);
              return ListTile(
                leading: _actionIcon(action),
                title: Text(_formatActionTitle(action), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: details != null && details.isNotEmpty ? Text(details, style: const TextStyle(color: Colors.white54, fontSize: 12)) : null,
                trailing: Text(_formatTime(createdAt), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionIcon(String action) {
    switch (action) {
      case 'login': return const Icon(Icons.login, color: Color(0xFFFFC124));
      case 'logout': return const Icon(Icons.logout, color: Colors.redAccent);
      case 'view_license': return const Icon(Icons.credit_card, color: Color(0xFFFFC124));
      case 'view_profile': return const Icon(Icons.person, color: Color(0xFFFFC124));
      case 'view_settings': return const Icon(Icons.settings, color: Color(0xFFFFC124));
      case 'change_password': return const Icon(Icons.lock, color: Color(0xFFFFC124));
      case 'offense_recorded': return const Icon(Icons.gavel, color: Colors.redAccent);
      case 'offense_paid': return const Icon(Icons.payment, color: Colors.green);
      case 'offense_cleared': return const Icon(Icons.check_circle, color: Colors.green);
      default: return const Icon(Icons.info, color: Color(0xFFFFC124));
    }
  }

  String _formatActionTitle(String action) {
    switch (action) {
      case 'login': return 'Logged In';
      case 'logout': return 'Logged Out';
      case 'view_license': return 'License Viewed';
      case 'view_profile': return 'Profile Viewed';
      case 'view_settings': return 'Settings Opened';
      case 'change_password': return 'Password Changed';
      case 'offense_recorded': return 'Offense Issued';
      case 'offense_paid': return 'Offense Paid';
      case 'offense_cleared': return 'Offense Cleared';
      default: return action.replaceAll('_', ' ');
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}