import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Models/parent_models.dart';

enum MapTileProvider {
  googleRoadmap,
  googleSatellite,
  openStreetMap,
}

/// A real, interactive Google Map widget powered by flutter_map.
/// Uses free Google Map tile servers (mt1.google.com) and OpenStreetMap tiles.
/// Requires NO API key, NO billing, and NO paid account.
class GoogleBusMapWidget extends StatefulWidget {
  final StudentBusTransit transit;
  final bool isInteractive;
  final bool showControls;
  final double initialZoom;
  final VoidCallback? onFullscreenTap;
  final MapController? mapController;
  final MapTileProvider tileProvider;
  final ValueChanged<MapTileProvider>? onTileProviderChanged;

  const GoogleBusMapWidget({
    super.key,
    required this.transit,
    this.isInteractive = true,
    this.showControls = true,
    this.initialZoom = 14.5,
    this.onFullscreenTap,
    this.mapController,
    this.tileProvider = MapTileProvider.googleRoadmap,
    this.onTileProviderChanged,
  });

  @override
  State<GoogleBusMapWidget> createState() => _GoogleBusMapWidgetState();
}

class _GoogleBusMapWidgetState extends State<GoogleBusMapWidget>
    with SingleTickerProviderStateMixin {
  late final MapController _internalMapController;
  MapController get _mapController => widget.mapController ?? _internalMapController;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late MapTileProvider _currentTileProvider;

  @override
  void initState() {
    super.initState();
    _internalMapController = MapController();
    _currentTileProvider = widget.tileProvider;
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
  void didUpdateWidget(covariant GoogleBusMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tileProvider != oldWidget.tileProvider) {
      _currentTileProvider = widget.tileProvider;
    }
  }

  @override
  void dispose() {
    if (widget.mapController == null) {
      _internalMapController.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  List<LatLng> _getRouteCoordinates() {
    final waypoints = widget.transit.routePoints;
    return waypoints.map((p) => LatLng(p[0], p[1])).toList();
  }

  LatLng _getBusLocation() {
    final pos = widget.transit.liveBusPosition;
    return LatLng(pos.$1, pos.$2);
  }

  String _getTileUrl() {
    switch (_currentTileProvider) {
      case MapTileProvider.googleRoadmap:
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapTileProvider.googleSatellite:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapTileProvider.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _recenterOnBus() {
    final busLoc = _getBusLocation();
    _mapController.move(busLoc, 17.0);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(3.0, 19.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(3.0, 19.0));
  }

  void _toggleTileProvider() {
    setState(() {
      if (_currentTileProvider == MapTileProvider.googleRoadmap) {
        _currentTileProvider = MapTileProvider.googleSatellite;
      } else if (_currentTileProvider == MapTileProvider.googleSatellite) {
        _currentTileProvider = MapTileProvider.openStreetMap;
      } else {
        _currentTileProvider = MapTileProvider.googleRoadmap;
      }
      widget.onTileProviderChanged?.call(_currentTileProvider);
    });
  }

  String _tileProviderLabel() {
    switch (_currentTileProvider) {
      case MapTileProvider.googleRoadmap:
        return 'Google Map';
      case MapTileProvider.googleSatellite:
        return 'Satellite';
      case MapTileProvider.openStreetMap:
        return 'OpenStreetMap';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busLoc = _getBusLocation();
    final routePoints = _getRouteCoordinates();
    final startLoc = routePoints.isNotEmpty ? routePoints.first : busLoc;
    final destLoc = routePoints.isNotEmpty ? routePoints.last : busLoc;

    return Stack(
      children: [
        // 1. The Interactive Flutter Map Layer (Google Maps Tiles)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: busLoc,
            initialZoom: widget.initialZoom,
            minZoom: 4.0,
            maxZoom: 19.0,
            interactionOptions: InteractionOptions(
              flags: widget.isInteractive
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            // Dynamic Tile Layer (Google Roadmap / Satellite / OSM)
            TileLayer(
              urlTemplate: _getTileUrl(),
              userAgentPackageName: 'com.intelliattend.parent',
              maxZoom: 19,
              tileProvider: NetworkTileProvider(),
            ),

            // Route Polyline Layer
            if (routePoints.length >= 2) ...[
              // Outer glow line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                    strokeWidth: 8.0,
                  ),
                ],
              ),
              // Main crisp road line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: const Color(0xFF0F766E),
                    strokeWidth: 4.5,
                  ),
                ],
              ),
            ],

            // Real-Time Markers
            MarkerLayer(
              markers: [
                // LIVE Bus Marker with animated radar ripples
                Marker(
                  point: busLoc,
                  width: 58,
                  height: 58,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Concentric radar ripple
                          Container(
                            width: 38 + (_pulseAnimation.value * 18),
                            height: 38 + (_pulseAnimation.value * 18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: (1.0 - _pulseAnimation.value) * 0.45),
                            ),
                          ),
                          // Main Bus Circle
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.directions_bus_rounded,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),
                          ),
                          // Little live status dot
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Map Provider Badge (Only shown if controls are enabled)
        if (widget.showControls)
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_rounded, size: 11, color: Color(0xFF2DD4BF)),
                  const SizedBox(width: 4),
                  Text(
                    _tileProviderLabel(),
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. Floating Interactive Controls (Only shown if showControls is true)
        if (widget.showControls)
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter on bus
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  onTap: _recenterOnBus,
                  tooltip: 'Center on Bus',
                  isPrimary: true,
                ),
                const SizedBox(height: 6),

                // Zoom controls group
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSmallIconButton(
                        icon: Icons.add_rounded,
                        onTap: _zoomIn,
                        tooltip: 'Zoom In',
                        isDark: isDark,
                      ),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                      ),
                      _buildSmallIconButton(
                        icon: Icons.remove_rounded,
                        onTap: _zoomOut,
                        tooltip: 'Zoom Out',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Toggle Tile Provider (Google / Satellite / OSM)
                _buildMapControlBtn(
                  icon: Icons.layers_outlined,
                  onTap: _toggleTileProvider,
                  tooltip: 'Switch Map Layer',
                  isDark: isDark,
                ),

                // Fullscreen Map Button
                if (widget.onFullscreenTap != null) ...[
                  const SizedBox(height: 6),
                  _buildMapControlBtn(
                    icon: Icons.open_in_full_rounded,
                    onTap: widget.onFullscreenTap!,
                    tooltip: 'Fullscreen Map',
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
    bool isDark = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFF0F766E)
                : (isDark ? const Color(0xFF0F172A) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF2DD4BF)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 19,
            color: isPrimary
                ? Colors.white
                : (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E)),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
