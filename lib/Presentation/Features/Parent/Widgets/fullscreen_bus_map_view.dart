import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import 'google_bus_map_widget.dart';

/// Fullscreen Only Map View: When the parent clicks fullscreen,
/// displays edge-to-edge interactive live Google Map with zoom controls,
/// layer switcher, call driver, and smooth camera animation.
class FullscreenOnlyMapView extends StatefulWidget {
  final ChildProfile child;
  final StudentBusTransit initialTransit;
  final VoidCallback onDeboardTap;

  const FullscreenOnlyMapView({
    super.key,
    required this.child,
    required this.initialTransit,
    required this.onDeboardTap,
  });

  @override
  State<FullscreenOnlyMapView> createState() => _FullscreenOnlyMapViewState();
}

class _FullscreenOnlyMapViewState extends State<FullscreenOnlyMapView>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  AnimationController? _flyAnimationController;

  MapTileProvider _tileProvider = MapTileProvider.googleRoadmap;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutQuad,
    );
  }

  @override
  void dispose() {
    _flyAnimationController?.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Smooth Google Maps-style camera flight and zoom in to the live bus location.
  void _flyToBusLocation(StudentBusTransit transit) {
    HapticFeedback.mediumImpact();

    final pos = transit.liveBusPosition;
    final target = LatLng(pos.$1, pos.$2);

    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;

    // Cycle between zoom 17.0 (street view) and 18.2 (ultra close building view)
    final double targetZoom = (currentZoom >= 16.8 && currentZoom < 18.0) ? 18.2 : 17.0;

    _flyAnimationController?.dispose();
    _flyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final animation = CurvedAnimation(
      parent: _flyAnimationController!,
      curve: Curves.easeOutCubic,
    );

    final latTween = Tween<double>(begin: currentCenter.latitude, end: target.latitude);
    final lngTween = Tween<double>(begin: currentCenter.longitude, end: target.longitude);
    final zoomTween = Tween<double>(begin: currentZoom, end: targetZoom);

    _flyAnimationController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _flyAnimationController!.forward();

    // Floating notification feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.my_location_rounded, color: Color(0xFF2DD4BF), size: 18),
            const SizedBox(width: 8),
            Text(
              'Focused on Bus ${transit.busNumber} • Live Street View',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.92),
        margin: const EdgeInsets.only(bottom: 120, left: 30, right: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _zoomIn() {
    HapticFeedback.selectionClick();
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (z + 1).clamp(4.0, 19.0));
  }

  void _zoomOut() {
    HapticFeedback.selectionClick();
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (z - 1).clamp(4.0, 19.0));
  }

  void _toggleTileLayer() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_tileProvider == MapTileProvider.googleRoadmap) {
        _tileProvider = MapTileProvider.googleSatellite;
      } else if (_tileProvider == MapTileProvider.googleSatellite) {
        _tileProvider = MapTileProvider.openStreetMap;
      } else {
        _tileProvider = MapTileProvider.googleRoadmap;
      }
    });
  }

  Future<void> _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<ParentController>();
    final transit = controller.childTransit(widget.child.id) ?? widget.initialTransit;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12161A) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. FULLSCREEN ONLY LIVE MAP (Real Interactive Google Map - Free API)
          Positioned.fill(
            child: GoogleBusMapWidget(
              transit: transit,
              isInteractive: true,
              showControls: false, // Handled cleanly by HUD overlay without collisions
              initialZoom: 15.0,
              mapController: _mapController,
              tileProvider: _tileProvider,
            ),
          ),

          // 2. TOP FLOATING HUD BAR (Back & Live Bus Status)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF18181B) : Colors.white).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.text(context)),
                            const SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Center Live Status Pill
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF18181B) : Colors.white).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, _) => Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.4 + (_pulseAnimation.value * 0.6)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                transit.isReached
                                    ? (transit.destinationType == TransitDestinationType.school
                                        ? 'REACHED SCHOOL'
                                        : 'REACHED HOME')
                                    : 'LIVE • ${transit.busNumber}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. REACHED CELEBRATION PILL OVERLAY
          if (transit.isReached)
            Positioned(
              top: 68,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF34D399), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    transit.reachedCelebrationTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

          // 4. FLOATING GOOGLE MAPS CONTROLS (Layer Switcher, Zoom, Target Recenter, Call Driver)
          Positioned(
            right: 14,
            bottom: 140, // Safely above bottom card to eliminate all overlaps
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Layer switcher (Roadmap / Satellite / OSM)
                _buildFloatingButton(
                  icon: Icons.layers_outlined,
                  onTap: _toggleTileLayer,
                  tooltip: 'Switch Map Layer',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),

                // Zoom controls group (+ / -)
                Container(
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF18181B) : Colors.white).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _zoomIn,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: SizedBox(
                          width: 38,
                          height: 36,
                          child: Icon(Icons.add_rounded, size: 20, color: AppTheme.text(context)),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.8, color: AppTheme.border(context)),
                      InkWell(
                        onTap: _zoomOut,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                        child: SizedBox(
                          width: 38,
                          height: 36,
                          child: Icon(Icons.remove_rounded, size: 20, color: AppTheme.text(context)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Target / My Location Symbol (Smooth animated camera fly & street zoom to bus!)
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _flyToBusLocation(transit),
                  tooltip: 'Zoom into Live Bus Location',
                  isDark: isDark,
                  iconColor: const Color(0xFF0F766E),
                ),
                const SizedBox(height: 8),

                // Call Driver button
                _buildFloatingButton(
                  icon: Icons.phone_rounded,
                  onTap: () => _callDriver(transit.driverPhone),
                  tooltip: 'Call Driver',
                  backgroundColor: const Color(0xFF10B981),
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),

          // 5. MINIMAL FLOATING BOTTOM CARD (Destination, ETA, & Deboard Button)
          Positioned(
            bottom: 16,
            left: 14,
            right: 14,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF18181B) : Colors.white).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: transit.isReached
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                    width: transit.isReached ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Destination & ETA row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                transit.destinationTitle,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                transit.isReached
                                    ? 'Bus arrived at ${transit.destinationTitle}'
                                    : 'ETA ~${transit.estimatedMinutes} mins • ${transit.remainingKm} km away • ${transit.routeName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: transit.isReached ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            transit.isReached ? 'STOPPED' : 'ON TIME',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    // Deboard / Exit Button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onDeboardTap();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: transit.isReached ? 11 : 8,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: transit.isReached
                              ? const Color(0xFF0F766E)
                              : AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: transit.isReached
                                ? const Color(0xFF2DD4BF)
                                : AppTheme.border(context),
                            width: transit.isReached ? 1.4 : 1.0,
                          ),
                          boxShadow: transit.isReached
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.nfc_rounded,
                              size: transit.isReached ? 16 : 14,
                              color: transit.isReached
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF2DD4BF),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                transit.isReached
                                    ? '📱 Tap Pass on Bus Reader to Exit & Stop Map'
                                    : '📱 Tap Pass on Bus to Deboard',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: transit.isReached
                                      ? Colors.white
                                      : AppTheme.text(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? backgroundColor,
    Color? iconColor,
    bool isDark = false,
  }) {
    final bg = backgroundColor ?? ((isDark ? const Color(0xFF18181B) : Colors.white).withValues(alpha: 0.95));
    final fg = iconColor ?? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 19, color: fg),
      ),
    );
  }
}
