import 'package:flutter/material.dart';
import '../companion_cubit.dart';
import '../companion_page.dart';

class CompanionLoadingScreen extends StatelessWidget {
  const CompanionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Colors.white));
}

class CompanionErrorScreen extends StatelessWidget {
  final CompanionCubit cubit;
  final String? message;

  const CompanionErrorScreen({super.key, required this.cubit, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(message ?? 'Lỗi không xác định', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kGreenAccent),
              onPressed: () => cubit.clearFeedback(),
              child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}