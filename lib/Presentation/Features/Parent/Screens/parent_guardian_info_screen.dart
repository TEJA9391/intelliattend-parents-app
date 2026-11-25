import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';

class ParentGuardianInfoScreen extends StatefulWidget {
  const ParentGuardianInfoScreen({super.key});

  @override
  State<ParentGuardianInfoScreen> createState() => _ParentGuardianInfoScreenState();
}

class _ParentGuardianInfoScreenState extends State<ParentGuardianInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;
  late TextEditingController _emergencyPhoneController;
  String? _relationship;

  bool _isSaving = false;
  bool _isSyncing = false;

  final List<String> _relationshipOptions = [
    'Father',
    'Mother',
    'Legal Guardian',
    'Relative / Local Guardian',
  ];

  @override
  void initState() {
    super.initState();
    final controller = context.read<ParentController>();
    _nameController = TextEditingController(text: controller.parentName);
    _phoneController = TextEditingController(text: controller.parentPhone);
    _emailController = TextEditingController(text: controller.parentEmail);
    _cityController = TextEditingController(text: controller.parentCity);
    _emergencyPhoneController =
        TextEditingController(text: controller.emergencyContactPhone);
    _relationship = _relationshipOptions.contains(controller.guardianRelationship)
        ? controller.guardianRelationship
        : null;

    Future.microtask(() => _syncFromServer());
  }

  Future<void> _syncFromServer() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    final controller = context.read<ParentController>();
    await controller.fetchProfileFromServer();
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      if (_nameController.text.trim().isEmpty &&
          controller.parentName.trim().isNotEmpty) {
        _nameController.text = controller.parentName;
      }
      if (_phoneController.text.trim().isEmpty &&
          controller.parentPhone.trim().isNotEmpty) {
        _phoneController.text = controller.parentPhone;
      }
      if (_emailController.text.trim().isEmpty &&
          controller.parentEmail.trim().isNotEmpty) {
        _emailController.text = controller.parentEmail;
      }
      if (_cityController.text.trim().isEmpty &&
          controller.parentCity.trim().isNotEmpty) {
        _cityController.text = controller.parentCity;
      }
      if (_emergencyPhoneController.text.trim().isEmpty &&
          controller.emergencyContactPhone.trim().isNotEmpty) {
        _emergencyPhoneController.text = controller.emergencyContactPhone;
      }
      if (_relationship == null &&
          _relationshipOptions.contains(controller.guardianRelationship)) {
        _relationship = controller.guardianRelationship;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final controller = context.read<ParentController>();
    final syncedToServer = await controller.updateGuardianInfo(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      city: _cityController.text,
      relationship: _relationship ?? '',
      emergencyPhone: _emergencyPhoneController.text,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      AppSnackBar.showSuccess(
        context,
        syncedToServer
            ? 'Guardian profile synced with server!'
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
          'Guardian Information',
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
                    child: const Icon(Icons.family_restroom_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Guardian Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isSyncing
                              ? 'Syncing latest records from school server...'
                              : 'Provided by school server. Edits saved here sync to the server automatically.',
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

            // Form Fields Container
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
                  _buildSectionHeader('Personal Details', primaryColor),
                  const SizedBox(height: 14),

                  // Parent Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Parent / Guardian Full Name',
                    icon: Icons.person_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter parent name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Relationship Dropdown
                  Text(
                    'Relationship to Student',
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
                        value: _relationship,
                        hint: Text(
                          'Select relationship',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: AppTheme.card(context),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: primaryColor),
                        items: _relationshipOptions.map((rel) {
                          return DropdownMenuItem(
                            value: rel,
                            child: Text(
                              rel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text(context),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _relationship = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Contact & Residential Info', primaryColor),
                  const SizedBox(height: 14),

                  // Primary Phone
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Primary Contact Mobile',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter contact number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Emergency Secondary Phone
                  _buildTextField(
                    controller: _emergencyPhoneController,
                    label: 'Secondary / Emergency Contact',
                    icon: Icons.contact_phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Registered Email Address',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val != null &&
                          val.trim().isNotEmpty &&
                          !val.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // City & Residential Address
                  _buildTextField(
                    controller: _cityController,
                    label: 'Residential City & State',
                    icon: Icons.home_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Saving Changes...' : 'Save Guardian Profile',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppTheme.text(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary(context),
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF2DD4BF)),
        filled: true,
        fillColor: AppTheme.surface(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
        ),
      ),
    );
  }
}