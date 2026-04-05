import 'package:flutter/material.dart';
import '../models/TrafficOfficerModels/license.dart';
import '../theme/app_theme.dart';

class LicenseSearchDialog extends StatefulWidget {
  final List<License> licenses;
  final Function(License) onLicenseSelected;

  const LicenseSearchDialog({
    super.key,
    required this.licenses,
    required this.onLicenseSelected,
  });

  @override
  State<LicenseSearchDialog> createState() => _LicenseSearchDialogState();
}

class _LicenseSearchDialogState extends State<LicenseSearchDialog> {
  late TextEditingController _searchController;
  late List<License> _filteredLicenses;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredLicenses = widget.licenses;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLicenses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLicenses = widget.licenses;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredLicenses =
            widget.licenses
                .where(
                  (license) =>
                      license.registerNumber.toLowerCase().contains(
                        lowerQuery,
                      ) ||
                      license.ownerName.toLowerCase().contains(lowerQuery),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select License',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterLicenses,
              decoration: InputDecoration(
                hintText: 'Search by registration or name...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white10,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // License List
          Flexible(
            child:
                _filteredLicenses.isEmpty
                    ? Container(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No licenses found'
                              : 'No matches found',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredLicenses.length,
                      itemBuilder: (context, index) {
                        final license = _filteredLicenses[index];
                        return GestureDetector(
                          onTap: () {
                            widget.onLicenseSelected(license);
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  license.registerNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  license.ownerName,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      license.licenseType,
                                      style: const TextStyle(
                                        color: AppTheme.gold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            license.isExpired
                                                ? Colors.red.withOpacity(0.2)
                                                : Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        license.isExpired ? 'Expired' : 'Valid',
                                        style: TextStyle(
                                          color:
                                              license.isExpired
                                                  ? Colors.red[300]
                                                  : Colors.green[300],
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
