import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

class ParentNoticesFacultyTab extends StatefulWidget {
  const ParentNoticesFacultyTab({super.key});

  @override
  State<ParentNoticesFacultyTab> createState() => _ParentNoticesFacultyTabState();
}

class _ParentNoticesFacultyTabState extends State<ParentNoticesFacultyTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentController>();
    final notices = controller.notices;
    final mentors = controller.mentors;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notices & Faculty Connect',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.text(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary(context),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Circulars & Notices'),
                Tab(text: 'Faculty Mentors'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNoticesList(context, notices),
          _buildMentorsList(context, mentors),
        ],
      ),
    );
  }


  Future<void> _makeCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer for $phone'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, String email, String mentorName) async {
    final cleanEmail = email.trim();
    final subject = Uri.encodeComponent('Parent Inquiry - $mentorName');
    final uri = Uri.parse('mailto:$cleanEmail?subject=$subject');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email app for $email'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildNoticesList(BuildContext context, List<CampusNotice> notices) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: notices.length,
      itemBuilder: (ctx, index) {
        final notice = notices[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: notice.categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notice.category.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: notice.categoryColor,
                      ),
                    ),
                  ),
                  Text(
                    dateFormat.format(notice.publishedDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notice.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notice.fullContent,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF2DD4BF)),
                  const SizedBox(width: 6),
                  Text(
                    notice.publishedBy,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2DD4BF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMentorsList(BuildContext context, List<FacultyMentor> mentors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: mentors.length,
      itemBuilder: (ctx, index) {
        final mentor = mentors[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    child: Text(
                      mentor.name[0],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentor.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mentor.designation,
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
              const SizedBox(height: 14),
              _buildMentorDetailRow(
                context,
                icon: Icons.meeting_room_outlined,
                label: 'Cabin',
                value: mentor.officeRoom,
              ),
              const SizedBox(height: 6),
              _buildMentorDetailRow(
                context,
                icon: Icons.schedule_rounded,
                label: 'Office Hours',
                value: mentor.availableHours,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(context, mentor.phone),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Call', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2DD4BF),
                        side: const BorderSide(color: Color(0xFF2DD4BF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendEmail(context, mentor.email, mentor.name),
                      icon: const Icon(Icons.email_outlined, size: 16),
                      label: const Text('Email', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMentorDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF2DD4BF)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.text(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
