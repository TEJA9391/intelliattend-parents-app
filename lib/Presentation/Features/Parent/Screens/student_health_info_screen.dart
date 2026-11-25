import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

class StudentHealthInfoScreen extends StatefulWidget {
  final ChildProfile child;

  const StudentHealthInfoScreen({super.key, required this.child});

  @override
  State<StudentHealthInfoScreen> createState() => _StudentHealthInfoScreenState();
}

class _StudentHealthInfoScreenState extends State<StudentHealthInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _bloodGroup;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicConditionsController;
  late TextEditingController _dailyMedsController;
  late TextEditingController _criticalDirectivesController;
  late bool _isOrganDonor;

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _dietaryNeedsController;
  late TextEditingController _sensoryAidsController;

  late TextEditingController _insuranceProviderController;
  late TextEditingController _insurancePolicyController;
  late TextEditingController _campusOpdIdController;
  late TextEditingController _doctorNameController;
  late TextEditingController _doctorPhoneController;
  late TextEditingController _preferredHospitalController;

  bool _isSaving = false;
  bool _isSyncing = false;

  final List<String> _bloodGroupOptions = [
    'A+ve',
    'A-ve',
    'B+ve',
    'B-ve',
    'O+ve',
    'O-ve',
    'AB+ve',
    'AB-ve',
  ];

  @override
  void initState() {
    super.initState();
    final controller = context.read<ParentController>();
    final record = controller.healthRecordForChild(widget.child.id);

    _bloodGroup =
        _bloodGroupOptions.contains(record.bloodGroup) ? record.bloodGroup : null;

    _allergiesController = TextEditingController(text: record.allergies);
    _chronicConditionsController =
        TextEditingController(text: record.chronicConditions);
    _dailyMedsController = TextEditingController(text: record.dailyMedications);
    _criticalDirectivesController =
        TextEditingController(text: record.criticalDirectives);
    _isOrganDonor = record.isOrganDonor;

    _heightController = TextEditingController(text: record.heightCm);
    _weightController = TextEditingController(text: record.weightKg);
    _dietaryNeedsController = TextEditingController(text: record.dietaryNeeds);
    _sensoryAidsController = TextEditingController(text: record.sensoryAids);

    _insuranceProviderController =
        TextEditingController(text: record.insuranceProvider);
    _insurancePolicyController =
        TextEditingController(text: record.insurancePolicyNumber);
    _campusOpdIdController =
        TextEditingController(text: record.campusClinicOpdId);
    _doctorNameController =
        TextEditingController(text: record.primaryDoctorName);
    _doctorPhoneController =
        TextEditingController(text: record.primaryDoctorPhone);
    _preferredHospitalController =
        TextEditingController(text: record.preferredHospital);

    Future.microtask(() => _syncFromServer());
  }

  Future<void> _syncFromServer() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    final controller = context.read<ParentController>();
    await controller.fetchProfileFromServer();
    if (!mounted) return;
    final record = controller.healthRecordForChild(widget.child.id);
    setState(() {
      _isSyncing = false;
      if (_bloodGroup == null && _bloodGroupOptions.contains(record.bloodGroup)) {
        _bloodGroup = record.bloodGroup;
      }
      void fillIfEmpty(TextEditingController ctrl, String serverVal) {
        if (ctrl.text.trim().isEmpty && serverVal.trim().isNotEmpty) {
          ctrl.text = serverVal;
        }
      }

      fillIfEmpty(_allergiesController, record.allergies);
      fillIfEmpty(_chronicConditionsController, record.chronicConditions);
      fillIfEmpty(_dailyMedsController, record.dailyMedications);
      fillIfEmpty(_criticalDirectivesController, record.criticalDirectives);
      fillIfEmpty(_heightController, record.heightCm);
      fillIfEmpty(_weightController, record.weightKg);
      fillIfEmpty(_dietaryNeedsController, record.dietaryNeeds);
      fillIfEmpty(_sensoryAidsController, record.sensoryAids);
      fillIfEmpty(_insuranceProviderController, record.insuranceProvider);
      fillIfEmpty(_insurancePolicyController, record.insurancePolicyNumber);
      fillIfEmpty(_campusOpdIdController, record.campusClinicOpdId);
      fillIfEmpty(_doctorNameController, record.primaryDoctorName);
      fillIfEmpty(_doctorPhoneController, record.primaryDoctorPhone);
      fillIfEmpty(_preferredHospitalController, record.preferredHospital);
      if (record.isOrganDonor) {
        _isOrganDonor = true;
      }
    });
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    _dailyMedsController.dispose();
    _criticalDirectivesController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dietaryNeedsController.dispose();
    _sensoryAidsController.dispose();
    _insuranceProviderController.dispose();
    _insurancePolicyController.dispose();
    _campusOpdIdController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    _preferredHospitalController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final updatedRecord = StudentHealthRecord(
      childId: widget.child.id,
      bloodGroup: _bloodGroup ?? '',
      allergies: _allergiesController.text.trim(),
      chronicConditions: _chronicConditionsController.text.trim(),
      dailyMedications: _dailyMedsController.text.trim(),
      criticalDirectives: _criticalDirectivesController.text.trim(),
      isOrganDonor: _isOrganDonor,
      heightCm: _heightController.text.trim(),
      weightKg: _weightController.text.trim(),
      dietaryNeeds: _dietaryNeedsController.text.trim(),
      sensoryAids: _sensoryAidsController.text.trim(),
      insuranceProvider: _insuranceProviderController.text.trim(),
      insurancePolicyNumber: _insurancePolicyController.text.trim(),
      campusClinicOpdId: _campusOpdIdController.text.trim(),
      primaryDoctorName: _doctorNameController.text.trim(),
      primaryDoctorPhone: _doctorPhoneController.text.trim(),
      preferredHospital: _preferredHospitalController.text.trim(),
    );

    final controller = context.read<ParentController>();
    final syncedToServer =
        await controller.updateChildHealthRecord(widget.child.id, updatedRecord);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      AppSnackBar.showSuccess(
        context,
        syncedToServer
            ? 'Medical records synced with server!'
            : 'Saved locally — will sync with server automatically.',
        icon: syncedToServer
            ? Icons.cloud_done_rounded
            : Icons.check_circle_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2DD4BF);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.text(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Student Health & Medical ID',
          style: TextStyle(
            color: AppTheme.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            // Top Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.3)
                      : AppTheme.border(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.health_and_safety_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.child.name}\'s Medical ID',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isSyncing
                              ? 'Syncing medical records from school server...'
                              : 'Provided by school server. Edits saved here sync to official medical records.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: Emergency & Critical Vitals
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Critical Emergency Vitals',
                    Icons.emergency_rounded,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),

                  // Blood Group Dropdown
                  Text(
                    'Blood Group (Syncs to Campus ID)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _bloodGroup,
                        hint: Text(
                          'Select blood group',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: AppTheme.card(context),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: primaryColor),
                        items: _bloodGroupOptions.map((bg) {
                          return DropdownMenuItem(
                            value: bg,
                            child: Row(
                              children: [
                                const Icon(Icons.water_drop_rounded,
                                    size: 16, color: Color(0xFFEF4444)),
                                const SizedBox(width: 8),
                                Text(
                                  bg,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          setState(() => _bloodGroup = newVal);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _allergiesController,
                    label: 'Allergies & Severe Reactions',
                    hintText: 'Enter allergies (if any)',
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.amber,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _chronicConditionsController,
                    label: 'Ongoing Conditions / Diagnosis',
                    hintText: 'Enter ongoing medical conditions',
                    icon: Icons.medical_information_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _dailyMedsController,
                    label: 'Daily / SOS Medications',
                    hintText: 'Enter regular or emergency medications',
                    icon: Icons.medication_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _criticalDirectivesController,
                    label: 'Emergency First-Aid Directive',
                    hintText: 'Enter first-aid instructions',
                    icon: Icons.assignment_late_outlined,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // Organ Donor Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite_rounded,
                                size: 20, color: primaryColor),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Organ Donor Status',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.text(context),
                                  ),
                                ),
                                Text(
                                  _isOrganDonor ? 'Registered Organ Donor' : 'Not Registered',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isOrganDonor,
                          activeThumbColor: primaryColor,
                          onChanged: (val) {
                            setState(() => _isOrganDonor = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 2: Biometrics & Lifestyle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Biometrics & Lifestyle Needs',
                    Icons.accessibility_new_rounded,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'Height (cm)',
                          hintText: 'Enter cm',
                          icon: Icons.height_rounded,
                          keyboardType: TextInputFormattersHelper.digitsOnly,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'Weight (kg)',
                          hintText: 'Enter kg',
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: TextInputFormattersHelper.digitsOnly,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _dietaryNeedsController,
                    label: 'Dietary Needs / Restrictions',
                    hintText: 'Enter dietary restrictions',
                    icon: Icons.restaurant_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _sensoryAidsController,
                    label: 'Sensory / Mobility Aids',
                    hintText: 'Enter glasses or assistive aids',
                    icon: Icons.visibility_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 3: School Clinic & Insurance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'School Clinic & Insurance',
                    Icons.local_hospital_rounded,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _insuranceProviderController,
                    label: 'Student Health Insurance Provider',
                    hintText: 'Enter insurance provider',
                    icon: Icons.health_and_safety_outlined,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _insurancePolicyController,
                    label: 'Insurance Policy / Card Number',
                    hintText: 'Enter policy number',
                    icon: Icons.credit_card_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _campusOpdIdController,
                    label: 'School Health Center OPD Reg #',
                    hintText: 'Enter OPD registration ID',
                    icon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _doctorNameController,
                    label: 'Primary Care Physician / Doctor',
                    hintText: 'Enter doctor name',
                    icon: Icons.person_pin_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _doctorPhoneController,
                    label: 'Primary Doctor Phone',
                    hintText: 'Enter doctor phone number',
                    icon: Icons.phone_in_talk_rounded,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _preferredHospitalController,
                    label: 'Preferred Emergency Hospital',
                    hintText: 'Enter hospital name',
                    icon: Icons.local_hospital_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Health Records',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.text(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    Color? iconColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2DD4BF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.text(context),
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppTheme.surface(context),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: iconColor ?? primaryColor,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class TextInputFormattersHelper {
  static const TextInputType digitsOnly = TextInputType.number;
}
