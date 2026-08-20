import 'package:flutter/material.dart';

/// Placeholder untuk fitur Tier 2/3 yang belum ada endpoint API-nya —
/// lihat docs/96_perencanaan_mobile_app_owner.md §4 (Utility/PBB/P3SRS
/// masih di sisi "belum diprioritaskan"/butuh keputusan scope §2).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                description ?? 'Fitur ini segera hadir.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
