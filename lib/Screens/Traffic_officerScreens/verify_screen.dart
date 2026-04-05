import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/verification_result_card.dart';
import '../../widgets/offense_form.dart';
import '../../services/TrafficOfficerServices/dashboard_service.dart';
import '../../services/TrafficOfficerServices/offense_service.dart';
import '../../models/TrafficOfficerModels/license.dart';
import '../Traffic_OfficerScreens/dashboard_screen.dart';
import 'offenses_screen.dart';

enum VerificationStatus { none, success, inactive, notFound, error }

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen>
    with TickerProviderStateMixin {
  bool isQRMode = true; // Changed: QR Scan is now default
  bool isScanned = false;
  bool _isVerifying = false;
  bool _showOffenseForm = false;

  License? _verificationLicense;
  String? _verificationMessage;
  VerificationStatus _verificationStatus = VerificationStatus.none;
  List<String> _offenseTypes = [];
  Map<String, String> _offenseFines = {};

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final DashboardService _dashboardService = DashboardService();
  final OffenseService _offenseService = OffenseService();
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOffenseTypes();
  }

  Future<void> _loadOffenseTypes() async {
    try {
      final types = await _offenseService.getOffenseTypes();
      if (mounted) {
        setState(() {
          _offenseTypes = types.map((t) => t.label).toList();
          _offenseFines = {for (var type in types) type.label: type.fine};
        });
      }
    } catch (e) {
      print('Error loading offense types: $e');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (idx) {
          if (idx == 1) return;
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else if (idx == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OffensesScreen()),
            );
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Verify User",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Scan QR code or search by register number",
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Modern Toggle Buttons
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  _buildModernToggle(
                    text: "QR Scan",
                    icon: Icons.qr_code_scanner_rounded,
                    isActive: isQRMode,
                    onTap: () => setState(() {
                      isQRMode = true;
                      isScanned = false;
                    }),
                  ),
                  _buildModernToggle(
                    text: "Manual",
                    icon: Icons.keyboard_outlined,
                    isActive: !isQRMode,
                    onTap: () => setState(() {
                      isQRMode = false;
                      isScanned = false;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Content
            Expanded(
              child: _verificationStatus == VerificationStatus.none
                  ? (isQRMode ? _qrScannerView() : _manualView())
                  : _resultView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernToggle({
    required String text,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.black : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.black : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qrScannerView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      if (isScanned) return;
                      for (final b in capture.barcodes) {
                        if (b.rawValue != null && b.rawValue!.isNotEmpty) {
                          setState(() => isScanned = true);
                          _onQRScanned(b.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                  // Scan Frame Overlay
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.gold,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Corner animations
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppTheme.gold, width: 4),
                                  left: BorderSide(color: AppTheme.gold, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppTheme.gold, width: 4),
                                  right: BorderSide(color: AppTheme.gold, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.gold, width: 4),
                                  left: BorderSide(color: AppTheme.gold, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.gold, width: 4),
                                  right: BorderSide(color: AppTheme.gold, width: 4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code, color: AppTheme.gold, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Position QR code within the frame",
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => controller.toggleTorch(),
              icon: const Icon(Icons.flashlight_on, size: 18),
              label: const Text("Flashlight"),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () => controller.switchCamera(),
              icon: const Icon(Icons.cameraswitch, size: 18),
              label: const Text("Switch Camera"),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _manualView() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _manualController,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Enter 14-digit register number",
                    hintStyle: TextStyle(color: AppTheme.textLight),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search_outlined, color: AppTheme.gold),
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onManualVerify(),
                ),
              ),
              const Divider(height: 1, color: AppTheme.cardBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppTheme.textLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Format: 14-digit number (e.g., 20260104008973)",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _onManualVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Verify License",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _resultView() {
    if (_verificationLicense == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _verificationMessage ?? 'Verification failed',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _resetVerification,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          child: VerificationResultCard(
            license: _verificationLicense!,
            onRecordOffense: () => setState(() => _showOffenseForm = true),
          ),
        ),
        if (_showOffenseForm)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showOffenseForm = false),
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: GestureDetector(
                  onTap: () {},
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    builder: (context, scrollController) {
                      return OffenseForm(
                        licenseId: _verificationLicense!.id,
                        licenseOwnerName: _verificationLicense!.ownerName,
                        registrationNumber: _verificationLicense!.registerNumber,
                        offenseTypes: _offenseTypes,
                        offenseFines: _offenseFines,
                        onSubmit: _handleOffenseSubmit,
                        onCancel: () => setState(() => _showOffenseForm = false),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleOffenseSubmit(OffenseFormData formData) async {
    if (_verificationLicense == null) return;
    try {
      await _offenseService.recordOffenseForLicense(
        licenseId: _verificationLicense!.id,
        licenseOwnerName: _verificationLicense!.ownerName,
        registrationNumber: _verificationLicense!.registerNumber,
        offenseType: formData.offenseType,
        location: formData.location,
        fine: formData.fine ?? 'TBD',
      );
      if (mounted) {
        setState(() => _showOffenseForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offense recorded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record offense: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _resetVerification() {
    setState(() {
      _verificationStatus = VerificationStatus.none;
      _verificationMessage = null;
      _verificationLicense = null;
      _showOffenseForm = false;
      isScanned = false;
      _manualController.clear();
    });
  }

  void _onQRScanned(String code) async {
    try {
      await _verifyLicense(code);
    } finally {
      setState(() => isScanned = false);
    }
  }

  void _onManualVerify() async {
    FocusScope.of(context).unfocus();
    final regNumber = _manualController.text.trim();
    if (regNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a registration number')),
      );
      return;
    }
    if (!RegExp(r'^\d{14}$').hasMatch(regNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid registration number format')),
      );
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await _verifyLicense(regNumber);
    } finally {
      setState(() => _isVerifying = false);
      _manualController.clear();
    }
  }

  Future<void> _verifyLicense(String registrationNumber) async {
    try {
      final success = await _dashboardService.verifyAndRecordLicense(
        registrationNumber,
      );
      final license = await _dashboardService.getLicenseDetails(
        registrationNumber,
      );
      if (!mounted) return;
      if (success && license != null) {
        setState(() {
          _verificationStatus = VerificationStatus.success;
          _verificationMessage = 'License verified and recorded';
          _verificationLicense = license;
        });
      } else if (license != null) {
        setState(() {
          _verificationStatus = VerificationStatus.inactive;
          _verificationMessage = 'License is inactive or expired';
          _verificationLicense = license;
        });
      } else {
        setState(() {
          _verificationStatus = VerificationStatus.notFound;
          _verificationMessage = 'License not found in the system';
          _verificationLicense = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verificationStatus = VerificationStatus.error;
        _verificationMessage = 'Verification error: $e';
        _verificationLicense = null;
      });
    }
  }
}