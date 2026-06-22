import 'package:flutter/material.dart';

class GpsUserLocationMarker extends StatelessWidget {
  const GpsUserLocationMarker({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
