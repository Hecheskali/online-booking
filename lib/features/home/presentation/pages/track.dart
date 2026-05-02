import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/local_ticket_storage_service.dart';
import '../../../../core/services/native_app_config_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/booked_ticket_record.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  static const CameraPosition _fallbackCamera = CameraPosition(
    target: LatLng(-6.7924, 39.2083),
    zoom: 12,
  );

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  final LocalTicketStorageService _ticketStorageService =
      LocalTicketStorageService();
  final NativeAppConfigService _nativeAppConfigService =
      NativeAppConfigService();

  Position? _currentPosition;
  BookedTicketRecord? _activeTicket;
  List<LatLng> _trail = [];
  LocationPermission? _permission;
  bool _hasGoogleMapsApiKey = false;
  bool _isLoading = true;
  bool _serviceEnabled = true;
  bool _followLocation = true;
  bool _showTraffic = false;
  MapType _mapType = MapType.normal;
  DateTime? _lastUpdatedAt;

  static const String _mapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#eef2ff"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c4d7ff"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#e9eefb"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _hasGoogleMapsApiKey = await _nativeAppConfigService.hasGoogleMapsApiKey();
    await _loadActiveTicket();
    await _prepareTracking();
  }

  Future<void> _loadActiveTicket() async {
    _activeTicket = await _ticketStorageService.loadNextUpcomingTicket();
  }

  Future<void> _prepareTracking() async {
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      return;
    }

    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }

    if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      return;
    }

    final current = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    _updatePosition(current, animateCamera: false);
    _startPositionStream();
  }

  void _startPositionStream() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position, {bool animateCamera = true}) {
    final nextPoint = LatLng(position.latitude, position.longitude);
    final trail = List<LatLng>.from(_trail);
    if (trail.isEmpty ||
        trail.last.latitude != nextPoint.latitude ||
        trail.last.longitude != nextPoint.longitude) {
      trail.add(nextPoint);
      if (trail.length > 24) {
        trail.removeAt(0);
      }
    }

    if (!mounted) {
      _trail = trail;
      _currentPosition = position;
      _lastUpdatedAt = DateTime.now();
      _isLoading = false;
      return;
    }

    setState(() {
      _trail = trail;
      _currentPosition = position;
      _lastUpdatedAt = DateTime.now();
      _isLoading = false;
    });

    if (_mapController != null && _followLocation && animateCamera) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: nextPoint,
            zoom: 16.5,
            bearing: position.heading,
            tilt: 45,
          ),
        ),
      );
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  void _cycleMapType() {
    setState(() {
      if (_mapType == MapType.normal) {
        _mapType = MapType.satellite;
      } else if (_mapType == MapType.satellite) {
        _mapType = MapType.terrain;
      } else {
        _mapType = MapType.normal;
      }
    });
  }

  void _recenterMap() {
    final position = _currentPosition;
    if (_mapController == null || position == null) {
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLatLng = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          _hasGoogleMapsApiKey
              ? GoogleMap(
                  initialCameraPosition: currentLatLng == null
                      ? _fallbackCamera
                      : CameraPosition(target: currentLatLng, zoom: 16),
                  onTap: (_) => AppSessionService.instance.markActivity(),
                  onLongPress: (_) => AppSessionService.instance.markActivity(),
                  onCameraMoveStarted: AppSessionService.instance.markActivity,
                  onCameraIdle: AppSessionService.instance.markActivity,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  style: _mapStyle,
                  mapType: _mapType,
                  myLocationEnabled: currentLatLng != null,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  trafficEnabled: _showTraffic,
                  compassEnabled: false,
                  markers: currentLatLng == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('current-location'),
                            position: currentLatLng,
                            infoWindow: const InfoWindow(
                              title: 'Your live location',
                              snippet:
                                  'Streaming from this device inside the app',
                            ),
                          ),
                        },
                  polylines: _trail.length < 2
                      ? {}
                      : {
                          Polyline(
                            polylineId: const PolylineId('journey-trail'),
                            points: _trail,
                            width: 5,
                            color: AppColors.primary,
                          ),
                        },
                )
              : _buildMapSetupBackground(),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(30),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (!_isLoading &&
              (_permission == LocationPermission.denied ||
                  _permission == LocationPermission.deniedForever ||
                  !_serviceEnabled))
            _buildPermissionState(),
          if (!_hasGoogleMapsApiKey) _buildMapsKeyMissingState(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildHeaderCard(),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 120,
            child: Column(
              children: [
                _buildMapAction(
                  icon: Icons.layers_rounded,
                  label: 'Map',
                  onTap: _cycleMapType,
                ),
                const SizedBox(height: 12),
                _buildMapAction(
                  icon: _showTraffic
                      ? Icons.traffic_rounded
                      : Icons.traffic_outlined,
                  label: 'Traffic',
                  onTap: () => setState(() => _showTraffic = !_showTraffic),
                ),
                const SizedBox(height: 12),
                _buildMapAction(
                  icon: _followLocation
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  label: 'Follow',
                  onTap: () =>
                      setState(() => _followLocation = !_followLocation),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildTelemetryCard(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _hasGoogleMapsApiKey ? _recenterMap : null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.my_location_rounded),
        label: const Text('RECENTER'),
      ),
    );
  }

  Widget _buildMapSetupBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF172554),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildPermissionState() {
    final deniedForever = _permission == LocationPermission.deniedForever;
    final title = !_serviceEnabled
        ? 'Turn on location services'
        : 'Allow location access';
    final description = !_serviceEnabled
        ? 'Live tracking needs device location services enabled so the map can keep you on route inside the app.'
        : deniedForever
            ? 'Location permission is blocked for this app. Open settings and allow precise location to continue.'
            : 'This page uses your device location to show live tracking and map telemetry without leaving the app.';

    return Container(
      color: Colors.black.withAlpha(80),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_searching_rounded,
                  color: AppColors.primary, size: 52),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !_serviceEnabled
                      ? _openLocationSettings
                      : deniedForever
                          ? _openAppSettings
                          : _prepareTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    !_serviceEnabled
                        ? 'OPEN LOCATION SETTINGS'
                        : deniedForever
                            ? 'OPEN APP SETTINGS'
                            : 'ENABLE LOCATION',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapsKeyMissingState() {
    return Container(
      color: Colors.black.withAlpha(85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: 52,
              ),
              const SizedBox(height: 18),
              const Text(
                'Google Maps key missing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Login will no longer crash. To enable the in-app map, add `google.maps.api.key=YOUR_ANDROID_MAPS_KEY` to `android/local.properties`, then restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const SelectableText(
                  'google.maps.api.key=YOUR_ANDROID_MAPS_KEY',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final title = _activeTicket == null
        ? 'Personal live location'
        : '${_activeTicket!.from} -> ${_activeTicket!.to}';
    final subtitle = _activeTicket == null
        ? 'Google Maps is running inside the app using this device location.'
        : '${_activeTicket!.busName} • ${DateFormat('dd MMM').format(_activeTicket!.travelDate)} • ${_activeTicket!.departureTime}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.radar_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: Colors.red),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withAlpha(235),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textPrimary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard() {
    final position = _currentPosition;
    final coordinates = position == null
        ? '--'
        : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    final speed =
        position == null ? '--' : (position.speed * 3.6).toStringAsFixed(1);
    final heading =
        position == null ? '--' : position.heading.toStringAsFixed(0);
    final altitude =
        position == null ? '--' : position.altitude.toStringAsFixed(0);
    final accuracy =
        position == null ? '--' : position.accuracy.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xEE0F172A),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Live telemetry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                _lastUpdatedAt == null
                    ? 'Waiting...'
                    : 'Updated ${DateFormat('hh:mm:ss a').format(_lastUpdatedAt!)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _telemetryItem('Coordinates', coordinates),
              _telemetryItem('Speed', '$speed km/h'),
              _telemetryItem('Heading', '$heading°'),
              _telemetryItem('Accuracy', '$accuracy m'),
              _telemetryItem('Altitude', '$altitude m'),
              _telemetryItem(
                'Trail points',
                _trail.length.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active trip context',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _activeTicket == null
                      ? 'No upcoming ticket yet. The map is still tracking this device in real time.'
                      : '${_activeTicket!.busName} • ${_activeTicket!.routeLabel} • Seats ${_activeTicket!.seatNumbers.join(', ')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _telemetryItem(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
