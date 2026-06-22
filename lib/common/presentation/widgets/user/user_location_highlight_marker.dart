import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserLocationHighlightMarker extends StatelessWidget {
  const UserLocationHighlightMarker({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'You are here',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    const Shadow(color: Colors.black45, blurRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
