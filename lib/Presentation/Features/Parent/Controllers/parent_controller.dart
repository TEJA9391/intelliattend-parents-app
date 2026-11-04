import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../Services/notification_service.dart';
import '../Models/parent_models.dart';

class ParentController extends ChangeNotifier {
  ParentController() {
    _initMockData();
    if (_childTransits.values.any((t) => t.isOnBus)) {
      _startTransitTimer();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _activeChildId = 'child_1';
  String get activeChildId => _activeChildId;

  final List<ChildProfile> _children = [];
  List<ChildProfile> get children => List.unmodifiable(_children);

  ChildProfile get activeChild =>
      _children.firstWhere((c) => c.id == _activeChildId, orElse: () => _children.first);

  // Today's classes for active child
  final Map<String, List<PeriodAttendance>> _childTodayClasses = {};
  List<PeriodAttendance> get todayClasses =>
      _childTodayClasses[_activeChildId] ?? [];

  // Subject attendance for active child
  final Map<String, List<SubjectAttendance>> _childSubjects = {};
  List<SubjectAttendance> get subjects =>
      _childSubjects[_activeChildId] ?? [];

  // Leave requests for active child
  final List<LeaveRequest> _leaveRequests = [];
  List<LeaveRequest> get activeChildLeaveRequests =>
      _leaveRequests.where((l) => l.childId == _activeChildId).toList();

  // College notices (global for parents)
  final List<CampusNotice> _notices = [];
  List<CampusNotice> get notices => List.unmodifiable(_notices);

  // Faculty mentors
  final List<FacultyMentor> _mentors = [];
  List<FacultyMentor> get mentors => List.unmodifiable(_mentors);

  // Real-time Bus Transit Tracking
  final Map<String, StudentBusTransit> _childTransits = {};
  Timer? _transitSimulationTimer;

  StudentBusTransit? get activeChildTransit => _childTransits[_activeChildId];
  StudentBusTransit? childTransit(String childId) => _childTransits[childId];
  bool get isChildOnBus => _childTransits[_activeChildId]?.isOnBus ?? false;
  bool isChildIdOnBus(String childId) => _childTransits[childId]?.isOnBus ?? false;

  void tapRfidBoardBus(String childId) {
    final existing = _childTransits[childId];
    if (existing == null) return;

    // Automatic Morning vs Evening Transit:
    // 1. If child was last deboarded at School -> next trip is return to Home!
    // 2. If child was last deboarded at Home -> next trip is morning to School!
    // 3. Otherwise determined by time of day: before 12:00 PM is to School, 12:00 PM onwards is to Home.
    final TransitDestinationType destType;
    if (existing.deboardedAt != null) {
      destType = existing.destinationType == TransitDestinationType.school
          ? TransitDestinationType.home
          : TransitDestinationType.school;
    } else {
      destType = DateTime.now().hour < 12
          ? TransitDestinationType.school
          : TransitDestinationType.home;
    }

    final destTitle = destType == TransitDestinationType.school
        ? 'School Campus Gate'
        : 'Home';

    final routeTitle = destType == TransitDestinationType.school
        ? 'Route 14B • Morning School Express'
        : 'Route 14B • Evening Home Express';

    _childTransits[childId] = existing.copyWith(
      isOnBus: true,
      boardedAt: DateTime.now(),
      progressFraction: 0.12,
      estimatedMinutes: 14,
      remainingKm: 4.8,
      currentSpeed: 36.0,
      stage: TransitStage.boarded,
      destinationType: destType,
      destinationCampus: destTitle,
      routeName: routeTitle,
      stops: _updateStopsProgress(existing.stops, 0.12),
    );

    _startTransitTimer();
    notifyListeners();

    // Trigger instant system push alert to parent
    final child = _children.firstWhere((c) => c.id == childId, orElse: () => _children.first);
    NotificationService().showNotification(
      id: childId.hashCode,
      title: '🚌 Bus Boarded Alert',
      body: '${child.name} has tapped their RFID card and boarded ${existing.busNumber}. Live tracking is active.',
    );
  }

  /// Called when student taps RFID on the physical reader device on the bus to exit / deboard
  void tapRfidDeboardBus(String childId) {
    final existing = _childTransits[childId];
    if (existing == null) return;

    final reachedStage = existing.destinationType == TransitDestinationType.school
        ? TransitStage.reachedSchool
        : TransitStage.reachedHome;

    _childTransits[childId] = existing.copyWith(
      isOnBus: false, // Stops map tracking and restores Enrolled Student Card
      stage: reachedStage,
      deboardedAt: DateTime.now(),
      currentSpeed: 0.0,
      progressFraction: 0.0,
    );

    final anyOnBus = _childTransits.values.any((t) => t.isOnBus);
    if (!anyOnBus) {
      _transitSimulationTimer?.cancel();
      _transitSimulationTimer = null;
    }

    notifyListeners();

    // Trigger arrival / deboard alert to parent
    final child = _children.firstWhere((c) => c.id == childId, orElse: () => _children.first);
    final placeName = existing.destinationType == TransitDestinationType.school ? 'Campus' : 'Home';
    NotificationService().showNotification(
      id: childId.hashCode + 1,
      title: '🏡 Safely Arrived at $placeName',
      body: '${child.name} has safely reached $placeName (${existing.destinationCampus}). Live location tracking exited.',
    );
  }

  void toggleBusTransit(String childId) {
    final existing = _childTransits[childId];
    if (existing == null) return;
    if (existing.isOnBus) {
      tapRfidDeboardBus(childId);
    } else {
      tapRfidBoardBus(childId);
    }
  }

  List<StudentTransitStop> _updateStopsProgress(List<StudentTransitStop> stops, double progress) {
    return stops.map((stop) {
      final isCompleted = progress >= stop.progressFraction;
      final isNext = !isCompleted && (progress < stop.progressFraction);
      return stop.copyWith(
        isCompleted: isCompleted,
        isNext: isNext,
      );
    }).toList();
  }

  void _startTransitTimer() {
    _transitSimulationTimer?.cancel();
    _transitSimulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      bool anyUpdated = false;

      for (final childId in _childTransits.keys) {
        final current = _childTransits[childId];
        if (current != null && current.isOnBus) {
          // If already reached destination, automatically exit live tracking
          if (current.isReached) {
            final targetChildId = childId;
            Timer(const Duration(milliseconds: 1500), () {
              final active = _childTransits[targetChildId];
              if (active != null && active.isOnBus) {
                tapRfidDeboardBus(targetChildId);
              }
            });
            continue;
          }

          double newProgress = current.progressFraction + 0.024;
          if (newProgress >= 1.0) {
            newProgress = 1.0;
          }

          // Interpolate GPS coordinates along the route
          final startLat = 12.9141;
          final startLng = 77.6411;
          final destLat = current.destLat;
          final destLng = current.destLng;
          final curLat = startLat + (destLat - startLat) * newProgress;
          final curLng = startLng + (destLng - startLng) * newProgress;

          if (newProgress >= 0.98) {
            // REACHED DESTINATION! Bus arrives at campus or home
            final reachedStage = current.destinationType == TransitDestinationType.school
                ? TransitStage.reachedSchool
                : TransitStage.reachedHome;

            _childTransits[childId] = current.copyWith(
              progressFraction: 1.0,
              estimatedMinutes: 0,
              remainingKm: 0.0,
              currentSpeed: 0.0,
              stage: reachedStage,
              reachedAt: DateTime.now(),
              currentLat: destLat,
              currentLng: destLng,
              stops: current.stops.map((s) => s.copyWith(isCompleted: true, isNext: false)).toList(),
            );
            anyUpdated = true;

            // Automatically exit location tracking and return to dashboard after arriving
            final targetChildId = childId;
            Timer(const Duration(milliseconds: 2000), () {
              final active = _childTransits[targetChildId];
              if (active != null && active.isOnBus) {
                tapRfidDeboardBus(targetChildId);
              }
            });
          } else {
            final estMins = ((1.0 - newProgress) * 15).ceil().clamp(1, 20);
            final remKm = double.parse(((1.0 - newProgress) * 5.2).clamp(0.1, 5.2).toStringAsFixed(1));
            final randomFluct = 34.0 + (sin(newProgress * 20) * 8.0).abs();

            TransitStage newStage;
            if (newProgress < 0.18) {
              newStage = TransitStage.boarded;
            } else if (newProgress < 0.88) {
              newStage = TransitStage.inTransit;
            } else {
              newStage = TransitStage.approachingCampus;
            }

            _childTransits[childId] = current.copyWith(
              progressFraction: newProgress,
              estimatedMinutes: estMins,
              remainingKm: remKm,
              currentSpeed: double.parse(randomFluct.toStringAsFixed(1)),
              stage: newStage,
              currentLat: curLat,
              currentLng: curLng,
              stops: _updateStopsProgress(current.stops, newProgress),
            );
            anyUpdated = true;
          }
        }
      }

      if (anyUpdated) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _transitSimulationTimer?.cancel();
    super.dispose();
  }

  void switchChild(String childId) {
    if (_activeChildId == childId) return;
    _activeChildId = childId;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 650));
    _isLoading = false;
    notifyListeners();
  }

