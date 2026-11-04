import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import 'google_bus_map_widget.dart';
import 'fullscreen_bus_map_view.dart';

/// Zomato-style real-time bus tracking card that replaces the Enrolled Student Card
/// when a student enters the bus and taps their RFID card.
class ZomatoBusTrackingCard extends StatefulWidget {
  final ChildProfile child;
  final StudentBusTransit transit;
  final VoidCallback onDeboardTap;
  final VoidCallback? onExpandMap;

  const ZomatoBusTrackingCard({
    super.key,
    required this.child,
    required this.transit,
    required this.onDeboardTap,
    this.onExpandMap,
  });

  @override
  State<ZomatoBusTrackingCard> createState() => _ZomatoBusTrackingCardState();
}

class _ZomatoBusTrackingCardState extends State<ZomatoBusTrackingCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _heightController;
  late Animation<double> _heightAnimation;

  double _mapHeight = 220.0;
  static const double _kMinMapHeight = 135.0;
  static const double _kNormalMapHeight = 220.0;
  static const double _kMaxMapHeight = 360.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutQuad,
    );

    _heightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _heightAnimation = Tween<double>(begin: _mapHeight, end: _mapHeight)
        .animate(_heightController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _mapHeight = (_mapHeight + details.primaryDelta!).clamp(_kMinMapHeight, _kMaxMapHeight);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    double target;

    if (velocity > 320) {
      target = _kMaxMapHeight; // Dragged down quickly -> expand map
    } else if (velocity < -320) {
      target = _kMinMapHeight; // Dragged up quickly -> sink map
    } else {
      if (_mapHeight < 175) {
        target = _kMinMapHeight;
      } else if (_mapHeight > 290) {
        target = _kMaxMapHeight;
      } else {
        target = _kNormalMapHeight;
      }
    }

    _animateToHeight(target);
  }

  void _animateToHeight(double target) {
    _heightAnimation = Tween<double>(begin: _mapHeight, end: target).animate(
      CurvedAnimation(parent: _heightController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _mapHeight = _heightAnimation.value;
        });
      });
    _heightController.forward(from: 0.0);
    HapticFeedback.selectionClick();
  }

  void _toggleExpansion() {
    if (_mapHeight >= 300) {
      _animateToHeight(_kMinMapHeight);
    } else if (_mapHeight <= 170) {
      _animateToHeight(_kNormalMapHeight);
    } else {
      _animateToHeight(_kMaxMapHeight);
    }
  }

  Future<void> _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Opens the live bus location in Google Maps
  Future<void> _openInGoogleMaps() async {
    HapticFeedback.mediumImpact();
    final lat = widget.transit.currentLat;
    final lng = widget.transit.currentLng;
    final label = Uri.encodeComponent('${widget.child.name} - School Bus ${widget.transit.busNumber}');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showFullscreenMap(BuildContext context) {
    HapticFeedback.selectionClick();
    final controller = context.read<ParentController>();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return ChangeNotifierProvider.value(
            value: controller,
            child: FullscreenOnlyMapView(
              child: widget.child,
              initialTransit: widget.transit,
              onDeboardTap: widget.onDeboardTap,
            ),
          );
        },
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transit = widget.transit;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HEADER: Zomato-style Live Delivery/Transit Pill
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Static fixed-size container: pulse stays inside without shifting adjacent text
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 12 + (_pulseAnimation.value * 10),
                                    height: 12 + (_pulseAnimation.value * 10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 1.0 - _pulseAnimation.value),
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'STUDENT ON BUS • LIVE',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF059669),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    transit.busNumber,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${widget.child.name} • Pass Verified',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          
          // 2. THE ZOMATO-STYLE MAP INTERFACE (DRAGGABLE TO SINK OR EXPAND)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: AnimatedContainer(
                duration: _heightController.isAnimating ? Duration.zero : const Duration(milliseconds: 100),
                height: _mapHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.8),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: Stack(
                    children: [
                      // Real Interactive Google Map (Free API)
                      Positioned.fill(
                        child: GoogleBusMapWidget(
                          transit: transit,
                          isInteractive: true,
                          showControls: false,
                          initialZoom: 14.5,
                          onFullscreenTap: () => _showFullscreenMap(context),
                        ),
                      ),

                    // Floating Overlays on Map
                    // Top Left: Speed & Live Status Pill
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF18181B) : Colors.white)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              transit.isReached ? Icons.check_circle_rounded : Icons.directions_bus_rounded,
                              size: 14,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              transit.isReached ? 'Stopped' : 'In Transit',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top Right: Fullscreen Button (Opens Fullscreen ONLY Map!)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _showFullscreenMap(context),
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF18181B) : Colors.white)
                                .withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.open_in_full_rounded,
                            size: 15,
                            color: AppTheme.text(context),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Left: Route Label & Destination
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF18181B) : Colors.white)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          transit.destinationTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text(context),
                          ),
                        ),
                      ),
                    ),


                    // Center overlay when reached destination
                    if (transit.isReached)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                              ),
                              child: Text(
                                transit.reachedCelebrationTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Zomato Tactile Drag Handle (Centered pill, NO text)
          GestureDetector(
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            onTap: _toggleExpansion,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),

          // 3. ZOMATO-STYLE ETA & TRANSIT PROGRESS SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big bold ETA and remaining distance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            transit.isReached
                                ? (transit.destinationType == TransitDestinationType.school
                                    ? 'Reached School!'
                                    : 'Reached Home!')
                                : 'Arriving in ~${transit.estimatedMinutes} mins',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: transit.isReached
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transit.isReached
                                ? 'Bus arrived • Tap Pass on Bus to exit'
                                : '${transit.remainingKm.toStringAsFixed(1)} km away • Approaching ${_getNextStopName(transit)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: transit.isReached ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            transit.isReached ? Icons.check_circle_rounded : Icons.traffic_rounded,
                            size: 12,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transit.isReached ? 'STOPPED' : 'Normal Traffic',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Driver, Bus & Contact Tile
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.border(context),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Driver Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            const Color(0xFF0F766E).withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF2DD4BF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transit.driverName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${transit.busNumber} (${transit.vehiclePlate}) • ⭐ ${transit.driverRating}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Call Driver Button
                      IconButton(
                        onPressed: () => _callDriver(transit.driverPhone),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.phone_in_talk_rounded,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                        tooltip: 'Call Driver',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Deboard / RFID Exit Trigger (When student taps on device on bus, stops map!)
                GestureDetector(
                  onTap: widget.onDeboardTap,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: transit.isReached ? 13 : 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: transit.isReached ? const Color(0xFF0F766E) : AppTheme.card(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: transit.isReached ? const Color(0xFF2DD4BF) : AppTheme.border(context),
                        width: transit.isReached ? 1.5 : 1.0,
                      ),
                      boxShadow: transit.isReached
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nfc_rounded,
                          size: transit.isReached ? 18 : 14,
                          color: transit.isReached ? Colors.white : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            transit.isReached
                                ? 'Tap Pass on Bus to Exit & Stop Map'
                                : 'Student Deboarded? Tap Pass to Exit',
                            style: TextStyle(
                              fontSize: transit.isReached ? 12 : 11,
                              fontWeight: transit.isReached ? FontWeight.bold : FontWeight.w600,
                              color: transit.isReached ? Colors.white : AppTheme.textSecondary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: transit.isReached ? 14 : 12,
                          color: transit.isReached ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextStopName(StudentBusTransit transit) {
    for (final stop in transit.stops) {
      if (!stop.isCompleted) return stop.name;
    }
    return transit.destinationCampus;
  }

  Widget _buildJourneyTimeline(
      BuildContext context, StudentBusTransit transit) {
    final progress = transit.progressFraction;

    return Row(
      children: [
        _buildTimelineStep(
          icon: Icons.check_circle_rounded,
          label: 'Boarded',
          time: '08:14 AM',
          isActive: true,
          isDone: true,
        ),
        Expanded(
          child: Container(
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _buildTimelineStep(
          icon: Icons.directions_bus_rounded,
          label: 'On Route',
          time: 'Live',
          isActive: true,
          isDone: progress > 0.85,
          isCurrent: progress <= 0.85,
        ),
        Expanded(
          child: Container(
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: progress > 0.85
                  ? const Color(0xFF10B981)
                  : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _buildTimelineStep(
          icon: Icons.school_rounded,
          label: 'Campus Gate',
          time: '~08:40 AM',
          isActive: progress > 0.85,
          isDone: progress >= 0.96,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String label,
    required String time,
    required bool isActive,
    required bool isDone,
    bool isCurrent = false,
  }) {
    Color iconColor;
    Color bgColor;

    if (isCurrent) {
      iconColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
    } else if (isDone) {
      iconColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.2);
    } else {
      iconColor = const Color(0xFF94A3B8);
      bgColor = const Color(0xFF94A3B8).withValues(alpha: 0.15);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor,
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            color: iconColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 8.5,
            color: Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Custom Vector Map Painter: Emulates Zomato's delivery tracking map
class ZomatoMapPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 along the route
  final double pulseValue; // 0.0 to 1.0 for sonar waves
  final bool isDark;
  final double heightFactor; // 0.0 to 1.0
  final double focalShiftY; // -0.5 to 0.5 for vertical camera focal shift

  ZomatoMapPainter({
    required this.progress,
    required this.pulseValue,
    required this.isDark,
    this.heightFactor = 0.5,
    this.focalShiftY = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Map Color
    final baseBgColor = isDark ? const Color(0xFF12161A) : const Color(0xFFF1F5F9);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = baseBgColor);

    // Apply Zomato camera scale & sinking focal shift
    final scale = 0.92 + (heightFactor * 0.16);
    final offsetY = focalShiftY * h;

    canvas.save();
    canvas.translate(w / 2, (h / 2) + offsetY);
    canvas.scale(scale);
    canvas.translate(-w / 2, -(h / 2) - offsetY);

    // 2. City Blocks & Green Parks
    _drawCityBlocks(canvas, size);

    // 3. Grid Road Network (Streets & Avenues)
    _drawStreetNetwork(canvas, size);

    // 4. Primary Route Polyline (The Zomato delivery road path)
    final routePath = _buildCurvedRoute(size);

    // Route Glow (Subtle teal/cyan neon underlay)
    final glowPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: isDark ? 0.25 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(routePath, glowPaint);

    // Road Base Line (Gray upcoming path)
    final upcomingRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, upcomingRoadPaint);

    // Covered Portion (Active Glowing Emerald Polyline)
    final pathMetrics = routePath.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final totalLen = metric.length;
      final coveredLen = (totalLen * progress).clamp(0.0, totalLen);

      final coveredPath = metric.extractPath(0, coveredLen);
      final activeRoadPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(coveredPath, activeRoadPaint);

      // 5. Boarding Stop Pin (Pickup Location)
      final startPos = metric.getTangentForOffset(0)?.position ?? Offset(w * 0.12, h * 0.78);
      _drawStopPin(
        canvas: canvas,
        center: startPos,
        label: 'Boarded',
        time: '08:14',
        pinColor: const Color(0xFF10B981),
        icon: Icons.person_pin_circle_rounded,
      );

      // 6. Destination Campus Gate Pin
      final endPos = metric.getTangentForOffset(totalLen)?.position ?? Offset(w * 0.88, h * 0.22);
      _drawCampusPin(
        canvas: canvas,
        center: endPos,
        label: 'Campus',
      );

      // 7. Bus Marker & Moving Radar Pulse
      final tangent = metric.getTangentForOffset(coveredLen);
      if (tangent != null) {
        _drawMovingSchoolBus(
          canvas: canvas,
          position: tangent.position,
          angle: tangent.angle,
        );
      }
    }

    canvas.restore();
  }

  void _drawCityBlocks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Green campus garden / park block
    final parkPaint = Paint()
      ..color = isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.35)
          : const Color(0xFFD1FAE5).withValues(alpha: 0.85);

    final r1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.08, w * 0.28, h * 0.38),
      const Radius.circular(10),
    );
    canvas.drawRRect(r1, parkPaint);

    // Tech Park block
    final techPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.5)
          : const Color(0xFFE2E8F0);

    final r2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.42, h * 0.52, w * 0.35, h * 0.38),
      const Radius.circular(8),
    );
    canvas.drawRRect(r2, techPaint);

    // Water reservoir / lake curve
    final lakePaint = Paint()
      ..color = isDark
          ? const Color(0xFF0369A1).withValues(alpha: 0.25)
          : const Color(0xFFBAE6FD).withValues(alpha: 0.6);

    final lakePath = Path()
      ..moveTo(w * 0.75, 0)
      ..quadraticBezierTo(w * 0.92, h * 0.18, w, h * 0.25)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(lakePath, lakePaint);
  }

  void _drawStreetNetwork(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final streetPaint = Paint()
      ..color = isDark ? const Color(0xFF1E242B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Horizontal secondary streets
    canvas.drawLine(Offset(0, h * 0.28), Offset(w, h * 0.28), streetPaint);
    canvas.drawLine(Offset(0, h * 0.68), Offset(w, h * 0.68), streetPaint);

    // Vertical secondary avenues
    canvas.drawLine(Offset(w * 0.36, 0), Offset(w * 0.36, h), streetPaint);
    canvas.drawLine(Offset(w * 0.68, 0), Offset(w * 0.68, h), streetPaint);
  }

  Path _buildCurvedRoute(Size size) {
    final w = size.width;
    final h = size.height;

    // Realistic multi-curve route: Pickup (lower left) -> curves across city -> Campus Gate (upper right)
    final path = Path();
    path.moveTo(w * 0.12, h * 0.78);
    path.cubicTo(
      w * 0.28, h * 0.78,
      w * 0.34, h * 0.52,
      w * 0.48, h * 0.48,
    );
    path.cubicTo(
      w * 0.62, h * 0.44,
      w * 0.70, h * 0.24,
      w * 0.88, h * 0.22,
    );
    return path;
  }

  void _drawStopPin({
    required Canvas canvas,
    required Offset center,
    required String label,
    required String time,
    required Color pinColor,
    required IconData icon,
  }) {
    // Outer glow
    canvas.drawCircle(
      center,
      9,
      Paint()..color = pinColor.withValues(alpha: 0.3),
    );
    // Pin circle
    canvas.drawCircle(
      center,
      6,
      Paint()..color = pinColor,
    );
    // Inner white dot
    canvas.drawCircle(
      center,
      2.5,
      Paint()..color = Colors.white,
    );
  }

  void _drawCampusPin({
    required Canvas canvas,
    required Offset center,
    required String label,
  }) {
    // University icon badge
    final campusColor = const Color(0xFF2DD4BF);
    canvas.drawCircle(
      center,
      12,
      Paint()..color = campusColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      center,
      7,
      Paint()..color = campusColor,
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.black,
    );
  }

  void _drawMovingSchoolBus({
    required Canvas canvas,
    required Offset position,
    required double angle,
  }) {
    // 1. Zomato radar sonar waves (concentric expanding ripples)
    final pulseRadius1 = 12.0 + (pulseValue * 22.0);
    final pulseAlpha1 = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.45;
    canvas.drawCircle(
      position,
      pulseRadius1,
      Paint()..color = const Color(0xFF10B981).withValues(alpha: pulseAlpha1),
    );

    final pulseRadius2 = 8.0 + (pulseValue * 14.0);
    final pulseAlpha2 = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.6;
    canvas.drawCircle(
      position,
      pulseRadius2,
      Paint()..color = const Color(0xFF2DD4BF).withValues(alpha: pulseAlpha2),
    );

    // 2. High-visibility School Bus Yellow Marker
    final busMarkerPaint = Paint()
      ..color = const Color(0xFFFBBF24) // School Bus Amber
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Drop shadow
    canvas.drawCircle(
      position + const Offset(0, 2),
      12,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    canvas.drawCircle(position, 12, busMarkerPaint);
    canvas.drawCircle(position, 12, borderPaint);

    // 3. Direction pointer needle (faces road angle)
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final arrowPath = Path()
      ..moveTo(14, 0)
      ..lineTo(8, -4)
      ..lineTo(8, 4)
      ..close();
    canvas.drawPath(
      arrowPath,
      Paint()..color = const Color(0xFFD97706),
    );

    // Draw miniature bus body in center
    final busRect = Rect.fromCenter(center: Offset.zero, width: 14, height: 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF1E293B),
    );
    // Bus windshield
    final windshield = Rect.fromCenter(center: const Offset(3.5, 0), width: 3, height: 7);
    canvas.drawRect(
      windshield,
      Paint()..color = const Color(0xFF38BDF8),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZomatoMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isDark != isDark ||
        oldDelegate.heightFactor != heightFactor ||
        oldDelegate.focalShiftY != focalShiftY;
  }
}
