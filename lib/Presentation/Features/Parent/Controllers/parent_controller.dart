import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Core/Network/api_client.dart';
import '../../../../Services/notification_service.dart';
import '../Models/parent_models.dart';

class ParentController extends ChangeNotifier {
  ParentController() {
    _initMockData();
    _bootstrapLocalStorageAndSync();
    if (_childTransits.values.any((t) => t.isOnBus)) {
      _startTransitTimer();
    }
  }

  Future<void> _bootstrapLocalStorageAndSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _purgeLegacyDummyPrefsIfNeeded(prefs);
      await _loadSavedParentName(prefs);
      await _loadSavedChildAvatars(prefs);
      await _loadSavedHealthRecords(prefs);
      await fetchProfileFromServer();
    } catch (e) {
      debugPrint('[ParentSync] Bootstrap error: $e');
    }
  }

  Future<void> _purgeLegacyDummyPrefsIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool('profile_dummy_purged_v1') == true) return;

    // Clear pre-update hardcoded mock defaults so Profile starts empty until
    // server provides data or the guardian saves their real details.
    if (prefs.getString('parent_full_name') == 'Mr. & Mrs. Sharma') {
      await prefs.remove('parent_full_name');
    }
    if (prefs.getBool('guardian_sync_pending') != true) {
      for (final key in const [
        'parent_phone',
        'parent_email',
        'parent_city',
        'guardian_relationship',
        'emergency_contact_phone',
      ]) {
        await prefs.remove(key);
      }
    }
    for (final child in _children) {
      if (prefs.getBool('health_sync_pending_${child.id}') != true) {
        for (final prefix in const [
          'health_blood_',
          'health_allergies_',
          'health_conditions_',
          'health_meds_',
          'health_directives_',
          'health_ins_provider_',
          'health_ins_policy_',
          'health_opd_',
          'health_doc_name_',
          'health_doc_phone_',
          'health_hospital_',
          'health_donor_',
          'health_diet_',
          'health_height_',
          'health_weight_',
          'health_sensory_',
        ]) {
          await prefs.remove('$prefix${child.id}');
        }
      }
    }
    await prefs.setBool('profile_dummy_purged_v1', true);
  }

  Future<void> updateChildAvatar(String childId, String newAvatarUrl) async {
    final idx = _children.indexWhere((c) => c.id == childId);
    if (idx != -1) {
      _children[idx] = _children[idx].copyWith(avatarUrl: newAvatarUrl);
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('child_avatar_$childId', newAvatarUrl);
      } catch (e) {
        debugPrint('Error saving child avatar to SharedPreferences: $e');
      }
      try {
        await ApiClient().dio.put(
          '/api/v1/parent/students/$childId/avatar',
          data: {'avatar_url': newAvatarUrl},
        );
      } catch (e) {
        debugPrint('[ParentSync] Child avatar sync skipped/offline: $e');
      }
    }
  }

  Future<void> _loadSavedChildAvatars([SharedPreferences? existingPrefs]) async {
    try {
      final prefs = existingPrefs ?? await SharedPreferences.getInstance();
      for (int i = 0; i < _children.length; i++) {
        final saved = prefs.getString('child_avatar_${_children[i].id}');
        if (saved != null && saved.isNotEmpty) {
          _children[i] = _children[i].copyWith(avatarUrl: saved);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  String _parentName = '';
  String get parentName => _parentName;

  void setParentName(String name, {bool save = true}) {
    final clean = name.trim();
    _parentName = clean;

    if (clean.isNotEmpty) {
      final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        final surname = parts.last;
        for (int i = 0; i < _children.length; i++) {
          final current = _children[i];
          final childFirst = i == 0 ? 'Aarav' : 'Ananya';
          _children[i] = current.copyWith(name: '$childFirst $surname');
        }
      }
    }

    if (save) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('parent_full_name', clean);
      });
    }
    notifyListeners();
  }

  Future<void> _loadSavedParentName([SharedPreferences? existingPrefs]) async {
    try {
      final prefs = existingPrefs ?? await SharedPreferences.getInstance();
      final saved = prefs.getString('parent_full_name');
      if (saved != null && saved.trim().isNotEmpty) {
        setParentName(saved, save: false);
      }
      _parentPhone = prefs.getString('parent_phone') ?? '';
      _parentEmail = prefs.getString('parent_email') ?? '';
      _parentCity = prefs.getString('parent_city') ?? '';
      _guardianRelationship = prefs.getString('guardian_relationship') ?? '';
      _emergencyContactPhone = prefs.getString('emergency_contact_phone') ?? '';
      _guardianSyncPending = prefs.getBool('guardian_sync_pending') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  String _parentPhone = '';
  String get parentPhone => _parentPhone;

  String _parentEmail = '';
  String get parentEmail => _parentEmail;

  String _parentCity = '';
  String get parentCity => _parentCity;

  String _guardianRelationship = '';
  String get guardianRelationship => _guardianRelationship;

  String _emergencyContactPhone = '';
  String get emergencyContactPhone => _emergencyContactPhone;

  bool _guardianSyncPending = false;
  bool get hasPendingProfileSync =>
      _guardianSyncPending || _pendingHealthSyncIds.isNotEmpty;
  final Set<String> _pendingHealthSyncIds = {};

  /// Pulls official Guardian & Medical Records from the school server.
  /// Defaults remain empty until provided by the server or edited in-app.
  Future<void> fetchProfileFromServer() async {
    try {
      final dio = ApiClient().dio;

      // 1. Sync any locally queued offline changes first
      await syncPendingProfileChanges();

      // 2. Fetch guardian info from server
      try {
        final res = await dio.get('/api/v1/parent/guardian');
        if (res.statusCode == 200 && res.data is Map) {
          final raw = res.data['data'] is Map ? res.data['data'] : res.data;
          final data = Map<String, dynamic>.from(raw as Map);
          await _applyGuardianServerData(data);
        }
      } catch (e) {
        debugPrint('[ParentSync] Guardian fetch skipped/offline: $e');
      }

      // 3. Fetch medical / health records per child from server
      for (final child in _children) {
        try {
          final res = await dio.get('/api/v1/parent/students/${child.id}/health-record');
          if (res.statusCode == 200 && res.data is Map) {
            final raw = res.data['data'] is Map ? res.data['data'] : res.data;
            final record = StudentHealthRecord.fromJson(
              child.id,
              Map<String, dynamic>.from(raw as Map),
            );
            _healthRecords[child.id] = record;
            await _persistHealthRecordLocally(child.id, record);
            if (record.bloodGroup.isNotEmpty) {
              final idx = _children.indexWhere((c) => c.id == child.id);
              if (idx != -1) {
                _children[idx] = _children[idx].copyWith(bloodGroup: record.bloodGroup);
              }
            }
          }
        } catch (e) {
          debugPrint('[ParentSync] Health fetch skipped for ${child.id}: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ParentSync] fetchProfileFromServer error: $e');
    }
  }

  Future<void> _applyGuardianServerData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final name = (data['name'] ?? data['full_name'] ?? '').toString().trim();
    final phone = (data['phone'] ?? data['mobile'] ?? '').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final city = (data['city'] ?? data['address'] ?? '').toString().trim();
    final rel = (data['relationship'] ?? '').toString().trim();
    final emerg = (data['emergency_phone'] ?? data['emergencyPhone'] ?? '').toString().trim();

    if (name.isNotEmpty) setParentName(name, save: true);
    _parentPhone = phone;
    _parentEmail = email;
    _parentCity = city;
    _guardianRelationship = rel;
    _emergencyContactPhone = emerg;

    await prefs.setString('parent_phone', _parentPhone);
    await prefs.setString('parent_email', _parentEmail);
    await prefs.setString('parent_city', _parentCity);
    await prefs.setString('guardian_relationship', _guardianRelationship);
    await prefs.setString('emergency_contact_phone', _emergencyContactPhone);
    await prefs.setBool('guardian_sync_pending', false);
    _guardianSyncPending = false;
  }

  Future<bool> _pushGuardianToServer() async {
    try {
      final res = await ApiClient().dio.put(
        '/api/v1/parent/guardian',
        data: {
          'name': _parentName,
          'phone': _parentPhone,
          'email': _parentEmail,
          'city': _parentCity,
          'relationship': _guardianRelationship,
          'emergency_phone': _emergencyContactPhone,
        },
      );
      return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
    } catch (e) {
      debugPrint('[ParentSync] Guardian sync to server deferred: $e');
      return false;
    }
  }

  Future<bool> _pushHealthToServer(String childId, StudentHealthRecord record) async {
    try {
      final res = await ApiClient().dio.put(
        '/api/v1/parent/students/$childId/health-record',
        data: record.toJson(),
      );
      return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
    } catch (e) {
      debugPrint('[ParentSync] Health sync to server deferred for $childId: $e');
      return false;
    }
  }

  /// Retries syncing any pending local edits to the server.
  Future<void> syncPendingProfileChanges() async {
    final prefs = await SharedPreferences.getInstance();
    if (_guardianSyncPending) {
      final ok = await _pushGuardianToServer();
      if (ok) {
        _guardianSyncPending = false;
        await prefs.setBool('guardian_sync_pending', false);
      }
    }
    for (final childId in _pendingHealthSyncIds.toList()) {
      final record = _healthRecords[childId];
      if (record != null) {
        final ok = await _pushHealthToServer(childId, record);
        if (ok) {
          _pendingHealthSyncIds.remove(childId);
          await prefs.setBool('health_sync_pending_$childId', false);
        }
      }
    }
  }

  /// Saves guardian edits locally and immediately syncs to server.
  /// Returns true if server sync succeeded, false if queued offline.
  Future<bool> updateGuardianInfo({
    required String name,
    required String phone,
    required String email,
    required String city,
    required String relationship,
    required String emergencyPhone,
  }) async {
    setParentName(name, save: true);
    _parentPhone = phone.trim();
    _parentEmail = email.trim();
    _parentCity = city.trim();
    _guardianRelationship = relationship.trim();
    _emergencyContactPhone = emergencyPhone.trim();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_phone', _parentPhone);
      await prefs.setString('parent_email', _parentEmail);
      await prefs.setString('parent_city', _parentCity);
      await prefs.setString('guardian_relationship', _guardianRelationship);
      await prefs.setString('emergency_contact_phone', _emergencyContactPhone);

      final synced = await _pushGuardianToServer();
      _guardianSyncPending = !synced;
      await prefs.setBool('guardian_sync_pending', _guardianSyncPending);
      notifyListeners();
      return synced;
    } catch (e) {
      debugPrint('Error saving guardian info: $e');
      return false;
    }
  }

  // Student Health & Emergency Vault Records (empty by default until server/user populates)
  final Map<String, StudentHealthRecord> _healthRecords = {};

  StudentHealthRecord healthRecordForChild(String childId) {
    if (!_healthRecords.containsKey(childId)) {
      _healthRecords[childId] = StudentHealthRecord(childId: childId);
    }
    return _healthRecords[childId]!;
  }

  StudentHealthRecord get activeChildHealthRecord => healthRecordForChild(_activeChildId);

  Future<void> _persistHealthRecordLocally(
      String childId, StudentHealthRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('health_blood_$childId', record.bloodGroup);
    await prefs.setString('health_allergies_$childId', record.allergies);
    await prefs.setString('health_conditions_$childId', record.chronicConditions);
    await prefs.setString('health_meds_$childId', record.dailyMedications);
    await prefs.setString('health_directives_$childId', record.criticalDirectives);
    await prefs.setString('health_ins_provider_$childId', record.insuranceProvider);
    await prefs.setString('health_ins_policy_$childId', record.insurancePolicyNumber);
    await prefs.setString('health_opd_$childId', record.campusClinicOpdId);
    await prefs.setString('health_doc_name_$childId', record.primaryDoctorName);
    await prefs.setString('health_doc_phone_$childId', record.primaryDoctorPhone);
    await prefs.setString('health_hospital_$childId', record.preferredHospital);
    await prefs.setBool('health_donor_$childId', record.isOrganDonor);
    await prefs.setString('health_diet_$childId', record.dietaryNeeds);
    await prefs.setString('health_height_$childId', record.heightCm);
    await prefs.setString('health_weight_$childId', record.weightKg);
    await prefs.setString('health_sensory_$childId', record.sensoryAids);
  }

  /// Saves health record locally and immediately syncs to server.
  /// Returns true if server sync succeeded, false if queued offline.
  Future<bool> updateChildHealthRecord(
      String childId, StudentHealthRecord record) async {
    _healthRecords[childId] = record;

    final idx = _children.indexWhere((c) => c.id == childId);
    if (idx != -1 && record.bloodGroup.isNotEmpty) {
      _children[idx] = _children[idx].copyWith(bloodGroup: record.bloodGroup);
    }
    notifyListeners();

    try {
      await _persistHealthRecordLocally(childId, record);
      final prefs = await SharedPreferences.getInstance();
      final synced = await _pushHealthToServer(childId, record);
      if (synced) {
        _pendingHealthSyncIds.remove(childId);
      } else {
        _pendingHealthSyncIds.add(childId);
      }
      await prefs.setBool('health_sync_pending_$childId', !synced);
      notifyListeners();
      return synced;
    } catch (e) {
      debugPrint('Error saving health record: $e');
      return false;
    }
  }

  Future<void> _loadSavedHealthRecords([SharedPreferences? existingPrefs]) async {
    try {
      final prefs = existingPrefs ?? await SharedPreferences.getInstance();
      for (final child in _children) {
        final blood = prefs.getString('health_blood_${child.id}') ?? '';
        final allergies = prefs.getString('health_allergies_${child.id}') ?? '';
        final conditions = prefs.getString('health_conditions_${child.id}') ?? '';
        final meds = prefs.getString('health_meds_${child.id}') ?? '';
        final directives = prefs.getString('health_directives_${child.id}') ?? '';
        final insProvider = prefs.getString('health_ins_provider_${child.id}') ?? '';
        final insPolicy = prefs.getString('health_ins_policy_${child.id}') ?? '';
        final opd = prefs.getString('health_opd_${child.id}') ?? '';
        final docName = prefs.getString('health_doc_name_${child.id}') ?? '';
        final docPhone = prefs.getString('health_doc_phone_${child.id}') ?? '';
        final hospital = prefs.getString('health_hospital_${child.id}') ?? '';
        final isDonor = prefs.getBool('health_donor_${child.id}') ?? false;
        final diet = prefs.getString('health_diet_${child.id}') ?? '';
        final height = prefs.getString('health_height_${child.id}') ?? '';
        final weight = prefs.getString('health_weight_${child.id}') ?? '';
        final sensory = prefs.getString('health_sensory_${child.id}') ?? '';

        if (prefs.getBool('health_sync_pending_${child.id}') == true) {
          _pendingHealthSyncIds.add(child.id);
        }

        _healthRecords[child.id] = StudentHealthRecord(
          childId: child.id,
          bloodGroup: blood,
          allergies: allergies,
          chronicConditions: conditions,
          dailyMedications: meds,
          criticalDirectives: directives,
          insuranceProvider: insProvider,
          insurancePolicyNumber: insPolicy,
          campusClinicOpdId: opd,
          primaryDoctorName: docName,
          primaryDoctorPhone: docPhone,
          preferredHospital: hospital,
          isOrganDonor: isDonor,
          dietaryNeeds: diet,
          heightCm: height,
          weightKg: weight,
          sensoryAids: sensory,
        );
      }
      notifyListeners();
    } catch (_) {}
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

  // Notifications from Faculty & Authorities
  final List<ParentNotificationMessage> _notifications = [];
  List<ParentNotificationMessage> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead && !n.isArchived).length;
  int get archivedNotificationsCount => _notifications.where((n) => n.isArchived).length;

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    bool changed = false;
    for (var n in _notifications) {
      if (!n.isRead && !n.isArchived) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void toggleNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = !_notifications[idx].isRead;
      notifyListeners();
    }
  }

  void toggleNotificationStar(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isStarred = !_notifications[idx].isStarred;
      notifyListeners();
    }
  }

  void archiveNotification(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isArchived = true;
      notifyListeners();
    }
  }

  void unarchiveNotification(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isArchived = false;
      notifyListeners();
    }
  }

  void clearReadNotifications() {
    _notifications.removeWhere((n) => n.isRead && !n.isArchived);
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void addNotification(ParentNotificationMessage message) {
    _notifications.insert(0, message);
    notifyListeners();
  }

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
    addNotification(
      ParentNotificationMessage(
        id: 'rfid_board_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Bus Boarded: RFID Scan Confirmed',
        message: '${child.name} tapped their student RFID card and boarded ${existing.busNumber}. Real-time bus GPS tracking is currently active.',
        senderName: 'Campus Transport Authority',
        senderRole: 'RFID Gate & Fleet Logistics',
        senderDepartment: 'Security & Fleet Operations',
        senderType: NotificationSenderType.authority,
        childId: childId,
        childName: child.name,
        timestamp: DateTime.now(),
        priority: NotificationPriority.info,
        isRead: false,
      ),
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
    addNotification(
      ParentNotificationMessage(
        id: 'rfid_deboard_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Safe Arrival: Deboarded at $placeName',
        message: '${child.name} tapped RFID and safely deboarded ${existing.busNumber} at $placeName. Transit logged successfully.',
        senderName: 'Campus Transport Authority',
        senderRole: 'RFID Gate & Fleet Logistics',
        senderDepartment: 'Security & Fleet Operations',
        senderType: NotificationSenderType.authority,
        childId: childId,
        childName: child.name,
        timestamp: DateTime.now(),
        priority: NotificationPriority.info,
        isRead: false,
      ),
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
    await fetchProfileFromServer();
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
    // 1. Linked Children (School Configuration)
    _children.addAll([
      const ChildProfile(
        id: 'child_1',
        name: 'Aarav Boora',
        rollNumber: '14',
        program: 'Class 10',
        semester: 'Section A',
        avatarUrl: 'preset:aarav',
        bloodGroup: 'O+ve',
        mentorName: 'Mrs. Sunita Sharma (Class Teacher)',
        mentorPhone: '+91 98450 12345',
        overallAttendance: 94.6,
        academicYear: '2026 - 2027',
      ),
      const ChildProfile(
        id: 'child_2',
        name: 'Ananya Boora',
        rollNumber: '22',
        program: 'Class 7',
        semester: 'Section B',
        avatarUrl: 'preset:ananya',
        bloodGroup: 'B+ve',
        mentorName: 'Mrs. Kavita Reddy (Class Teacher)',
        mentorPhone: '+91 98450 67890',
        overallAttendance: 91.2,
        academicYear: '2026 - 2027',
      ),
    ]);

    // 2. Child 1 Classes Today (Class 10 School Routine)
    _childTodayClasses['child_1'] = [
      const PeriodAttendance(
        periodNumber: 'Period 1',
        subjectName: 'Mathematics',
        subjectCode: 'MTH-10',
        startTime: '09:00 AM',
        endTime: '09:45 AM',
        room: 'Class 10-A',
        facultyName: 'Mrs. Sunita Sharma',
        status: PeriodStatus.present,
        timeMarked: '09:02 AM via RFID Gate',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 2',
        subjectName: 'English Language & Literature',
        subjectCode: 'ENG-10',
        startTime: '09:50 AM',
        endTime: '10:35 AM',
        room: 'Class 10-A',
        facultyName: 'Mrs. Ananya Gupta',
        status: PeriodStatus.present,
        timeMarked: '09:52 AM via Smart Register',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 3',
        subjectName: 'Science (Physics & Chemistry)',
        subjectCode: 'SCI-10',
        startTime: '10:50 AM',
        endTime: '11:35 AM',
        room: 'Science Lab 2',
        facultyName: 'Mr. R. K. Verma',
        status: PeriodStatus.present,
        timeMarked: '10:53 AM via Bluetooth BLE',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 4',
        subjectName: 'Social Science (History & Civics)',
        subjectCode: 'SST-10',
        startTime: '11:40 AM',
        endTime: '12:25 PM',
        room: 'Class 10-A',
        facultyName: 'Mrs. Kavita Reddy',
        status: PeriodStatus.upcoming,
      ),
      const PeriodAttendance(
        periodNumber: 'Period 5',
        subjectName: 'Hindi / Regional Language',
        subjectCode: 'HIN-10',
        startTime: '01:10 PM',
        endTime: '01:50 PM',
        room: 'Class 10-A',
        facultyName: 'Mr. Arvind Joshi',
        status: PeriodStatus.upcoming,
      ),
      const PeriodAttendance(
        periodNumber: 'Period 6',
        subjectName: 'Computer Science & AI Coding',
        subjectCode: 'CS-10',
        startTime: '01:55 PM',
        endTime: '02:40 PM',
        room: 'Computer Lab 1',
        facultyName: 'Ms. Priya Nair',
        status: PeriodStatus.upcoming,
      ),
      const PeriodAttendance(
        periodNumber: 'Period 7',
        subjectName: 'Physical Education & Games',
        subjectCode: 'PET-10',
        startTime: '02:45 PM',
        endTime: '03:30 PM',
        room: 'School Playground',
        facultyName: 'Coach Vikram Singh',
        status: PeriodStatus.upcoming,
      ),
    ];

    // Child 2 Classes Today (Class 7 School Routine)
    _childTodayClasses['child_2'] = [
      const PeriodAttendance(
        periodNumber: 'Period 1',
        subjectName: 'General Science',
        subjectCode: 'SCI-07',
        startTime: '09:00 AM',
        endTime: '09:45 AM',
        room: 'Class 7-B',
        facultyName: 'Mrs. Kavita Reddy',
        status: PeriodStatus.present,
        timeMarked: '09:02 AM',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 2',
        subjectName: 'Mathematics',
        subjectCode: 'MTH-07',
        startTime: '09:50 AM',
        endTime: '10:35 AM',
        room: 'Class 7-B',
        facultyName: 'Mr. P. N. Rao',
        status: PeriodStatus.absent,
        timeMarked: 'Late Arrival Recorded',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 3',
        subjectName: 'Social Studies',
        subjectCode: 'SST-07',
        startTime: '10:50 AM',
        endTime: '11:35 AM',
        room: 'Class 7-B',
        facultyName: 'Mrs. Sunita Sharma',
        status: PeriodStatus.present,
        timeMarked: '10:52 AM',
      ),
      const PeriodAttendance(
        periodNumber: 'Period 4',
        subjectName: 'English Grammar',
        subjectCode: 'ENG-07',
        startTime: '11:40 AM',
        endTime: '12:25 PM',
        room: 'Class 7-B',
        facultyName: 'Ms. Priya Nair',
        status: PeriodStatus.upcoming,
      ),
      const PeriodAttendance(
        periodNumber: 'Period 5',
        subjectName: 'Art & Craft',
        subjectCode: 'ART-07',
        startTime: '01:10 PM',
        endTime: '01:50 PM',
        room: 'Art Studio',
        facultyName: 'Mrs. Meera Roy',
        status: PeriodStatus.upcoming,
      ),
    ];

    // 3. Child 1 School Subjects
    _childSubjects['child_1'] = [
      const SubjectAttendance(
        subjectName: 'Mathematics',
        code: 'MTH-10',
        facultyName: 'Mrs. Sunita Sharma',
        attendedClasses: 45,
        totalClasses: 48,
      ),
      const SubjectAttendance(
        subjectName: 'Science (Physics, Chem, Bio)',
        code: 'SCI-10',
        facultyName: 'Mr. R. K. Verma',
        attendedClasses: 44,
        totalClasses: 46,
      ),
      const SubjectAttendance(
        subjectName: 'English Language & Literature',
        code: 'ENG-10',
        facultyName: 'Mrs. Ananya Gupta',
        attendedClasses: 42,
        totalClasses: 44,
      ),
      const SubjectAttendance(
        subjectName: 'Social Science (History, Geo, Civics)',
        code: 'SST-10',
        facultyName: 'Mrs. Kavita Reddy',
        attendedClasses: 39,
        totalClasses: 42,
      ),
      const SubjectAttendance(
        subjectName: 'Hindi / Regional Language',
        code: 'HIN-10',
        facultyName: 'Mr. Arvind Joshi',
        attendedClasses: 40,
        totalClasses: 42,
      ),
      const SubjectAttendance(
        subjectName: 'Computer Science & AI Coding',
        code: 'CS-10',
        facultyName: 'Ms. Priya Nair',
        attendedClasses: 30,
        totalClasses: 32,
      ),
    ];

    // Child 2 School Subjects
    _childSubjects['child_2'] = [
      const SubjectAttendance(
        subjectName: 'Mathematics',
        code: 'MTH-07',
        facultyName: 'Mr. P. N. Rao',
        attendedClasses: 40,
        totalClasses: 44,
      ),
      const SubjectAttendance(
        subjectName: 'General Science',
        code: 'SCI-07',
        facultyName: 'Mrs. Kavita Reddy',
        attendedClasses: 42,
        totalClasses: 44,
      ),
      const SubjectAttendance(
        subjectName: 'English Grammar',
        code: 'ENG-07',
        facultyName: 'Ms. Priya Nair',
        attendedClasses: 38,
        totalClasses: 40,
      ),
      const SubjectAttendance(
        subjectName: 'Social Studies',
        code: 'SST-07',
        facultyName: 'Mrs. Sunita Sharma',
        attendedClasses: 36,
        totalClasses: 40,
      ),
      const SubjectAttendance(
        subjectName: 'Hindi Language',
        code: 'HIN-07',
        facultyName: 'Mr. Arvind Joshi',
        attendedClasses: 39,
        totalClasses: 42,
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
        title: 'Half-Yearly Examination Schedule Announced (Class 1 to 10)',
        summary: 'Half-yearly exams commence Dec 08. Minimum 75% attendance mandatory for admit cards.',
        fullContent: 'The Examination Directorate has released the official routine for the Half-Yearly Examinations. Admit cards will be handed over by respective Class Teachers next week. Students must be present in proper school uniform.',
        publishedDate: DateTime.now().subtract(const Duration(hours: 4)),
        category: NoticeCategory.exam,
        isUrgent: true,
        publishedBy: 'Office of the Principal & Exam Cell',
      ),
      CampusNotice(
        id: 'notice_2',
        title: 'Term-1 Parent-Teacher Meeting (PTM)',
        summary: 'Scheduled for Saturday, Nov 29 from 9:00 AM to 1:00 PM in respective classrooms.',
        fullContent: 'All parents are warmly invited to attend the Term-1 PTM to discuss their ward\'s academic progress, class performance, and homework submissions with the Class Teacher and Subject Teachers.',
        publishedDate: DateTime.now().subtract(const Duration(days: 1)),
        category: NoticeCategory.event,
        publishedBy: 'School Administration',
      ),
      CampusNotice(
        id: 'notice_3',
        title: 'Annual Sports Day & Winter Uniform Notification',
        summary: 'Switch to winter uniform from Dec 01. Sports Day house trials start next week.',
        fullContent: 'Starting Monday, Dec 01, all students are required to wear the official navy blue school blazer. Inter-house sports selection trials for track events and football will take place during zero periods.',
        publishedDate: DateTime.now().subtract(const Duration(days: 2)),
        category: NoticeCategory.academic,
        publishedBy: 'Physical Education Department',
      ),
      CampusNotice(
        id: 'notice_4',
        title: 'Upcoming Festival Holiday Declaration',
        summary: 'School and administrative offices will remain closed on Friday.',
        fullContent: 'The school will remain closed for all students and staff this Friday on account of the festive holiday. Regular morning classes will resume on Monday at 8:00 AM sharp.',
        publishedDate: DateTime.now().subtract(const Duration(days: 4)),
        category: NoticeCategory.holiday,
        publishedBy: 'Principal\'s Office',
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
      isOnBus: false, // Inactive by default: Gray & non-clickable until student enters bus and taps RFID
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

    // 8. Notifications from Faculty & Campus Authorities
    _notifications.addAll([
      ParentNotificationMessage(
        id: 'notif_1',
        title: 'DAA Lab Performance & Practical Review',
        message:
            'Aarav has been demonstrating commendable consistency in Design & Analysis of Algorithms lab sessions. His aggregate attendance is strong at 84.6%. Please ensure he prepares for the upcoming complex algorithms evaluation next Tuesday.',
        senderName: 'Dr. Rajeshwari Raman',
        senderRole: 'Class Advisor & Mentor (CSE VI Sem)',
        senderDepartment: 'Computer Science & Engineering',
        senderPhone: '+91 98450 12345',
        senderEmail: 'rajeshwari.r@intelliattend.edu',
        senderType: NotificationSenderType.faculty,
        childId: 'child_1',
        childName: 'Aarav Boora',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        priority: NotificationPriority.info,
        actionLabel: 'Call Mentor',
        actionRoute: 'call_mentor',
        isRead: false,
      ),
      ParentNotificationMessage(
        id: 'notif_2',
        title: 'Attendance Alert: Basic Electrical Engineering',
        message:
            'Dear Parent, Ananya\'s attendance in Basic Electrical Engineering (EE201) is currently at 60.0% (needs 21 consecutive lectures to achieve 75% cutoff). A special remedial clarification tutorial is scheduled this Thursday at 4:00 PM in Admin Block Room 108. Please advise her to attend.',
        senderName: 'Prof. Ananth Kumar',
        senderRole: 'HOD & First-Year Mentor (ECE)',
        senderDepartment: 'Electronics & Communication',
        senderPhone: '+91 98450 67890',
        senderEmail: 'ananth.k@intelliattend.edu',
        senderType: NotificationSenderType.faculty,
        childId: 'child_2',
        childName: 'Ananya Boora',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        priority: NotificationPriority.important,
        actionLabel: 'Call Faculty',
        actionRoute: 'call_mentor',
        isRead: false,
      ),
      ParentNotificationMessage(
        id: 'notif_3',
        title: 'Annual Parent-Teacher Conference (PTM) Invitation',
        message:
            'Dear Parents, the Semester IV & II Parent-Teacher Conference will convene this Saturday, 28th Nov at 10:00 AM. We encourage all parents to interact with department faculty regarding academic progress, semester milestones, and placements.',
        senderName: 'Office of the Principal',
        senderRole: 'Executive Office • College Administration',
        senderDepartment: 'Office of Principal Dr. V. Chandrasekhar',
        senderPhone: '+91 80 2345 6700',
        senderEmail: 'principal@intelliattend.edu',
        senderType: NotificationSenderType.authority,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        priority: NotificationPriority.important,
        actionLabel: 'View Circular',
        actionRoute: 'notices',
        isRead: false,
      ),
      ParentNotificationMessage(
        id: 'notif_4',
        title: 'Semester Examination Hall Ticket Eligibility Criterion',
        message:
            'Official Advisory: Mandatory 75% minimum aggregate attendance is strictly required for generating exam hall tickets. The condonation window for medical certificates closes on 30th Nov. Defaulter lists have been published on the departmental boards.',
        senderName: 'Controller of Examinations',
        senderRole: 'University Examination Branch',
        senderDepartment: 'Office of the COE',
        senderEmail: 'exams@intelliattend.edu',
        senderType: NotificationSenderType.authority,
        timestamp: DateTime.now().subtract(const Duration(hours: 22)),
        priority: NotificationPriority.urgent,
        actionLabel: 'View Attendance',
        actionRoute: 'attendance',
        isRead: true,
      ),
      ParentNotificationMessage(
        id: 'notif_5',
        title: 'Compiler Design Assignment #3 Grade Published',
        message:
            'Aarav\'s parsing algorithms assignment #3 has been evaluated and marked with Grade A (19/20). On-duty attendance for representing the university in the AI Hackathon has also been officially credited.',
        senderName: 'Dr. Sunita Rao',
        senderRole: 'Subject Professor (Compiler Design)',
        senderDepartment: 'Computer Science & Engineering',
        senderPhone: '+91 98450 33441',
        senderEmail: 'sunita.rao@intelliattend.edu',
        senderType: NotificationSenderType.faculty,
        childId: 'child_1',
        childName: 'Aarav Boora',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        priority: NotificationPriority.info,
        actionLabel: 'Call Faculty',
        actionRoute: 'call_mentor',
        isRead: true,
      ),
      ParentNotificationMessage(
        id: 'notif_6',
        title: 'Bus Route #14 Schedule Adjustment Notice',
        message:
            'Due to highway flyover construction along Koramangala Outer Ring Road, Bus #14 (Morning School Express) will depart 10 minutes earlier starting Monday. Real-time RFID card entry and exit notifications remain operational on your mobile app.',
        senderName: 'Transport Department',
        senderRole: 'Campus Fleet & Safety Division',
        senderDepartment: 'Transport Office',
        senderPhone: '+91 80 2345 6788',
        senderType: NotificationSenderType.authority,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        priority: NotificationPriority.info,
        isRead: true,
      ),
      ParentNotificationMessage(
        id: 'notif_7',
        title: 'Medical Leave Sanctioned (Viral Fever)',
        message:
            'Medical leave application (leave_101) for viral fever (14 Nov – 16 Nov) has been validated by the medical officer and officially approved. On-Duty attendance credit for 6 missed classes has been recorded in the central ERP.',
        senderName: 'Dean of Student Affairs',
        senderRole: 'Student Welfare & Leave Sanctioning Authority',
        senderDepartment: 'Academic Affairs Council',
        senderType: NotificationSenderType.authority,
        childId: 'child_1',
        childName: 'Aarav Boora',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        priority: NotificationPriority.info,
        actionLabel: 'View Leave Record',
        actionRoute: 'leaves',
        isRead: true,
      ),
    ]);

    _startTransitTimer();
  }
}
