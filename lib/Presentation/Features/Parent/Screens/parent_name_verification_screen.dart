import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Theme/app_theme.dart';

class ParentNameVerificationScreen extends StatefulWidget {
  final Function(String parentName) onVerified;
  final String? initialName;

  const ParentNameVerificationScreen({
    super.key,
    required this.onVerified,
    this.initialName,
  });

  @override
  State<ParentNameVerificationScreen> createState() =>
      _ParentNameVerificationScreenState();
}

class _ParentNameVerificationScreenState
    extends State<ParentNameVerificationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _showingChildrenConfirmation = false;
  String? _errorMessage;
  String _enteredParentName = '';
  String _extractedSurname = 'Sharma';

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null && widget.initialName!.trim().isNotEmpty) {
      _nameController.text = widget.initialName!.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleFindChildren() {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name.';
      });
      return;
    }

    final words = rawName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) {
      setState(() {
        _errorMessage =
            'Please enter your full name with surname (e.g. Rajesh Sharma) so college records can match your children.';
      });
      return;
    }

    setState(() {
      _enteredParentName = rawName;
      _extractedSurname = words.last;
      _errorMessage = null;
      _showingChildrenConfirmation = true;
    });
  }

  Future<void> _handleConfirmChildren() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_full_name', _enteredParentName);
    await prefs.setBool('parent_identity_verified', true);

    if (mounted) {
      widget.onVerified(_enteredParentName);
    }
  }

  void _handleRejectChildren() {
    setState(() {
      _showingChildrenConfirmation = false;
      _errorMessage =
          'Please check your name with the correct surname as registered in college records.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _showingChildrenConfirmation
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.text(context),
                ),
                onPressed: () {
                  setState(() {
                    _showingChildrenConfirmation = false;
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showingChildrenConfirmation
              ? _buildChildrenConfirmationView(context, isDark)
              : _buildNameInputView(context, isDark),
        ),
      ),
    );
  }

  // View 1: Name Input View
  Widget _buildNameInputView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('name_input_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Radiant Guardian Badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF14B8A6).withValues(alpha: 0.14),
              border: Border.all(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.supervised_user_circle_rounded,
                size: 44,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Campus Header Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(width: 6),
                Text(
                  'PARENT VERIFICATION',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            'Enter Your Full Name',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.text(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Enter your full name with surname as registered with the college administration to link your student wards.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Error / Surname Warning Banner
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Name Text Field
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _errorMessage != null
                    ? const Color(0xFFEF4444)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFCBD5E1)),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(context),
              ),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF0F766E),
                  size: 22,
                ),
                hintText: 'e.g. Rajesh Sharma / Boora Raviteja',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? const Color(0xFF71717A)
                      : const Color(0xFF94A3B8),
                ),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _nameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              onSubmitted: (_) => _handleFindChildren(),
            ),
          ),
          const SizedBox(height: 12),

          // Helper instruction
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Make sure your surname matches the campus enrollment record.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF71717A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleFindChildren,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Find My Children',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // View 2: Children Confirmation View
  Widget _buildChildrenConfirmationView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('children_confirmation_view'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Match badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  '2 CHILDREN FOUND',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Greeting
          Text(
            'Is this you, $_enteredParentName?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.text(context),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),

          // Prompt
          Text(
            'Please confirm if these 2 enrolled students are your children:',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 22),

          // Child 1 Card
          _buildChildCard(
            context,
            isDark: isDark,
            name: 'Aarav $_extractedSurname',
            rollNumber: '21CS042',
            program: 'B.Tech - Computer Science & Engineering',
            semester: 'Semester VI (Sec A)',
            mentor: 'Dr. Rajeshwari Raman',
            avatarUrl:
                'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
            bloodGroup: 'O+ve',
          ),
          const SizedBox(height: 12),

          // Child 2 Card
          _buildChildCard(
            context,
            isDark: isDark,
            name: 'Ananya $_extractedSurname',
            rollNumber: '24EC118',
            program: 'B.Tech - Electronics & Communication',
            semester: 'Semester II (Sec C)',
            mentor: 'Prof. Ananth Kumar',
            avatarUrl:
                'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
            bloodGroup: 'B+ve',
          ),
          const SizedBox(height: 26),

          // Button 1: Yes, These are my children (Confirm & Continue)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleConfirmChildren,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Yes, These Are My Children',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Button 2: No, Check name again (Wrong surname)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _handleRejectChildren,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_note_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No, Check Name (Wrong Surname)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChildCard(
    BuildContext context, {
    required bool isDark,
    required String name,
    required String rollNumber,
    required String program,
    required String semester,
    required String mentor,
    required String avatarUrl,
    required String bloodGroup,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                backgroundImage: NetworkImage(avatarUrl),
                onBackgroundImageError: (_, __) {},
                child: Text(
                  name.isNotEmpty ? name[0] : 'S',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.text(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Active',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      program,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0F766E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Roll: $rollNumber • $semester',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 14, color: Color(0xFF0F766E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Class Advisor: $mentor',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

