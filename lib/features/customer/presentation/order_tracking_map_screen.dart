import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingMapScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingMapScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingMapScreen> createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Delivery Tracking'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final double? lat = data['currentLatitude'];
          final double? lng = data['currentLongitude'];

          if (lat == null || lng == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Rider location not available yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final riderPosition = LatLng(lat, lng);

          // Animate camera to new position
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: riderPosition, zoom: 15.0),
              ),
            );
          }

          final Set<Marker> markers = {
            Marker(
              markerId: const MarkerId('rider'),
              position: riderPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
              infoWindow: const InfoWindow(title: 'Rider is here'),
            ),
          };

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: riderPosition,
              zoom: 15.0,
            ),
            markers: markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          );
        },
      ),
    );
  }
}
