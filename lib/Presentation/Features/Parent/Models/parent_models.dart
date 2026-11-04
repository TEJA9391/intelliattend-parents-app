import 'package:flutter/material.dart';

/// Represents a linked child profile for a parent.
class ChildProfile {
  final String id;
  final String name;
  final String rollNumber;
  final String program; // e.g. "B.Tech Computer Science & Engineering"
  final String semester; // e.g. "6th Sem - Section A"
  final String avatarUrl;
  final String bloodGroup;
  final String mentorName;
  final String mentorPhone;
  final double overallAttendance; // percentage e.g. 84.5
  final String academicYear;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.program,
    required this.semester,
    required this.avatarUrl,
    required this.bloodGroup,
    required this.mentorName,
    required this.mentorPhone,
    required this.overallAttendance,
    this.academicYear = '2026 - 2027',
  });

  Color get attendanceColor {
    if (overallAttendance >= 75.0) {
      return const Color(0xFF2DD4BF); // Teal Green
    } else if (overallAttendance >= 65.0) {
      return const Color(0xFFFBBF24); // Amber
    } else {
      return const Color(0xFFEF4444); // Red Critical
    }
  }

  String get attendanceStatusLabel {
    if (overallAttendance >= 75.0) {
      return 'Safe (Eligible)';
    } else if (overallAttendance >= 65.0) {
      return 'Warning (Near Cutoff)';
    } else {
      return 'Critical Defaulter';
    }
  }
}

/// Represents attendance for a single period/lecture today.
enum PeriodStatus { present, absent, late, upcoming, cancelled }

class PeriodAttendance {
  final String periodNumber;
  final String subjectName;
  final String subjectCode;
  final String startTime;
  final String endTime;
  final String room;
  final String facultyName;
  final PeriodStatus status;
  final String? timeMarked;

  const PeriodAttendance({
    required this.periodNumber,
    required this.subjectName,
    required this.subjectCode,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.facultyName,
    required this.status,
    this.timeMarked,
  });

  Color get statusColor {
    switch (status) {
      case PeriodStatus.present:
        return const Color(0xFF2DD4BF);
      case PeriodStatus.absent:
        return const Color(0xFFEF4444);
      case PeriodStatus.late:
        return const Color(0xFFFBBF24);
      case PeriodStatus.upcoming:
        return const Color(0xFF94A3B8);
      case PeriodStatus.cancelled:
        return const Color(0xFF64748B);
    }
  }

  String get statusText {
    switch (status) {
      case PeriodStatus.present:
        return 'Present';
      case PeriodStatus.absent:
        return 'Absent';
      case PeriodStatus.late:
        return 'Late Check-in';
      case PeriodStatus.upcoming:
        return 'Upcoming';
      case PeriodStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case PeriodStatus.present:
        return Icons.check_circle_rounded;
      case PeriodStatus.absent:
        return Icons.cancel_rounded;
      case PeriodStatus.late:
        return Icons.access_time_filled_rounded;
      case PeriodStatus.upcoming:
        return Icons.schedule_rounded;
      case PeriodStatus.cancelled:
        return Icons.event_busy_rounded;
    }
  }
}

/// Represents course-level cumulative attendance.
class SubjectAttendance {
  final String subjectName;
  final String code;
  final String facultyName;
  final int attendedClasses;
  final int totalClasses;

  const SubjectAttendance({
    required this.subjectName,
    required this.code,
    required this.facultyName,
    required this.attendedClasses,
    required this.totalClasses,
  });

  double get percentage =>
      totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;

  /// Number of classes needed to reach 75%, or how many can be missed
  int get safeMarginOrNeededClasses {
    if (percentage >= 75.0) {
      final canMiss = ((4 * attendedClasses - 3 * totalClasses) / 3).floor();
      return canMiss < 0 ? 0 : canMiss;
    } else {
      final needed = 3 * totalClasses - 4 * attendedClasses;
      return needed < 0 ? 0 : needed;
    }
  }

  Color get statusColor {
    if (percentage >= 75.0) {
      return const Color(0xFF2DD4BF);
    } else if (percentage >= 65.0) {
      return const Color(0xFFFBBF24);
    } else {
      return const Color(0xFFEF4444);
    }
  }
}

/// Represents a Leave application.
enum LeaveStatus { pending, approved, rejected }

