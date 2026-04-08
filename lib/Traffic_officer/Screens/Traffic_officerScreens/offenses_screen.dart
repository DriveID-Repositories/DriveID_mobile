import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/license_search_dialog.dart';
import '../../widgets/license_preview_card.dart';
import '../../services/TrafficOfficerServices/offense_service.dart';
import '../../services/TrafficOfficerServices/dashboard_service.dart';
import '../../models/TrafficOfficerModels/offense.dart';
import '../../models/TrafficOfficerModels/license.dart';
import '../Traffic_OfficerScreens/dashboard_screen.dart';
import 'verify_screen.dart';

class OffensesScreen extends StatefulWidget {
  const OffensesScreen({super.key});

  @override
  State<OffensesScreen> createState() => _OffensesScreenState();
}

class _OffensesScreenState extends State<OffensesScreen> {
  bool isRecording = false;
  final TextEditingController locationController = TextEditingController();
  String? selectedOffenseId;
  License? _selectedLicense;

  final OffenseService _offenseService = OffenseService();
  final DashboardService _dashboardService = DashboardService();
  List<Offense> _offenses = [];
  List<OffenseType> _offenseTypes = [];
  List<License> _allLicenses = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final offenses = await _offenseService.getOffenses();
      final fetchedTypes = await _offenseService.getOffenseTypes();
      final licenses = await _dashboardService.getAllLicenses();

      final defaultTypes = <OffenseType>[
        OffenseType(id: '1', label: 'Speeding', fine: 'MWK 25,000'),
        OffenseType(id: '2', label: 'Driving without license', fine: 'MWK 50,000'),
        OffenseType(id: '3', label: 'Reckless driving', fine: 'MWK 75,000'),
        OffenseType(id: '4', label: 'Drunk driving', fine: 'MWK 100,000'),
        OffenseType(id: '5', label: 'Dangerous driving', fine: 'MWK 150,000'),
      ];
      
      // Remove duplicates by using a Set based on unique identifier
      final uniqueOffenses = offenses.fold<List<Offense>>([], (list, item) {
        if (!list.any((o) => o.id == item.id)) {
          list.add(item);
        }
        return list;
      });
      
      setState(() {
        _offenses = uniqueOffenses;
        _offenseTypes = fetchedTypes.isNotEmpty ? fetchedTypes : defaultTypes;
        _allLicenses = licenses;
        selectedOffenseId = _offenseTypes.isNotEmpty ? _offenseTypes.first.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _submitOffense() async {
    if (_selectedLicense == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a license'), backgroundColor: AppTheme.warning),
      );
      return;
    }
    if (locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location'), backgroundColor: AppTheme.warning),
      );
      return;
    }
    if (selectedOffenseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an offense type'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            const SizedBox(width: 10),
            const Text('Confirm Offense', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmationRow('Driver', _selectedLicense!.ownerName),
            _buildConfirmationRow('License', _selectedLicense!.registerNumber),
            const Divider(color: AppTheme.cardBorder),
            _buildConfirmationRow('Offense', _offenseTypes.firstWhere((t) => t.id == selectedOffenseId).label),
            _buildConfirmationRow('Fine', _offenseTypes.firstWhere((t) => t.id == selectedOffenseId).fine),
            _buildConfirmationRow('Location', locationController.text),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Record'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final selectedType = _offenseTypes.firstWhere((type) => type.id == selectedOffenseId);
      await _offenseService.createOffense(
        name: _selectedLicense!.ownerName,
        registrationNumber: _selectedLicense!.registerNumber,
        offenseTypeId: selectedOffenseId!,
        offenseType: selectedType.label,
        location: locationController.text,
        fine: selectedType.fine,
      );

      // Reset form
      locationController.clear();
      selectedOffenseId = _offenseTypes.isNotEmpty ? _offenseTypes.first.id : null;
      _selectedLicense = null;
      isRecording = false;
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offense recorded successfully'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record offense: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (idx) {
          if (idx == 2) return;
          if (idx == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          } else if (idx == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerifyScreen()));
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Offenses',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Record and manage traffic violations',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Record Offense Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Record New Offense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: isRecording 
                        ? LinearGradient(colors: [AppTheme.error, AppTheme.error.withAlpha(204)])
                        : LinearGradient(colors: [AppTheme.gold, AppTheme.goldLight]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => isRecording = !isRecording),
                    icon: Icon(isRecording ? Icons.close : Icons.add, color: Colors.black),
                    label: Text(isRecording ? 'Close' : 'Record', style: const TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Record Form
            if (isRecording)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // License Search
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => LicenseSearchDialog(
                                licenses: _allLicenses,
                                onLicenseSelected: (license) => setState(() => _selectedLicense = license),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search, size: 20),
                          label: const Text('Search License', style: TextStyle(fontSize: 15)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // License Preview
                      if (_selectedLicense != null)
                        Column(
                          children: [
                            LicensePreviewCard(
                              license: _selectedLicense!,
                              onEdit: () {
                                setState(() => _selectedLicense = null);
                                showDialog(
                                  context: context,
                                  builder: (_) => LicenseSearchDialog(
                                    licenses: _allLicenses,
                                    onLicenseSelected: (license) => setState(() => _selectedLicense = license),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),

                      // Location Field
                      const Text('Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        enabled: _selectedLicense != null,
                        decoration: InputDecoration(
                          hintText: _selectedLicense == null ? 'Select a license first' : 'Enter offense location',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          filled: true,
                          fillColor: AppTheme.background,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Offense Type
                      const Text('Offense Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedOffenseId,
                            isExpanded: true,
                            dropdownColor: AppTheme.cardDark,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            hint: const Text('Select offense type'),
                            items: _offenseTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type.id,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(type.label),
                                    const SizedBox(width: 10),
                                    Text(type.fine, style: TextStyle(color: AppTheme.gold)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => selectedOffenseId = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isSubmitting || _selectedLicense == null || locationController.text.isEmpty || selectedOffenseId == null)
                              ? null
                              : _submitOffense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text('Review & Record Offense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // Recent Offenses Section
            const Text(
              'Recent Offenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_offenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_outlined, size: 48, color: AppTheme.textSecondary),
                      SizedBox(height: 12),
                      Text('No offenses recorded yet', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _offenses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildOffenseCard(_offenses[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffenseCard(Offense offense) {
    final isPending = offense.status.toLowerCase() == 'pending';
    final ribbonColor = isPending ? AppTheme.warning : AppTheme.success;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ribbonColor.withAlpha(77), width: 1),
        boxShadow: [
          BoxShadow(
            color: ribbonColor.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Victorian-style Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ribbonColor, ribbonColor.withAlpha(204)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      offense.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  offense.fine,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_outline, color: AppTheme.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offense.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            offense.registrationNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.cardBorder, height: 1),
                const SizedBox(height: 12),

                // Offense Details
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        offense.offenseType,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offense.location,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}