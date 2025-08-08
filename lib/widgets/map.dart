import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../config/constant.dart';

class UniversityMapWidget extends StatefulWidget {
  final bool isActive;
  const UniversityMapWidget({super.key, required this.isActive});

  @override
  State<UniversityMapWidget> createState() => _UniversityMapWidgetState();
}

class _UniversityMapWidgetState extends State<UniversityMapWidget> {
  late MapController controller;
  StreamSubscription<Position>? _positionStream;
  GeoPoint? _currentPosition;
  bool _isMapReady = false;
  bool _locationPermissionGranted = false;
  String _statusMessage = 'Initializing...';


  // Option to enable/disable boundaries
  bool enableBoundaries = false;


  @override
  void initState() {
    super.initState();
    controller = MapController(
      initPosition: GeoPoint(latitude: 22.29006, longitude: 73.36328),
    );
  }

  @override
  void didUpdateWidget(covariant UniversityMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && _isMapReady) {
      _initializeLocation();
    }
    if (!widget.isActive && oldWidget.isActive) {
      _positionStream?.cancel();
      _positionStream = null;
      // Remove golf cart marker when inactive
      _removeGolfCartMarker();
      if (mounted) {
        setState(() {
          _statusMessage = 'Inactive';
        });
      }
    }
  }

  Future<void> _initializeLocation() async {
    if (!widget.isActive) return;
    print('Starting location initialization...');

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Location services disabled';
          });
        }
        print('Location services are disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Location permission denied';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Location permission permanently denied';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _locationPermissionGranted = true;
          _statusMessage = 'Getting location...';
        });
      }

      // Get current position
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );

        print(
          'Got current position: ${position.latitude}, ${position.longitude}',
        );

        if (mounted && _isMapReady) {
          await _updateGolfCartPosition(position);
        }

        // Start location tracking
        _startLocationTracking();
      } catch (e) {
        print('Error getting current position: $e');
        if (mounted) {
          setState(() {
            _statusMessage = 'Error getting location: $e';
          });
        }
      }
    } catch (e) {
      print('Error in location initialization: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Location error: $e';
        });
      }
    }
  }

  void _startLocationTracking() {
    if (!_locationPermissionGranted || !widget.isActive) return;

    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Update every 3 meters (reduced from 1)
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          print(
            'Position update: ${position.latitude}, ${position.longitude}',
          );
          
          // Only update if there's a significant change
          if (_shouldUpdatePosition(position)) {
            if (mounted && _isMapReady) {
              _updateGolfCartPosition(position);
            }
          }
        },
        onError: (error) {
          print('Location stream error: $error');
          if (mounted) {
            setState(() {
              _statusMessage = 'Location stream error: $error';
            });
          }
        },
      );
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  // Check if position update is significant enough
  bool _shouldUpdatePosition(Position newPosition) {
    if (_currentPosition == null) return true;
    
    // Calculate distance between current and new position
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    // Only update if moved more than 2 meters
    return distance > 2.0;
  }

  Future<void> _updateGolfCartPosition(Position position) async {
    if (!_isMapReady || !mounted || !widget.isActive) return;

    try {
      final newPosition = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      print(
        'Updating marker at: ${newPosition.latitude}, ${newPosition.longitude}',
      );

      // Remove existing golf cart marker first
      await _removeGolfCartMarker();

      // Create marker icon
      MarkerIcon markerIcon = await _createCustomMarkerIcon();

      // Add new marker
      await controller.addMarker(
        newPosition,
        markerIcon: markerIcon,
      );

      if (mounted) {
        setState(() {
          _currentPosition = newPosition;
          _statusMessage = 'Golf Cart Online';
        });
      }

      print('Golf cart marker updated successfully');
    } catch (e) {
      print('Error updating golf cart position: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error updating position: $e';
        });
      }
    }
  }

  // Helper method to remove golf cart marker
  Future<void> _removeGolfCartMarker() async {
    if (_currentPosition != null) {
      try {
        await controller.removeMarkers([_currentPosition!]);
      } catch (e) {
        print('Error removing golf cart marker: $e');
      }
    }
  }

  // Alternative method using custom widget for marker
  Future<MarkerIcon> _createCustomMarkerIcon() async {
    try {
      return MarkerIcon(
        iconWidget: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/png/golf-cart.png"),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } catch (e) {
      print('Custom widget marker failed, using fallback: $e');
      return MarkerIcon(
        icon: Icon(Icons.directions_car, color: Colors.blue, size: 40),
      );
    }
  }

  Future<void> _setMapBoundaries() async {
    if (!enableBoundaries || !_isMapReady) return;

    try {
      await controller.limitAreaMap(
        BoundingBox(
          east: eastBoundary,
          north: northBoundary,
          south: southBoundary,
          west: westBoundary,
        ),
      );
      print('Map boundaries set successfully');
    } catch (e) {
      print('Error setting map boundaries: $e');
    }
  }

  void _toggleBoundaries() {
    if (mounted) {
      setState(() {
        enableBoundaries = !enableBoundaries;
      });
    }

    if (_isMapReady) {
      if (enableBoundaries) {
        _setMapBoundaries();
      } else {
        try {
          controller.limitAreaMap(
            BoundingBox(east: 180, north: 85, south: -85, west: -180),
          );
        } catch (e) {
          print('Error removing boundaries: $e');
        }
      }
    }
  }

  void _centerOnGolfCart() {
    if (_currentPosition != null && _isMapReady) {
      try {
        controller.moveTo(_currentPosition!);
        print('Centered on golf cart');
      } catch (e) {
        print('Error centering on golf cart: $e');
      }
    }
  }

  // Manual refresh button
  void _refreshLocation() {
    if (_locationPermissionGranted && _isMapReady && widget.isActive) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Refreshing location...';
        });
      }

      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      )
          .then((position) {
        print(
          'Manual refresh position: ${position.latitude}, ${position.longitude}',
        );
        _updateGolfCartPosition(position);
      }).catchError((error) {
        print('Manual refresh error: $error');
        if (mounted) {
          setState(() {
            _statusMessage = 'Refresh failed: $error';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshLocation,
            tooltip: 'Refresh Location',
          ),
          IconButton(
            icon: Icon(
              enableBoundaries ? Icons.lock : Icons.lock_open,
              color: enableBoundaries ? Colors.red : Colors.green,
            ),
            onPressed: _toggleBoundaries,
            tooltip: enableBoundaries
                ? 'Disable Boundaries'
                : 'Enable Boundaries',
          ),
        ],
      ),
      body: Stack(
        children: [
          OSMFlutter(
            controller: controller,
            osmOption: OSMOption(
              zoomOption: ZoomOption(
                initZoom: 17,
                minZoomLevel: 15,
                maxZoomLevel: 19,
              ),
              userTrackingOption: UserTrackingOption(
                enableTracking: false,
                unFollowUser: true,
              ),
              showDefaultInfoWindow: false,
            ),
            onMapIsReady: (isReady) async {
              print('Map ready: $isReady');
              if (isReady && mounted) {
                if (mounted) {
                  setState(() {
                    _isMapReady = true;
                  });
                }

                // Initialize location after map is ready
                await _initializeLocation();

                // Set boundaries
                await _setMapBoundaries();
              }
            },
          ),

          // Status indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _currentPosition != null
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton:
          _currentPosition != null && _isMapReady && widget.isActive
              ? FloatingActionButton(
                  onPressed: _centerOnGolfCart,
                  child: const Icon(Icons.my_location),
                  tooltip: 'Center on Golf Cart',
                )
              : null,
    );
  }
}