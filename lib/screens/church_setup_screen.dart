import 'package:flutter/material.dart';
import '../../services/migration_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class ChurchSetupScreen extends StatefulWidget {
  const ChurchSetupScreen({super.key});

  @override
  State<ChurchSetupScreen> createState() => _ChurchSetupScreenState();
}

class _ChurchSetupScreenState extends State<ChurchSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  final MigrationService _migrationService = MigrationService();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _performSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _migrationService.performMigration(
        _nameController.text.trim(),
        _addressController.text.trim(),
      );

      // Force refresh of auth/church state
      if (mounted) {
        // Reload user to get updated claims/custom fields if any,
        // though here we rely on Firestore listener in AuthService
        // The migration updated the user doc, so AuthService should pick it up automatically

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Church created and data migrated successfully!'),
          ),
        );

        // Navigate back or to dashboard
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Church Space')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.church_rounded, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Upgrade to Church Space',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Create a dedicated space for your church. Your existing data (Members, Attendance, etc.) will be moved into this new space automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Church Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Location / Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _performSetup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create & Migrate Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
