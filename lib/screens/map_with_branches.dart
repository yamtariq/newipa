import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

class MapWithBranchesScreen extends StatefulWidget {
  final bool isArabic;

  MapWithBranchesScreen({required this.isArabic});

  @override
  _MapWithBranchesScreenState createState() => _MapWithBranchesScreenState();
}

class _MapWithBranchesScreenState extends State<MapWithBranchesScreen> with WidgetsBindingObserver {
  final BranchService _branchService = BranchService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  List<Branch> branches = [];
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_mapController != null && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initializeLocationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt < 33) { // Android 13 and below
        // Request both permissions for older Android versions
        await _requestOldAndroidPermissions();
      } else {
        // For Android 13+ (API 33+), only request when-in-use permission
        await _checkLocationPermission();
      }
    } else {
      await _checkLocationPermission();
    }
  }

  Future<void> _requestOldAndroidPermissions() async {
    try {
      // First check if location service is enabled
      if (!await Permission.locationWhenInUse.serviceStatus.isEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'يرجى تفعيل خدمة الموقع من إعدادات الجهاز'
                    : 'Please enable location services in device settings',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // For Android 13, first request the basic permission
      final basicStatus = await Permission.locationWhenInUse.request();
      if (!basicStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'يجب السماح بإذن الموقع لاستخدام هذه الميزة'
                    : 'Location permission is required for this feature',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Then request background permission if needed
      final backgroundStatus = await Permission.locationAlways.request();
      
      if (mounted) {
        setState(() {
          // Even if background permission is denied, we can still use foreground location
          _locationPermissionGranted = basicStatus.isGranted;
        });
      }

      _loadData();
      
      // Force rebuild the map
      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      print('Error requesting location permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'حدث خطأ أثناء طلب أذونات الموقع'
                  : 'Error requesting location permissions',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    // First check if location service is enabled
    if (!await Permission.locationWhenInUse.serviceStatus.isEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'يرجى تفعيل خدمة الموقع'
                  : 'Please enable location services',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Check permission status
    PermissionStatus status = await Permission.locationWhenInUse.status;
    
    if (status.isDenied) {
      // Request permission
      status = await Permission.locationWhenInUse.request();
    }
    
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'تم رفض إذن الموقع. يرجى تمكينه من إعدادات التطبيق'
                  : 'Location permission denied. Please enable it in app settings',
            ),
            action: SnackBarAction(
              label: widget.isArabic ? 'الإعدادات' : 'Settings',
              onPressed: () => openAppSettings(),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _locationPermissionGranted = status.isGranted;
      });
    }

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final branchList = await _branchService.getBranches();
      setState(() {
        branches = branchList;
        _setMarkers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isArabic 
              ? 'حدث خطأ أثناء تحميل بيانات الفروع'
              : 'Error loading branch data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setMarkers() {
    setState(() {
      _markers.clear();
      for (var branch in branches) {
        _markers.add(Marker(
          markerId: MarkerId(branch.nameEn),
          position: LatLng(branch.latitude, branch.longitude),
          infoWindow: InfoWindow(
            title: widget.isArabic ? branch.nameAr : branch.nameEn,
            snippet: branch.address,
          ),
        ));
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) async {
    if (!mounted) return;
    
    setState(() {
      _mapController = controller;
      _mapReady = true;
    });

    await Future.delayed(Duration(milliseconds: 100));
    if (mounted && _markers.isNotEmpty) {
      final bounds = _calculateBounds();
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _calculateBounds() {
    double? minLat, maxLat, minLng, maxLng;
    
    for (Marker marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 24.7136, minLng ?? 46.6753),
      northeast: LatLng(maxLat ?? 24.7136, maxLng ?? 46.6753),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? "خريطة الفروع" : "Branches Map"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.location_searching),
            onPressed: () async {
              if (Platform.isAndroid) {
                final androidInfo = await _deviceInfo.androidInfo;
                if (androidInfo.version.sdkInt < 33) {
                  await _requestOldAndroidPermissions();
                } else {
                  await _checkLocationPermission();
                }
              } else {
                await _checkLocationPermission();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(24.7136, 46.6753), // Center of Saudi Arabia
                      zoom: 6,
                    ),
                    mapType: MapType.normal,
                    markers: _markers,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: _locationPermissionGranted,
                    myLocationButtonEnabled: _locationPermissionGranted,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false, // Disable toolbar to prevent artifacts
                    compassEnabled: true,
                    buildingsEnabled: false, // Disable 3D buildings
                    indoorViewEnabled: false,
                    trafficEnabled: false,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    tiltGesturesEnabled: false, // Disable tilt to prevent rendering issues
                    liteModeEnabled: Platform.isAndroid, // Enable lite mode for all Android versions
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return ListTile(
                        title: Text(widget.isArabic ? branch.nameAr : branch.nameEn),
                        leading: Icon(Icons.location_on),
                        onTap: () {
                          if (_mapController != null) {
                            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
                              LatLng(branch.latitude, branch.longitude),
                              15.0,
                            ));
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
