import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/church.dart';
import '../../services/auth_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/migration_service.dart';

class ChurchSelectionScreen extends StatefulWidget {
  const ChurchSelectionScreen({super.key});

  @override
  State<ChurchSelectionScreen> createState() => _ChurchSelectionScreenState();
}

class _ChurchSelectionScreenState extends State<ChurchSelectionScreen> {
  bool _isCreating = false; // Toggle between Create and Join
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Create Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  // Join Controller
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateChurch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final migrationService = MigrationService();

    try {
      // Create fresh church (NO legacy data migration)
      await migrationService.performMigration(
        _nameController.text.trim(),
        _addressController.text.trim(),
        includeLegacyData: false,
      );

      // MigrationService updates the user's churchId, so AppWrapper will handle the redirect
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoinChurch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) return;

    try {
      final code = _codeController.text.trim().toUpperCase();
      final church = await dbService.getChurchByCode(code);

      if (church == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid Church Code')));
        }
        return;
      }

      await dbService.joinChurch(user.uid, church.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.church_rounded,
                  size: 64,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 24),
                Text(
                  _isCreating ? 'Start a New Church' : 'Join a Church',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isCreating
                      ? 'Register your ministry to manage members and attendance.'
                      : 'Enter the 6-character code provided by your admin.',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (_isCreating) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Church Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Church Code',
                      hintText: 'e.g. ABC123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        v!.length < 6 ? 'Invalid code length' : null,
                  ),
                ],

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isCreating ? _handleCreateChurch : _handleJoinChurch),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isCreating ? 'Create Church' : 'Join Church'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCreating = !_isCreating;
                      _formKey.currentState!.reset();
                    });
                  },
                  child: Text(
                    _isCreating
                        ? 'Have a code? Join a church instead'
                        : 'Need to register a new church?',
                    style: const TextStyle(color: Colors.indigo),
                  ),
                ),
                // Logout option in case they are stuck
                TextButton(
                  onPressed: () => Provider.of<AuthService>(
                    context,
                    listen: false,
                  ).signOut(),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
