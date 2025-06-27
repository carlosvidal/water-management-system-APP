import 'package:flutter/material.dart';

class CameraReadingScreen extends StatelessWidget {
  final String unitId;
  final String periodId;

  const CameraReadingScreen({
    super.key,
    required this.unitId,
    required this.periodId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Reading'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Reading Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unit ID: $unitId',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            Text(
              'Period ID: $periodId',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}