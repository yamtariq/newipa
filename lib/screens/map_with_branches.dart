import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

class MapWithBranchesScreen extends StatefulWidget {
  final bool isArabic;

  MapWithBranchesScreen({required this.isArabic});

  @override
  _MapWithBranchesScreenState createState() => _MapWithBranchesScreenState();
}

class _MapWithBranchesScreenState extends State<MapWithBranchesScreen> {
  final BranchService _branchService = BranchService();
  List<Branch> branches = [];
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
          ),
        ));
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? "خريطة الفروع" : "Branches Map"),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: branches.isNotEmpty 
                          ? LatLng(branches[0].latitude, branches[0].longitude)
                          : LatLng(24.7136, 46.6753), // Default to Riyadh if no branches
                      zoom: 6,
                    ),
                    mapType: MapType.normal,
                    markers: _markers,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                    compassEnabled: true,
                    buildingsEnabled: true,
                    indoorViewEnabled: true,
                    trafficEnabled: false,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    tiltGesturesEnabled: true,
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
