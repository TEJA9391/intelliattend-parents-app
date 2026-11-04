import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../../../../Theme/theme_controller.dart';
import '../Controllers/parent_controller.dart';
import '../Widgets/child_switcher_bar.dart';

class ParentProfileTab extends StatelessWidget {
  const ParentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentController>();
    final child = controller.activeChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Student & Guardian Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.text(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        physics: const BouncingScrollPhysics(),
        children: [
          const ChildSwitcherBar(),

          // Digital Student ID Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school_rounded, color: Color(0xFF2DD4BF), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'INTELLIATTEND CAMPUS ID',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF2DD4BF),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        child.bloodGroup,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
                      child: Text(
                        child.name[0],
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Roll No: ${child.rollNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            child.program,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Class Advisor: ${child.mentorName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2DD4BF)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Guardian Info Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Guardian Information',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.text(context),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              children: [
                _buildInfoRow(context, icon: Icons.person_outline_rounded, label: 'Parent Name', value: 'Mr. & Mrs. Sharma'),
                const Divider(height: 16),
                _buildInfoRow(context, icon: Icons.phone_outlined, label: 'Primary Contact', value: '+91 98765 43210'),
                const Divider(height: 16),
                _buildInfoRow(context, icon: Icons.email_outlined, label: 'Registered Email', value: 'parent.sharma@gmail.com'),
                const Divider(height: 16),
                _buildInfoRow(context, icon: Icons.home_outlined, label: 'Residential City', value: 'Bengaluru, Karnataka'),
              ],
            ),
          ),

          // App Settings & Preferences
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'App Preferences',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.text(context),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          size: 20,
                          color: const Color(0xFF2DD4BF),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Theme Mode',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.text(context),
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: isDark,
                      activeThumbColor: const Color(0xFF2DD4BF),
                      onChanged: (val) {
                        ThemeController.toggle();
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, size: 20, color: Color(0xFF2DD4BF)),
                        SizedBox(width: 12),
                        Text(
                          'Daily Attendance Alerts',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: true,
                      activeThumbColor: const Color(0xFF2DD4BF),
                      onChanged: (val) {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Campus helplines
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Campus Support Contacts',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.text(context),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              children: [
                _buildEmergencyItem(context, title: 'Academic Office Helpdesk', phone: '+91 80 2345 6789'),
                const Divider(height: 16),
                _buildEmergencyItem(context, title: 'Student Health Centre', phone: '+91 80 2345 6700'),
                const Divider(height: 16),
                _buildEmergencyItem(context, title: 'Dean of Student Affairs', phone: '+91 80 2345 6750'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2DD4BF)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.text(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyItem(
    BuildContext context, {
    required String title,
    required String phone,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.text(context),
          ),
        ),
        Text(
          phone,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2DD4BF),
          ),
        ),
      ],
    );
  }
}