class LeaveRequest {
  final String id;
  final String childId;
  final String leaveType; // e.g. "Medical Leave", "Family Event", "Academic On-Duty"
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final DateTime appliedAt;
  final String? approvedBy;
  final String? reviewRemarks;

  const LeaveRequest({
    required this.id,
    required this.childId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.appliedAt,
    this.approvedBy,
    this.reviewRemarks,
  });

  Color get statusColor {
    switch (status) {
      case LeaveStatus.pending:
        return const Color(0xFFFBBF24);
      case LeaveStatus.approved:
        return const Color(0xFF2DD4BF);
      case LeaveStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  String get statusLabel {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending Approval';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Represents a campus announcement or circular.
enum NoticeCategory { academic, exam, holiday, event, emergency }

class CampusNotice {
  final String id;
  final String title;
  final String summary;
  final String fullContent;
  final DateTime publishedDate;
  final NoticeCategory category;
  final bool isUrgent;
  final String publishedBy;

  const CampusNotice({
    required this.id,
    required this.title,
    required this.summary,
    required this.fullContent,
    required this.publishedDate,
    required this.category,
    this.isUrgent = false,
    required this.publishedBy,
  });

  Color get categoryColor {
    switch (category) {
      case NoticeCategory.academic:
        return const Color(0xFF38BDF8);
      case NoticeCategory.exam:
        return const Color(0xFFF43F5E);
      case NoticeCategory.holiday:
        return const Color(0xFF34D399);
      case NoticeCategory.event:
        return const Color(0xFFF59E0B);
      case NoticeCategory.emergency:
        return const Color(0xFFEF4444);
    }
  }
}

/// Represents a faculty mentor or subject professor.
class FacultyMentor {
  final String id;
  final String name;
  final String designation;
  final String department;
  final String email;
  final String phone;
  final String officeRoom;
  final String availableHours;
  final String? avatarUrl;

  const FacultyMentor({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.email,
    required this.phone,
    required this.officeRoom,
    required this.availableHours,
    this.avatarUrl,
  });
}

/// Represents the destination of the bus transit (Morning to school or evening to home)
enum TransitDestinationType {
  school,
  home,
}

/// Represents the stages of a student's bus transit
enum TransitStage {
  boarded,
  inTransit,
  approachingCampus,
  droppedAtCampus,
  reachedSchool,
  reachedHome,
}

/// Represents an individual stop along the bus route
class StudentTransitStop {
  final String stopId;
  final String name;
  final String scheduledTime;
  final bool isCompleted;
  final bool isNext;
  final double progressFraction;

  const StudentTransitStop({
    required this.stopId,
    required this.name,
    required this.scheduledTime,
    this.isCompleted = false,
    this.isNext = false,
    required this.progressFraction,
  });

  StudentTransitStop copyWith({
    bool? isCompleted,
    bool? isNext,
  }) {
    return StudentTransitStop(
      stopId: stopId,
      name: name,
      scheduledTime: scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isNext: isNext ?? this.isNext,
      progressFraction: progressFraction,
    );
  }
}

/// Represents real-time bus transit tracking when RFID is scanned on the bus
class StudentBusTransit {
  final String childId;
  final bool isOnBus;
  final String busNumber;
  final String vehiclePlate;
  final String routeName;
  final String driverName;
  final String driverPhone;
  final String driverRating;
  final String driverExperience;
  final String rfidCardNumber;
  final DateTime boardedAt;
  final String pickupLocation;
  final String destinationCampus;
  final int estimatedMinutes;
  final double remainingKm;
  final double currentSpeed;
  final double progressFraction; // 0.0 to 1.0 along route polyline
  final List<StudentTransitStop> stops;
  final TransitStage stage;
  final TransitDestinationType destinationType;
  final double currentLat;
  final double currentLng;
  final double destLat;
  final double destLng;
  final DateTime? reachedAt;
  final DateTime? deboardedAt;

  const StudentBusTransit({
    required this.childId,
    this.isOnBus = false,
    required this.busNumber,
    required this.vehiclePlate,
    required this.routeName,
    required this.driverName,
    required this.driverPhone,
    this.driverRating = '4.9',
    this.driverExperience = '8 Yrs Exp',
    required this.rfidCardNumber,
    required this.boardedAt,
    required this.pickupLocation,
    required this.destinationCampus,
    required this.estimatedMinutes,
    required this.remainingKm,
    required this.currentSpeed,
    required this.progressFraction,
    required this.stops,
    required this.stage,
    this.destinationType = TransitDestinationType.school,
    this.currentLat = 12.8912,
    this.currentLng = 77.6495,
    this.destLat = 12.8452,
    this.destLng = 77.6602,
    this.reachedAt,
    this.deboardedAt,
  });

  bool get isReached =>
      progressFraction >= 0.98 ||
      stage == TransitStage.reachedSchool ||
      stage == TransitStage.reachedHome ||
      stage == TransitStage.droppedAtCampus;

  String get destinationTitle =>
      destinationType == TransitDestinationType.school
          ? 'School Campus'
          : 'Home';

  String get reachedCelebrationTitle =>
      destinationType == TransitDestinationType.school
          ? 'REACHED SCHOOL'
          : 'REACHED HOME';

  List<List<double>> get routePoints {
    if (destinationType == TransitDestinationType.school) {
      return const [
        [12.9121, 77.6446],
        [12.9080, 77.6480],
        [12.9176, 77.6238],
        [12.8750, 77.6410],
        [12.8510, 77.6620],
        [12.8452, 77.6602],
      ];
    } else {
      return const [
        [12.8452, 77.6602],
        [12.8510, 77.6620],
        [12.8750, 77.6410],
        [12.9176, 77.6238],
        [12.9080, 77.6480],
        [12.9121, 77.6446],
      ];
    }
  }

  (double, double) get liveBusPosition {
    final points = routePoints;
    if (points.isEmpty) return (currentLat, currentLng);
    if (progressFraction <= 0.0) return (points.first[0], points.first[1]);
    if (progressFraction >= 1.0) return (points.last[0], points.last[1]);

    final totalSegments = points.length - 1;
    final scaled = (progressFraction * totalSegments).clamp(0.0, totalSegments.toDouble());
    final index = scaled.floor().clamp(0, totalSegments - 1);
    final frac = scaled - index;

    final p1 = points[index];
    final p2 = points[index + 1];

    final lat = p1[0] + (p2[0] - p1[0]) * frac;
    final lng = p1[1] + (p2[1] - p1[1]) * frac;
    return (lat, lng);
  }

  StudentBusTransit copyWith({
    bool? isOnBus,
    int? estimatedMinutes,
    double? remainingKm,
    double? currentSpeed,
    double? progressFraction,
    TransitStage? stage,
    TransitDestinationType? destinationType,
    double? currentLat,
    double? currentLng,
    double? destLat,
    double? destLng,
    DateTime? reachedAt,
    DateTime? deboardedAt,
    List<StudentTransitStop>? stops,
    DateTime? boardedAt,
    String? destinationCampus,
    String? routeName,
  }) {
    return StudentBusTransit(
      childId: childId,
      isOnBus: isOnBus ?? this.isOnBus,
      busNumber: busNumber,
      vehiclePlate: vehiclePlate,
      routeName: routeName ?? this.routeName,
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      driverExperience: driverExperience,
      rfidCardNumber: rfidCardNumber,
      boardedAt: boardedAt ?? this.boardedAt,
      pickupLocation: pickupLocation,
      destinationCampus: destinationCampus ?? this.destinationCampus,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      remainingKm: remainingKm ?? this.remainingKm,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      progressFraction: progressFraction ?? this.progressFraction,
      stops: stops ?? this.stops,
      stage: stage ?? this.stage,
      destinationType: destinationType ?? this.destinationType,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      reachedAt: reachedAt ?? this.reachedAt,
      deboardedAt: deboardedAt ?? this.deboardedAt,
    );
  }

  String get stageLabel {
    if (isReached) {
      return destinationType == TransitDestinationType.school
          ? 'Reached School • Bus Stopped'
          : 'Reached Home • Bus Stopped';
    }
    switch (stage) {
      case TransitStage.boarded:
        return 'Student Boarded Bus';
      case TransitStage.inTransit:
        return 'In Transit to $destinationTitle';
      case TransitStage.approachingCampus:
        return 'Approaching $destinationTitle';
      case TransitStage.droppedAtCampus:
      case TransitStage.reachedSchool:
        return 'Reached School • Bus Stopped';
      case TransitStage.reachedHome:
        return 'Reached Home • Bus Stopped';
    }
  }
}

