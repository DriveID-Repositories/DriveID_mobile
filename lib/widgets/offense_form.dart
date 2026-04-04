import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OffenseFormData {
  final String offenseType;
  final String? fine;
  final String location;

  OffenseFormData({
    required this.offenseType,
    this.fine,
    required this.location,
  });
}

class OffenseForm extends StatefulWidget {
  final String licenseId;
  final String licenseOwnerName;
  final String registrationNumber;
  final List<String> offenseTypes;
  final Map<String, String> offenseFines;
  final Function(OffenseFormData) onSubmit;
  final VoidCallback onCancel;

  const OffenseForm({
    super.key,
    required this.licenseId,
    required this.licenseOwnerName,
    required this.registrationNumber,
    required this.offenseTypes,
    required this.offenseFines,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<OffenseForm> createState() => _OffenseFormState();
}

class _OffenseFormState extends State<OffenseForm> {
  late TextEditingController _offenseTypeController;
  late TextEditingController _locationController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _offenseTypeController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _offenseTypeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_offenseTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an offense type')),
      );
      return;
    }

    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a location')));
      return;
    }

    setState(() => _isSubmitting = true);

    final fine = widget.offenseFines[_offenseTypeController.text] ?? 'TBD';
    final formData = OffenseFormData(
      offenseType: _offenseTypeController.text,
      fine: fine,
      location: _locationController.text,
    );

    widget.onSubmit(formData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Record Offense',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'License Owner: ${widget.licenseOwnerName}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              // Offense Type Dropdown
              const Text(
                'Offense Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child:
                    widget.offenseTypes.isEmpty
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Loading offense types...',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                        : DropdownButtonFormField<String>(
                          initialValue:
                              _offenseTypeController.text.isEmpty
                                  ? null
                                  : _offenseTypeController.text,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: AppTheme.cardDark,
                          items:
                              widget.offenseTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(
                              () =>
                                  _offenseTypeController.text =
                                      value ?? _offenseTypeController.text,
                            );
                          },
                          hint: const Text(
                            'Select an offense...',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
              ),
              const SizedBox(height: 24),

              // Show Fine if offense type selected
              if (_offenseTypeController.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fine Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.offenseFines[_offenseTypeController.text] ??
                            'TBD',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // Location Field
              const Text(
                'Location',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Enter offense location',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.gold,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting || widget.offenseTypes.isEmpty
                              ? null
                              : widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting || widget.offenseTypes.isEmpty
                              ? null
                              : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                              : const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
