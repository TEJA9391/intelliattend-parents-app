import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../Data/Models/Messaging/messaging_models.dart';
import '../../../../Data/Services/message_cache_service.dart';
import '../../../../Services/persistence_service.dart';
import '../../../../Theme/app_theme.dart';
import '../../Messaging/chat_screen.dart';
import '../../Messaging/Widgets/peer_avatar.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

/// School Parent Chat Tab — Exclusively shows:
/// 1. Class Teacher (pinned with role badge)
/// 2. Principal (pinned with administration badge)
/// 3. Teaching Faculty according to the student's daily timetable
class ParentChatTab extends StatefulWidget {
  const ParentChatTab({super.key});

  @override
  State<ParentChatTab> createState() => _ParentChatTabState();
}

class _ParentChatTabState extends State<ParentChatTab> {
  static const String _readChatsPrefKey = 'parent_read_chats_v1';

  final TextEditingController _searchController = TextEditingController();
  int _filterCategoryIndex =
      0; // 0: All, 1: Class Teacher, 2: Principal, 3: Timetable Faculty
  late Set<String> _readConversationIds;

  @override
  void initState() {
    super.initState();
    _readConversationIds = PersistenceService.isInitialized
        ? Set<String>.from(
            PersistenceService.prefs.getStringList(_readChatsPrefKey) ??
                const <String>[],
          )
        : <String>{};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatConversation> _getSchoolFacultyConversations(ChildProfile child) {
    final now = DateTime.now();

    if (child.id == 'child_2') {
      // Ananya (Class 7)
      return [
        ChatConversation(
          id: 'school_ct_ananya',
          peer: const StudentContact(
            id: 'teacher_kavita',
            name: 'Mrs. Kavita Reddy',
            department: 'Class Teacher • Class 7-B',
            section: 'Social Studies',
            email: 'kavita.reddy@intellischool.edu',
            phone: '+91 98450 67890',
            isOnline: true,
            isFaculty: true,
            customStatus: 'In Staff Room • Available for Parents',
          ),
          lastMessage:
              'Ananya participated enthusiastically in the classroom group discussion today.',
          lastMessageTime: now.subtract(const Duration(minutes: 35)),
          lastMessageStatus: MessageStatus.read,
          unreadCount: 1,
          isPinned: true,
        ),
        ChatConversation(
          id: 'school_principal',
          peer: const StudentContact(
            id: 'principal_meera',
            name: 'Dr. Meera Nambiar',
            department: 'Principal • Administration',
            section: 'Office of the Principal',
            email: 'principal@intellischool.edu',
            phone: '+91 98450 00100',
            isOnline: true,
            isFaculty: true,
            customStatus: 'Available by Appointment',
          ),
          lastMessage:
              'Warm greetings. The Parent-Teacher Open House is scheduled for this Saturday from 12:00 PM.',
          lastMessageTime: now.subtract(const Duration(days: 1, hours: 2)),
          lastMessageStatus: MessageStatus.read,
          unreadCount: 0,
          isPinned: true,
        ),
        ChatConversation(
          id: 'school_sci_ananya',
          peer: const StudentContact(
            id: 'teacher_sunita_sci',
            name: 'Mrs. Sunita Sharma',
            department: 'General Science • Period 1',
            section: 'Science Faculty',
            email: 'sunita.sharma@intellischool.edu',
            phone: '+91 98450 12345',
            isOnline: true,
            isFaculty: true,
          ),
          lastMessage:
              'Ananya showed great curiosity in the biology plant anatomy practical today.',
          lastMessageTime: now.subtract(const Duration(days: 1, hours: 5)),
          lastMessageStatus: MessageStatus.read,
          unreadCount: 0,
        ),
        ChatConversation(
          id: 'school_mth_ananya',
          peer: const StudentContact(
            id: 'teacher_pn_rao',
            name: 'Mr. P. N. Rao',
            department: 'Mathematics • Period 2',
            section: 'Math Department',
            email: 'pn.rao@intellischool.edu',
            phone: '+91 98450 33445',
            isOnline: false,
            isFaculty: true,
          ),
          lastMessage:
              'Please ensure Ananya practices the 10 worksheet problems on fractions.',
          lastMessageTime: now.subtract(const Duration(days: 2)),
          lastMessageStatus: MessageStatus.read,
          unreadCount: 0,
        ),
        ChatConversation(
          id: 'school_eng_ananya',
          peer: const StudentContact(
            id: 'teacher_priya_eng',
            name: 'Ms. Priya Nair',
            department: 'English Grammar • Period 4',
            section: 'Languages',
            email: 'priya.nair@intellischool.edu',
            phone: '+91 98450 55667',
            isOnline: true,
            isFaculty: true,
          ),
          lastMessage:
              'Grammar notebook verified. Handwriting is clean and well-maintained.',
          lastMessageTime: now.subtract(const Duration(days: 3)),
          lastMessageStatus: MessageStatus.read,
          unreadCount: 0,
        ),
        ChatConversation(
          id: 'school_art_ananya',
          peer: const StudentContact(
            id: 'teacher_meera_art',
            name: 'Mrs. Meera Roy',
            department: 'Art & Craft • Period 5',
            section: 'Creative Arts',
            email: 'meera.roy@intellischool.edu',
            phone: '+91 98450 77889',
            isOnline: false,
            isFaculty: true,
          ),
          lastMessage:
              'Ananya\'s watercolor artwork has been selected for the annual school bulletin!',
          lastMessageTime: now.subtract(const Duration(days: 4)),
          lastMessageStatus: MessageStatus.read,
          unreadCount: 0,
        ),
      ];
    }

    // Default: Aarav Boora (Class 10 - Section A)
    return [
      ChatConversation(
        id: 'school_ct_aarav',
        peer: const StudentContact(
          id: 'teacher_sunita',
          name: 'Mrs. Sunita Sharma',
          department: 'Class Teacher • Class 10-A',
          section: 'Mathematics (Period 1)',
          email: 'sunita.sharma@intellischool.edu',
          phone: '+91 98450 12345',
          isOnline: true,
          isFaculty: true,
          customStatus: 'Class Teacher 10-A • Available on Campus',
        ),
        lastMessage:
            'Aarav was very attentive in mathematics today. Please ensure he submits Chapter 4 homework tomorrow.',
        lastMessageTime: now.subtract(const Duration(minutes: 18)),
        lastMessageStatus: MessageStatus.delivered,
        unreadCount: 1,
        isPinned: true,
      ),
      ChatConversation(
        id: 'school_principal',
        peer: const StudentContact(
          id: 'principal_meera',
          name: 'Dr. Meera Nambiar',
          department: 'Principal • Administration',
          section: 'Office of the Principal',
          email: 'principal@intellischool.edu',
          phone: '+91 98450 00100',
          isOnline: true,
          isFaculty: true,
          customStatus: 'Available for Scheduled Parent Meetings',
        ),
        lastMessage:
            'Warm greetings. The Parent-Teacher Open House is scheduled for this coming Saturday from 12:00 PM.',
        lastMessageTime: now.subtract(const Duration(days: 1, hours: 2)),
        lastMessageStatus: MessageStatus.read,
        unreadCount: 0,
        isPinned: true,
      ),
      ChatConversation(
        id: 'school_eng_aarav',
        peer: const StudentContact(
          id: 'teacher_ananya',
          name: 'Mrs. Ananya Gupta',
          department: 'English Language & Literature • Period 2',
          section: 'Senior School Faculty',
          email: 'ananya.gupta@intellischool.edu',
          phone: '+91 98450 44321',
          isOnline: false,
          isFaculty: true,
        ),
        lastMessage:
            'Aarav scored 20/20 in the ASL speaking assessment. Excellent fluency and poise!',
        lastMessageTime: now.subtract(const Duration(days: 1, hours: 4)),
        lastMessageStatus: MessageStatus.read,
        unreadCount: 0,
      ),
      ChatConversation(
        id: 'school_sci_aarav',
        peer: const StudentContact(
          id: 'teacher_verma',
          name: 'Mr. R. K. Verma',
          department: 'Science (Physics & Chem) • Period 3',
          section: 'Science Laboratories',
          email: 'rk.verma@intellischool.edu',
          phone: '+91 98450 77123',
          isOnline: true,
          isFaculty: true,
        ),
        lastMessage:
            'Please review and countersign Aarav\'s Science practical record book by Wednesday.',
        lastMessageTime: now.subtract(const Duration(days: 2)),
        lastMessageStatus: MessageStatus.read,
        unreadCount: 0,
      ),
      ChatConversation(
        id: 'school_sst_aarav',
        peer: const StudentContact(
          id: 'teacher_kavita_sst',
          name: 'Mrs. Kavita Reddy',
          department: 'Social Science (History & Civics) • Period 4',
          section: 'Social Sciences',
          email: 'kavita.reddy@intellischool.edu',
          phone: '+91 98450 67890',
          isOnline: true,
          isFaculty: true,
        ),
        lastMessage:
            'India Map Pointing activity was completed neatly and verified.',
        lastMessageTime: now.subtract(const Duration(days: 3)),
        lastMessageStatus: MessageStatus.read,
        unreadCount: 0,
      ),
      ChatConversation(
        id: 'school_hin_aarav',
        peer: const StudentContact(
          id: 'teacher_joshi',
          name: 'Mr. Arvind Joshi',
          department: 'Hindi / Regional Language • Period 5',
          section: 'Indian Languages',
          email: 'arvind.joshi@intellischool.edu',
          phone: '+91 98450 99881',
          isOnline: false,
          isFaculty: true,
        ),
        lastMessage:
            'Hindi essay writing homework assigned on environmental awareness.',
        lastMessageTime: now.subtract(const Duration(days: 4)),
        lastMessageStatus: MessageStatus.read,
        unreadCount: 0,
      ),
      ChatConversation(
        id: 'school_cs_aarav',
        peer: const StudentContact(
          id: 'teacher_priya_cs',
          name: 'Ms. Priya Nair',
          department: 'Computer Science & AI Coding • Period 6',
          section: 'Computer Labs',
          email: 'priya.nair@intellischool.edu',
          phone: '+91 98450 55667',
          isOnline: true,
          isFaculty: true,
        ),
        lastMessage:
            'Aarav completed the Python calculator algorithm ahead of time in today\'s lab.',
        lastMessageTime: now.subtract(const Duration(days: 5)),
        lastMessageStatus: MessageStatus.read,
        unreadCount: 0,
      ),
      ChatConversation(
        id: 'school_pet_aarav',
        peer: const StudentContact(
          id: 'teacher_vikram_pet',
          name: 'Coach Vikram Singh',
          department: 'Physical Education & Games • Period 7',
          section: 'Sports Department',
          email: 'vikram.singh@intellischool.edu',
          phone: '+91 98450 88776',
          isOnline: false,
          isFaculty: true,
        ),
        lastMessage:
            'Aarav has been selected for the School Athletics 4x100m relay practice squad.',
        lastMessageTime: now.subtract(const Duration(days: 6)),
        lastMessageStatus: MessageStatus.read,
        unreadCount: 0,
      ),
    ];
  }

  List<ChatMessage> _getMockMessagesFor(ChatConversation conversation) {
    final now = DateTime.now();
    final cid = conversation.id;
    final teacher = conversation.peer;

    if (cid == 'school_ct_aarav') {
      return [
        ChatMessage(
          id: 'msg_ct_1',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Good morning Mrs. Sharma. Just checking how Aarav is doing in mathematics and overall classroom engagement.',
          timestamp: now.subtract(const Duration(days: 2, hours: 4)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_ct_2',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Good morning Mr. Boora. Aarav has been doing very well. He scored 96/100 in the recent assessment and grasps quadratic equations quickly.',
          timestamp: now.subtract(const Duration(days: 2, hours: 2)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_ct_3',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Thank you for the update! We made sure he spent extra time on exercise 4.2 practice problems yesterday.',
          timestamp: now.subtract(const Duration(hours: 3)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_ct_4',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Aarav was very attentive in mathematics today. Please ensure he submits Chapter 4 homework tomorrow.',
          timestamp: now.subtract(const Duration(minutes: 18)),
          status: MessageStatus.delivered,
        ),
      ];
    } else if (cid == 'school_principal') {
      return [
        ChatMessage(
          id: 'msg_pr_1',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Respected Principal Madam, we wanted to confirm the schedule for the Class 10 board preparation orientation.',
          timestamp: now.subtract(const Duration(days: 2, hours: 6)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_pr_2',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Warm greetings. The Parent-Teacher Open House is scheduled for this coming Saturday from 12:00 PM.',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_pr_3',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Thank you Dr. Meera, we have marked the calendar and will attend.',
          timestamp: now.subtract(const Duration(hours: 20)),
          status: MessageStatus.read,
        ),
      ];
    } else if (cid == 'school_eng_aarav') {
      return [
        ChatMessage(
          id: 'msg_eng_1',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Hello Mrs. Gupta, how did Aarav perform in the speaking and listening assessment?',
          timestamp: now.subtract(const Duration(days: 2, hours: 1)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_eng_2',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Aarav scored 20/20 in the ASL speaking assessment. Excellent fluency and poise!',
          timestamp: now.subtract(const Duration(days: 1, hours: 4)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_eng_3',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'That is wonderful to hear, thank you so much for mentoring him!',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          status: MessageStatus.read,
        ),
      ];
    } else if (cid == 'school_sci_aarav') {
      return [
        ChatMessage(
          id: 'msg_sci_1',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Good evening Mr. Verma, are the science practical records ready for parental review?',
          timestamp: now.subtract(const Duration(days: 3)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_sci_2',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Please review and countersign Aarav\'s Science practical record book by Wednesday.',
          timestamp: now.subtract(const Duration(days: 2)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_sci_3',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Sure sir, I will review all the experiment diagrams and countersign tonight.',
          timestamp: now.subtract(const Duration(days: 1, hours: 10)),
          status: MessageStatus.read,
        ),
      ];
    } else if (cid == 'school_sst_aarav') {
      return [
        ChatMessage(
          id: 'msg_sst_1',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Good day Mrs. Reddy, has Aarav submitted the 1857 Revolt history map work?',
          timestamp: now.subtract(const Duration(days: 3, hours: 6)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_sst_2',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text: 'India Map Pointing activity was completed neatly and verified.',
          timestamp: now.subtract(const Duration(days: 3)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_sst_3',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text: 'Thank you for confirming!',
          timestamp: now.subtract(const Duration(days: 2, hours: 5)),
          status: MessageStatus.read,
        ),
      ];
    } else if (cid == 'school_hin_aarav') {
      return [
        ChatMessage(
          id: 'msg_hin_1',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Hindi essay writing homework assigned. Aarav\'s vocabulary has noticeably improved.',
          timestamp: now.subtract(const Duration(days: 4)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_hin_2',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Thank you Mr. Joshi, we will make sure he finishes the essay today.',
          timestamp: now.subtract(const Duration(days: 3, hours: 22)),
          status: MessageStatus.read,
        ),
      ];
    } else if (cid == 'school_cs_aarav') {
      return [
        ChatMessage(
          id: 'msg_cs_1',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Aarav completed the Python calculator program successfully in the lab session today.',
          timestamp: now.subtract(const Duration(days: 5)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_cs_2',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Great! He enjoys coding and practicing logic at home as well.',
          timestamp: now.subtract(const Duration(days: 4, hours: 20)),
          status: MessageStatus.read,
        ),
      ];
    } else if (cid == 'school_pe_aarav') {
      return [
        ChatMessage(
          id: 'msg_pe_1',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Aarav has been selected for the School Inter-House Football Team for the upcoming tournament!',
          timestamp: now.subtract(const Duration(days: 6)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_pe_2',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'That is exciting news Coach! He will definitely be present for morning practice.',
          timestamp: now.subtract(const Duration(days: 5, hours: 18)),
          status: MessageStatus.read,
        ),
      ];
    } else if (cid == 'school_ct_ananya') {
      return [
        ChatMessage(
          id: 'msg_an_ct_1',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text: 'Good afternoon Mrs. Reddy, how is Ananya doing in Class 7-B?',
          timestamp: now.subtract(const Duration(hours: 3)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_an_ct_2',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text:
              'Ananya participated enthusiastically in the classroom group discussion today.',
          timestamp: now.subtract(const Duration(minutes: 35)),
          status: MessageStatus.delivered,
        ),
      ];
    } else {
      // General fallback
      return [
        ChatMessage(
          id: 'msg_${cid}_1',
          conversationId: cid,
          direction: MessageDirection.outgoing,
          type: MessageContentType.text,
          senderId: 'parent_user',
          senderName: 'Raviteja Boora',
          text:
              'Hello ${teacher.name}, regarding ${teacher.department ?? "academic updates"}.',
          timestamp: now.subtract(const Duration(days: 1)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg_${cid}_2',
          conversationId: cid,
          direction: MessageDirection.incoming,
          type: MessageContentType.text,
          senderId: teacher.id,
          senderName: teacher.name,
          text: conversation.lastMessage ??
              'Thank you for reaching out. We will keep you updated.',
          timestamp: conversation.lastMessageTime ??
              now.subtract(const Duration(hours: 2)),
          status: MessageStatus.delivered,
        ),
      ];
    }
  }

  void _openChat(BuildContext context, ChatConversation conversation) async {
    HapticFeedback.selectionClick();

    // Clear unread highlight immediately once the newly arrived chat is opened
    final readConversation = conversation.resetUnread();
    if (!_readConversationIds.contains(conversation.id)) {
      setState(() {
        _readConversationIds.add(conversation.id);
      });
      if (PersistenceService.isInitialized) {
        await PersistenceService.prefs.setStringList(
          _readChatsPrefKey,
          _readConversationIds.toList(),
        );
      }
    }

    // Cache conversation so ChatScreen can load history
    await MessageCacheService.instance.upsertConversation(readConversation);

    // Save full conversation history so ChatScreen is not empty
    final messages = _getMockMessagesFor(readConversation);
    await MessageCacheService.instance.saveMessages(conversation.id, messages);

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: readConversation),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _confirmCall(BuildContext context, StudentContact peer) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: Color(0xFF2DD4BF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirm Call',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to call ${peer.name}?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(context),
              ),
            ),
            if (peer.department != null && peer.department!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                peer.department!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded,
                      size: 16, color: Color(0xFF2DD4BF)),
                  const SizedBox(width: 8),
                  Text(
                    peer.phone ?? 'Not available',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppTheme.text(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will open your phone dialer to place the call.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _callFaculty(peer.phone);
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Call Now',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _callFaculty(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    HapticFeedback.lightImpact();
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentController = context.watch<ParentController>();
    final child = parentController.activeChild;

    final allConversations = _getSchoolFacultyConversations(child)
        .map((c) => _readConversationIds.contains(c.id) ? c.resetUnread() : c)
        .toList();
    final query = _searchController.text.trim().toLowerCase();

    // Category filter
    var filtered = allConversations.where((c) {
      if (_filterCategoryIndex == 1) {
        return c.peer.department?.contains('Class Teacher') ?? false;
      } else if (_filterCategoryIndex == 2) {
        return c.peer.department?.contains('Principal') ?? false;
      } else if (_filterCategoryIndex == 3) {
        return !(c.peer.department?.contains('Class Teacher') ?? false) &&
            !(c.peer.department?.contains('Principal') ?? false);
      }
      return true;
    }).toList();

    // Text search
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        final name = c.peer.name.toLowerCase();
        final dept = (c.peer.department ?? '').toLowerCase();
        final last = (c.lastMessage ?? '').toLowerCase();
        return name.contains(query) ||
            dept.contains(query) ||
            last.contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faculty Chat',
              style: GoogleFonts.inter(
                color: AppTheme.text(context),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Class Teacher • Principal • Timetable Faculty',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Child Selection Pills (Aarav / Ananya)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: parentController.children.map((c) {
                  final isSelected = c.id == child.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        parentController.switchChild(c.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2DD4BF)
                              : (isDark
                                  ? Colors.white10
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2DD4BF)
                                : (isDark
                                    ? Colors.white12
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${c.name} (${c.program} - ${c.semester})',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.text(context),
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2. Search Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppTheme.text(context), fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search by teacher name or subject...',
                  hintStyle: TextStyle(
                      color: AppTheme.textSecondary(context), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: AppTheme.textSecondary(context)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Category Filter Chips (All, Class Teacher, Principal, Timetable Faculty)
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCategoryChip(
                    'All (${allConversations.length})', 0, isDark),
                const SizedBox(width: 8),
                _buildCategoryChip('Class Teacher', 1, isDark),
                const SizedBox(width: 8),
                _buildCategoryChip('Principal', 2, isDark),
                const SizedBox(width: 8),
                _buildCategoryChip('Teaching Faculty', 3, isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // 4. Conversations List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 48, color: AppTheme.textSecondary(context)),
                        const SizedBox(height: 12),
                        Text(
                          'No faculty found matching search',
                          style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 74,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (ctx, idx) {
                      final c = filtered[idx];
                      final peer = c.peer;
                      final isUnread = c.unreadCount > 0;
                      final isClassTeacher =
                          peer.department?.contains('Class Teacher') ?? false;
                      final isPrincipal =
                          peer.department?.contains('Principal') ?? false;

                      final roleBadgeBg = isClassTeacher
                          ? const Color(0xFF2DD4BF).withValues(alpha: 0.15)
                          : isPrincipal
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : (isDark
                                  ? Colors.white10
                                  : const Color(0xFFF1F5F9));

                      final roleBadgeFg = isClassTeacher
                          ? const Color(0xFF2DD4BF)
                          : isPrincipal
                              ? const Color(0xFFF59E0B)
                              : AppTheme.textSecondary(ctx);

                      final roleBadgeText = isClassTeacher
                          ? 'Class Teacher'
                          : isPrincipal
                              ? 'Principal'
                              : 'Timetable Faculty';

                      return InkWell(
                        onTap: () => _openChat(context, c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Avatar with live presence indicator
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  PeerAvatar(
                                    name: peer.name,
                                    radius: 24,
                                    imageUrl: peer.avatarUrl,
                                  ),
                                  if (peer.isOnline)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 13,
                                        height: 13,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.bg(ctx),
                                            width: 2.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Chat Info: Name + Role Chip & Last Message only
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            peer.name,
                                            style: TextStyle(
                                              color: isUnread
                                                  ? AppTheme.text(ctx)
                                                  : AppTheme.text(ctx)
                                                      .withValues(alpha: 0.78),
                                              fontSize: 15,
                                              fontWeight: isUnread
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleBadgeBg,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            roleBadgeText,
                                            style: TextStyle(
                                              color: roleBadgeFg,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.lastMessage ??
                                          'Tap to start conversation',
                                      style: TextStyle(
                                        color: isUnread
                                            ? (isDark
                                                ? const Color(0xFF2DD4BF)
                                                : const Color(0xFF0F766E))
                                            : AppTheme.textSecondary(ctx),
                                        fontSize: 13,
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Right side: Call button only
                              IconButton(
                                icon: Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                  color: AppTheme.textSecondary(ctx),
                                ),
                                tooltip: 'Call Faculty',
                                onPressed: () => _confirmCall(context, peer),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int index, bool isDark) {
    final isSelected = _filterCategoryIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterCategoryIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2DD4BF).withValues(alpha: 0.18)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2DD4BF)
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF2DD4BF)
                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
