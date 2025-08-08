import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:unitrack/config/app_colors.dart';

class ManageBuggiesScreen extends StatefulWidget {
  const ManageBuggiesScreen({super.key});

  @override
  State<ManageBuggiesScreen> createState() => _ManageBuggiesScreenState();
}

class _ManageBuggiesScreenState extends State<ManageBuggiesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _buggies = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBuggies();
  }

  Future<void> _loadBuggies() async {
    setState(() => _loading = true);
    try {
      final response = await _supabase
          .from('buggies')
          .select('id, buggy_number, assigned_driver, drivers(name)');
      setState(() {
        _buggies = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showError('Error loading buggies: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _getBuggyLocation(String buggyId) async {
    try {
      final response = await _supabase
          .from('buggy_locations')
          .select('latitude, longitude')
          .eq('buggy_id', buggyId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  void _showBuggyMap(String buggyId, String buggyNumber) async {
    final location = await _getBuggyLocation(buggyId);

    if (location == null) {
      _showError('No location found for Buggy #$buggyNumber');
      return;
    }

    final lat = (location['latitude'] as num).toDouble();
    final lng = (location['longitude'] as num).toDouble();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuggyMapScreen(
          buggyId: buggyId,
          buggyNumber: buggyNumber,
          initialLat: lat,
          initialLng: lng,
          onLocationRefresh: _getBuggyLocation,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.warningOrangeLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(
          "Manage Buggies",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : RefreshIndicator(
              onRefresh: _loadBuggies,
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.cardBackground,
              child: _buggies.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _buggies.length,
                      itemBuilder: (context, index) {
                        final buggy = _buggies[index];
                        return _buildBuggyCard(buggy);
                      },
                    ),
            ),
    );
  }

  Widget _buildBuggyCard(Map<String, dynamic> buggy) {
    final driverName = buggy['drivers']?['name'] ?? 'Not Assigned';
    final isAssigned = buggy['drivers']?['name'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutralGray.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.electric_car,
            color: AppColors.primaryBlue,
            size: 24,
          ),
        ),
        title: Text(
          'Buggy #${buggy['buggy_number']}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: isAssigned
                    ? AppColors.successGreen
                    : AppColors.neutralGray,
              ),
              const SizedBox(width: 4),
              Text(
                'Driver: $driverName',
                style: TextStyle(
                  color: isAssigned
                      ? AppColors.successGreen
                      : AppColors.textSecondary,
                  fontWeight: isAssigned ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.map, color: AppColors.accentTeal, size: 20),
        ),
        onTap: () => _showBuggyMap(buggy['id'], buggy['buggy_number']),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neutralGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.electric_car,
              size: 48,
              color: AppColors.neutralGray,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No buggies found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull to refresh to check for new buggies',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// Separate screen for the map to avoid bottom sheet issues
class BuggyMapScreen extends StatefulWidget {
  final String buggyId;
  final String buggyNumber;
  final double initialLat;
  final double initialLng;
  final Future<Map<String, dynamic>?> Function(String) onLocationRefresh;

  const BuggyMapScreen({
    super.key,
    required this.buggyId,
    required this.buggyNumber,
    required this.initialLat,
    required this.initialLng,
    required this.onLocationRefresh,
  });

  @override
  State<BuggyMapScreen> createState() => _BuggyMapScreenState();
}

class _BuggyMapScreenState extends State<BuggyMapScreen> {
  late MapController _mapController;
  bool _isRefreshing = false;
  double _currentLat = 0;
  double _currentLng = 0;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
    _mapController = MapController(
      initPosition: GeoPoint(latitude: _currentLat, longitude: _currentLng),
    );

    // Auto-refresh location when screen opens - delayed to ensure map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _refreshLocation();
        }
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
  if (!mounted) return;

  setState(() => _isRefreshing = true);

  try {
    final updatedLocation = await widget.onLocationRefresh(widget.buggyId);

    if (!mounted) return;

    if (updatedLocation == null) {
      _showError('No location found for Buggy #${widget.buggyNumber}');
      return;
    }

    final newLat = (updatedLocation['latitude'] as num).toDouble();
    final newLng = (updatedLocation['longitude'] as num).toDouble();

    // Store the old coordinates for marker removal
    final oldLat = _currentLat;
    final oldLng = _currentLng;

    // Update state with new coordinates
    setState(() {
      _currentLat = newLat;
      _currentLng = newLng;
    });

    // Only move camera and update markers if the location actually changed
    if (oldLat != newLat || oldLng != newLng) {
      // Update map position smoothly FIRST
      await _mapController.moveTo(
        GeoPoint(latitude: newLat, longitude: newLng),
      );

      // Clear existing markers using the OLD coordinates
      try {
        await _mapController.removeMarker(
          GeoPoint(latitude: oldLat, longitude: oldLng),
        );
      } catch (e) {
        // Ignore errors if marker doesn't exist
      }

      // Add new marker at the new location
      await _mapController.addMarker(
        GeoPoint(latitude: newLat, longitude: newLng),
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.electric_car,
            color: AppColors.primaryBlue,
            size: 48,
          ),
        ),
      );

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location updated successfully'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      _showError('Error refreshing location: $e');
    }
  } finally {
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }
}

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.warningOrangeLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.electric_car, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Buggy #${widget.buggyNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshLocation,
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            color: Colors.white,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Location info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground,
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Location: ${_currentLat.toStringAsFixed(6)}, ${_currentLng.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neutralGray.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: OSMFlutter(
                  controller: _mapController,
                  osmOption: OSMOption(
                    // Enable user interactions
                    userTrackingOption: const UserTrackingOption(
                      enableTracking: false,
                      unFollowUser: false,
                    ),
                    // Enable zooming and panning
                    zoomOption: const ZoomOption(
                      initZoom: 17,
                      minZoomLevel: 10,
                      maxZoomLevel: 19,
                      stepZoom: 1.0,
                    ),
                    // Enable map interactions
                    enableRotationByGesture: true,
                    showZoomController: true,
                    showDefaultInfoWindow: false,
                    showContributorBadgeForOSM: false,
                    // Initial marker
                    staticPoints: [
                      StaticPositionGeoPoint(
                        'buggy_${widget.buggyId}',
                        const MarkerIcon(
                          icon: Icon(
                            Icons.electric_car,
                            color: AppColors.primaryBlue,
                            size: 48,
                          ),
                        ),
                        [
                          GeoPoint(
                            latitude: _currentLat,
                            longitude: _currentLng,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRefreshing ? null : _refreshLocation,
                    icon: _isRefreshing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isRefreshing ? 'Refreshing...' : 'Refresh Location',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _mapController.moveTo(
                      GeoPoint(latitude: _currentLat, longitude: _currentLng),
                    );
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Center'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
}
