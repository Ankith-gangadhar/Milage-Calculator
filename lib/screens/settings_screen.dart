import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/neon_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _importBackup(BuildContext context, VehicleProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        final success = await provider.importData(content);
        if (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup restored successfully!'),
                backgroundColor: NeonColors.secondary,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to parse backup file. Invalid format.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VehicleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Preferences and local backups",
                      style: TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(LucideIcons.settings, color: NeonColors.secondary, size: 24),
              ],
            ),
            const SizedBox(height: 28),

            // Theme Settings Card
            NeonCard(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              borderRadius: 16.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.moon, color: NeonColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dark Theme",
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Toggle dark neon aesthetics",
                            style: TextStyle(color: NeonColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: provider.isDarkMode,
                    activeColor: NeonColors.secondary,
                    activeTrackColor: NeonColors.primary.withOpacity(0.5),
                    inactiveThumbColor: NeonColors.textSecondary,
                    inactiveTrackColor: Colors.black12,
                    onChanged: (val) {
                      provider.toggleTheme();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Backup & Restore Block Title
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                "Backup & Restore",
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Export Backup Card
            NeonCard(
              onTap: () async {
                try {
                  await provider.exportData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to export data: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              padding: const EdgeInsets.all(16.0),
              borderRadius: 16.0,
              child: const Row(
                children: [
                  Icon(LucideIcons.download, color: NeonColors.secondary, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Export Data as JSON",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Generates and shares a local database backup file",
                          style: TextStyle(color: NeonColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: NeonColors.textSecondary, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Import Backup Card
            NeonCard(
              onTap: () => _importBackup(context, provider),
              padding: const EdgeInsets.all(16.0),
              borderRadius: 16.0,
              child: const Row(
                children: [
                  Icon(LucideIcons.upload, color: NeonColors.secondary, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Import Data from JSON",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Restores vehicles and refills from a backup file",
                          style: TextStyle(color: NeonColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: NeonColors.textSecondary, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer / Version
            Center(
              child: Column(
                children: [
                  Text(
                    "Mileage Calculator v1.0.0",
                    style: TextStyle(color: NeonColors.textSecondary.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Offline-only Secure Storage",
                    style: TextStyle(color: NeonColors.textSecondary.withOpacity(0.3), fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