  void submitLeaveRequest({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) {
    final newLeave = LeaveRequest(
      id: 'leave_${DateTime.now().millisecondsSinceEpoch}',
      childId: _activeChildId,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: LeaveStatus.pending,
      appliedAt: DateTime.now(),
      reviewRemarks: 'Under review by Department Class Advisor.',
    );

    _leaveRequests.insert(0, newLeave);
    notifyListeners();
  }

  void _initMockData() {
    // 1. Linked Children
    _children.addAll([
      const ChildProfile(
        id: 'child_1',
        name: 'Aarav Sharma',
        rollNumber: '21CS042',
        program: 'B.Tech - Computer Science & Engineering',
        semester: 'Semester VI (Sec A)',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
        bloodGroup: 'O+ve',
        mentorName: 'Dr. Rajeshwari Raman',
        mentorPhone: '+91 98450 12345',
        overallAttendance: 84.6,
        academicYear: '2026 - 2027',
      ),
      const ChildProfile(
        id: 'child_2',
        name: 'Ananya Sharma',
        rollNumber: '24EC118',
        program: 'B.Tech - Electronics & Communication',
        semester: 'Semester II (Sec C)',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
        bloodGroup: 'B+ve',
        mentorName: 'Prof. Ananth Kumar',
        mentorPhone: '+91 98450 67890',
        overallAttendance: 71.8,
        academicYear: '2026 - 2027',
      ),
    ]);

    // 2. Child 1 Classes Today
    _childTodayClasses['child_1'] = [
      const PeriodAttendance(
        periodNumber: 'Period 1',
        subjectName: 'Design & Analysis of Algorithms',
        subjectCode: 'CS601',
        startTime: '09:00 AM',
        endTime: '10:00 AM',
        room: 'Lab Complex 304',
        facultyName: 'Dr. Rajeshwari Raman',
        status: PeriodStatus.present,
        timeMarked: '09:04 AM via SmartBoard QR',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 2',
        subjectName: 'Cloud Computing & Distributed Systems',
        subjectCode: 'CS602',
        startTime: '10:05 AM',
        endTime: '11:05 AM',
        room: 'Seminar Hall B',
        facultyName: 'Prof. Vikram Sen',
        status: PeriodStatus.present,
        timeMarked: '10:07 AM via Bluetooth BLE',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 3',
        subjectName: 'Compiler Design',
        subjectCode: 'CS603',
        startTime: '11:20 AM',
        endTime: '12:20 PM',
        room: 'Tech Block 201',
        facultyName: 'Dr. Sunita Rao',
        status: PeriodStatus.present,
        timeMarked: '11:23 AM via SmartBoard QR',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 4',
        subjectName: 'Machine Learning Lab',
        subjectCode: 'CS604P',
        startTime: '01:30 PM',
        endTime: '03:30 PM',
        room: 'AI Computing Lab 1',
        facultyName: 'Prof. Arvind Menon',
        status: PeriodStatus.upcoming,
      ),
      const PeriodAttendance(
        periodNumber: 'Period 5',
        subjectName: 'Professional Ethics & Cyber Law',
        subjectCode: 'HS601',
        startTime: '03:45 PM',
        endTime: '04:45 PM',
        room: 'Lecture Hall 102',
        facultyName: 'Dr. Meera Nambiar',
        status: PeriodStatus.upcoming,
      ),
    ];

    // Child 2 Classes Today
    _childTodayClasses['child_2'] = [
      const PeriodAttendance(
        periodNumber: 'Period 1',
        subjectName: 'Engineering Mathematics II',
        subjectCode: 'MA201',
        startTime: '09:00 AM',
        endTime: '10:00 AM',
        room: 'Sciences Block 101',
        facultyName: 'Dr. K. Srinivas',
        status: PeriodStatus.present,
        timeMarked: '09:02 AM',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 2',
        subjectName: 'Basic Electrical Engineering',
        subjectCode: 'EE201',
        startTime: '10:05 AM',
        endTime: '11:05 AM',
        room: 'Electrical Block 202',
        facultyName: 'Prof. Ananth Kumar',
        status: PeriodStatus.absent,
        timeMarked: 'Unexcused Absence recorded',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 3',
        subjectName: 'Engineering Physics',
        subjectCode: 'PH201',
        startTime: '11:20 AM',
        endTime: '12:20 PM',
        room: 'Science Lab 3',
        facultyName: 'Dr. Nandini Sharma',
        status: PeriodStatus.present,
        timeMarked: '11:21 AM',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 4',
        subjectName: 'Digital Logic Design',
        subjectCode: 'EC202',
        startTime: '01:30 PM',
        endTime: '02:30 PM',
        room: 'VLSI Studio',
        facultyName: 'Prof. Harish B.',
        status: PeriodStatus.upcoming,
      ),
    ];

    // 3. Child 1 Subjects
    _childSubjects['child_1'] = [
      const SubjectAttendance(
        subjectName: 'Design & Analysis of Algorithms',
        code: 'CS601',
        facultyName: 'Dr. Rajeshwari Raman',
        attendedClasses: 38,
        totalClasses: 42,
      ),
      const SubjectAttendance(
        subjectName: 'Cloud Computing & Distributed Systems',
        code: 'CS602',
        facultyName: 'Prof. Vikram Sen',
        attendedClasses: 34,
        totalClasses: 40,
      ),
      const SubjectAttendance(
        subjectName: 'Compiler Design',
        code: 'CS603',
        facultyName: 'Dr. Sunita Rao',
        attendedClasses: 36,
        totalClasses: 44,
      ),
      const SubjectAttendance(
        subjectName: 'Machine Learning Lab',
        code: 'CS604P',
        facultyName: 'Prof. Arvind Menon',
        attendedClasses: 22,
        totalClasses: 24,
      ),
      const SubjectAttendance(
        subjectName: 'Professional Ethics & Cyber Law',
        code: 'HS601',
        facultyName: 'Dr. Meera Nambiar',
        attendedClasses: 28,
        totalClasses: 32,
      ),
    ];

    // Child 2 Subjects
    _childSubjects['child_2'] = [
      const SubjectAttendance(
        subjectName: 'Engineering Mathematics II',
        code: 'MA201',
        facultyName: 'Dr. K. Srinivas',
        attendedClasses: 26,
        totalClasses: 36,
      ),
      const SubjectAttendance(
        subjectName: 'Basic Electrical Engineering',
        code: 'EE201',
        facultyName: 'Prof. Ananth Kumar',
        attendedClasses: 21,
        totalClasses: 35,
      ),
      const SubjectAttendance(
        subjectName: 'Engineering Physics',
        code: 'PH201',
        facultyName: 'Dr. Nandini Sharma',
        attendedClasses: 30,
        totalClasses: 38,
      ),
      const SubjectAttendance(
        subjectName: 'Digital Logic Design',
        code: 'EC202',
        facultyName: 'Prof. Harish B.',
        attendedClasses: 24,
        totalClasses: 32,
      ),
    ];

    // 4. Leave applications
    _leaveRequests.addAll([
      LeaveRequest(
        id: 'leave_101',
        childId: 'child_1',
        leaveType: 'Medical Leave (Viral Fever)',
        startDate: DateTime.now().subtract(const Duration(days: 8)),
        endDate: DateTime.now().subtract(const Duration(days: 6)),
        reason: 'Severe fever and cough. Medical certificate submitted to HOD.',
        status: LeaveStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 9)),
        approvedBy: 'Dr. Rajeshwari Raman (Class Advisor)',
        reviewRemarks: 'Approved upon doctor certificate verification. Attendance excused.',
      ),
      LeaveRequest(
        id: 'leave_102',
        childId: 'child_1',
        leaveType: 'Academic Workshop / Hackathon',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().subtract(const Duration(days: 2)),
        reason: 'Representing university in inter-collegiate AI Hackathon.',
        status: LeaveStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 3)),
        approvedBy: 'HOD Computer Science',
        reviewRemarks: 'On-Duty attendance credit granted.',
      ),
      LeaveRequest(
        id: 'leave_201',
        childId: 'child_2',
        leaveType: 'Family Function Leave',
        startDate: DateTime.now().add(const Duration(days: 4)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        reason: 'Attending elder sister wedding ceremony out of town.',
        status: LeaveStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 4)),
        reviewRemarks: 'Forwarded to HOD for final sign-off.',
      ),
    ]);

    // 5. Notices
    _notices.addAll([
      CampusNotice(
        id: 'notice_1',
        title: 'Mid-Semester Examination Schedule Announced',
        summary: 'Theory exams start Nov 14. Minimum 75% attendance mandatory for hall ticket generation.',
        fullContent: 'The controller of examinations has officially released the timetable for the Mid-Semester Examinations. Students with attendance under 75% in any course will be categorized as defaulters and must obtain prior departmental condonation.',
        publishedDate: DateTime.now().subtract(const Duration(hours: 5)),
        category: NoticeCategory.exam,
        isUrgent: true,
        publishedBy: 'Office of Controller of Examinations',
      ),
      CampusNotice(
        id: 'notice_2',
        title: 'Parent-Teacher Meeting (PTM) for 6th Sem B.Tech',
        summary: 'Scheduled for Saturday, Nov 08 at 10:00 AM via Hybrid Mode (Campus Aud. & Google Meet).',
        fullContent: 'We invite all parents to attend the Mid-Semester PTM to review your ward academic progression, attendance trends, and upcoming placement readiness programs. Hybrid meeting links will be shared 2 days prior.',
        publishedDate: DateTime.now().subtract(const Duration(days: 1)),
        category: NoticeCategory.event,
        publishedBy: 'Dean of Student Affairs',
      ),
      CampusNotice(
        id: 'notice_3',
        title: 'Upcoming National Festival Holiday Declaration',
        summary: 'College and campus offices will remain closed on Friday, Nov 01.',
        fullContent: 'The institution will remain closed for all academic and laboratory sessions on Friday, Nov 01. Regular classes will resume on Monday, Nov 04.',
        publishedDate: DateTime.now().subtract(const Duration(days: 3)),
        category: NoticeCategory.holiday,
        publishedBy: 'Registrar Office',
      ),
    ]);

    // 6. Faculty Mentors
    _mentors.addAll([
      const FacultyMentor(
        id: 'fac_1',
        name: 'Dr. Rajeshwari Raman',
        designation: 'Professor & Class Advisor (CSE VI Sem)',
        department: 'Computer Science & Engineering',
        email: 'rajeshwari.r@intelliattend.edu',
        phone: '+91 98450 12345',
        officeRoom: 'Tech Block 3, Room 314',
        availableHours: 'Mon - Fri (03:30 PM - 05:00 PM)',
      ),
      const FacultyMentor(
        id: 'fac_2',
        name: 'Prof. Ananth Kumar',
        designation: 'Associate Professor & First-Year Mentor',
        department: 'Electronics & Communication',
        email: 'ananth.k@intelliattend.edu',
        phone: '+91 98450 67890',
        officeRoom: 'Admin Annex, Cabin 108',
        availableHours: 'Tue & Thu (02:00 PM - 04:00 PM)',
      ),
      const FacultyMentor(
        id: 'fac_3',
        name: 'Dr. K. Srinivas',
        designation: 'Head of Department (Mathematics)',
        department: 'Applied Sciences',
        email: 'srinivas.k@intelliattend.edu',
        phone: '+91 98450 99887',
        officeRoom: 'Sciences Block, Room 201',
        availableHours: 'Wed (11:00 AM - 01:00 PM)',
      ),
    ]);

    // 7. Student Bus Transit Profiles
    final isMorning = DateTime.now().hour < 12;
    _childTransits['child_1'] = StudentBusTransit(
      childId: 'child_1',
      isOnBus: true, // Active live tracking so the user sees it immediately on launch!
      busNumber: 'Bus #14',
      vehiclePlate: 'KA-04-E-2048',
      routeName: isMorning ? 'Route 14B • Morning School Express' : 'Route 14B • Evening Home Express',
      driverName: 'Ramesh Sharma',
      driverPhone: '+91 98450 77665',
      driverRating: '4.9',
      driverExperience: '8 Yrs Exp',
      rfidCardNumber: 'RFID-88391-A',
      boardedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      pickupLocation: isMorning ? 'Green Valley Sector 4 Stop' : 'Campus Main North Tech Gate',
      destinationCampus: isMorning ? 'Campus Main North Tech Gate' : 'Green Valley Residence (Home)',
      destinationType: isMorning ? TransitDestinationType.school : TransitDestinationType.home,
      estimatedMinutes: 14,
      remainingKm: 4.8,
      currentSpeed: 38.0,
      progressFraction: 0.15,
      stage: TransitStage.inTransit,
      stops: const [
        StudentTransitStop(
          stopId: 'stop_1',
          name: 'Green Valley Sec 4 (Pickup)',
          scheduledTime: '08:12 AM',
          isCompleted: true,
          progressFraction: 0.05,
        ),
        StudentTransitStop(
          stopId: 'stop_2',
          name: 'HSR 5th Main Junction',
          scheduledTime: '08:18 AM',
          isCompleted: false,
          isNext: true,
          progressFraction: 0.28,
        ),
        StudentTransitStop(
          stopId: 'stop_3',
          name: 'Silk Board Tech Flyover',
          scheduledTime: '08:25 AM',
          isCompleted: false,
          progressFraction: 0.52,
        ),
        StudentTransitStop(
          stopId: 'stop_4',
          name: 'Electronic City Tollway',
          scheduledTime: '08:32 AM',
          isCompleted: false,
          progressFraction: 0.75,
        ),
        StudentTransitStop(
          stopId: 'stop_5',
          name: 'Campus Main North Gate',
          scheduledTime: '08:40 AM',
          isCompleted: false,
          progressFraction: 0.98,
        ),
      ],
    );

    _childTransits['child_2'] = StudentBusTransit(
      childId: 'child_2',
      isOnBus: false, // In normal time, stays as Enrolled Student Card!
      busNumber: 'Bus #08',
      vehiclePlate: 'KA-04-F-1102',
      routeName: 'Route 08A • North Campus Shuttler',
      driverName: 'Manjunath Gowda',
      driverPhone: '+91 98450 33211',
      driverRating: '4.8',
      driverExperience: '6 Yrs Exp',
      rfidCardNumber: 'RFID-99412-B',
      boardedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      pickupLocation: 'Koramangala 4th Block Stop',
      destinationCampus: 'Campus Science Block Gate',
      estimatedMinutes: 18,
      remainingKm: 6.2,
      currentSpeed: 34.0,
      progressFraction: 0.12,
      stage: TransitStage.inTransit,
      stops: const [
        StudentTransitStop(
          stopId: 'stop_c2_1',
          name: 'Koramangala 4th Block (Pickup)',
          scheduledTime: '08:10 AM',
          isCompleted: true,
          progressFraction: 0.05,
        ),
        StudentTransitStop(
          stopId: 'stop_c2_2',
          name: 'Sony World Junction',
          scheduledTime: '08:16 AM',
          isCompleted: false,
          isNext: true,
          progressFraction: 0.35,
        ),
        StudentTransitStop(
          stopId: 'stop_c2_3',
          name: 'Indiranagar 100ft Rd',
          scheduledTime: '08:25 AM',
          isCompleted: false,
          progressFraction: 0.65,
        ),
        StudentTransitStop(
          stopId: 'stop_c2_4',
          name: 'Campus Science Block Gate',
          scheduledTime: '08:35 AM',
          isCompleted: false,
          progressFraction: 0.98,
        ),
      ],
    );

    _startTransitTimer();
  }
}
