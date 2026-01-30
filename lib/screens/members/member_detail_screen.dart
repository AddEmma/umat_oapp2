import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/member.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/full_screen_image_viewer.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;
  final Function(Member)? onMemberUpdated;

  const MemberDetailScreen({
    super.key,
    required this.member,
    this.onMemberUpdated,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  late ScrollController _scrollController;
  bool _isScrolled = false;
  bool _isDisposed = false; // Add disposal flag
  bool _isUpdatingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  // Store current member state locally
  late Member _currentMember;

  @override
  void initState() {
    super.initState();

    // Initialize local member state
    _currentMember = widget.member;

    _scrollController = ScrollController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _scrollController.addListener(_handleScroll);
    _animationController.forward();

    // Check for lost data from image picker
    _checkLostData();

    // Delay FAB animation with safety check
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_isDisposed) _fabAnimationController.forward();
    });
  }

  void _handleScroll() {
    if (!mounted || _isDisposed) return;

    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // Set disposal flag first

    // Remove listener before disposing
    _scrollController.removeListener(_handleScroll);

    // Dispose controllers safely
    try {
      _scrollController.dispose();
      _animationController.dispose();
      _fabAnimationController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileSection(),
                        const SizedBox(height: 24),
                        _buildContactCard(),
                        const SizedBox(height: 16),
                        _buildAcademicCard(),
                        const SizedBox(height: 16),
                        _buildMinistryCard(),
                        const SizedBox(height: 80), // Space for FAB
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Provider.of<AuthService>(context).canEdit
          ? ScaleTransition(
              scale: _fabScaleAnimation,
              child: FloatingActionButton(
                heroTag: "edit",
                onPressed: _isDisposed ? null : () => _showEditDialog(),
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _isScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            _currentMember.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _isDisposed
                ? null
                : (value) => _handleMenuAction(value),
            itemBuilder: (context) {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              return [
                if (authService.canEdit)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 12),
                        Text('Edit Member'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 12),
                      Text('Share Contact'),
                    ],
                  ),
                ),
                if (authService.canEdit)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Delete Member',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap:
                    (_currentMember.photoUrl != null &&
                        _currentMember.photoUrl!.isNotEmpty)
                    ? () {
                        FullScreenImageViewer.show(
                          context,
                          imageUrl: _currentMember.photoUrl!,
                          heroTag: 'member_photo_${_currentMember.id}',
                          title: _currentMember.name,
                        );
                      }
                    : null,
                child: Hero(
                  tag: 'member_photo_${_currentMember.id}',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            (_currentMember.isBaptized
                                    ? Colors.green
                                    : Colors.orange)
                                .withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_currentMember.isBaptized
                                      ? Colors.green
                                      : Colors.orange)
                                  .withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor:
                          (_currentMember.isBaptized
                                  ? Colors.green
                                  : Colors.orange)
                              .withValues(alpha: 0.1),
                      backgroundImage:
                          (_currentMember.photoUrl != null &&
                              _currentMember.photoUrl!.isNotEmpty)
                          ? NetworkImage(_currentMember.photoUrl!)
                          : null,
                      child: _isUpdatingPhoto
                          ? const CircularProgressIndicator()
                          : (_currentMember.photoUrl == null ||
                                _currentMember.photoUrl!.isEmpty)
                          ? Text(
                              _currentMember.name.isNotEmpty
                                  ? _currentMember.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: _currentMember.isBaptized
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (Provider.of<AuthService>(context, listen: false).canEdit)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _isUpdatingPhoto
                        ? null
                        : () => _updateProfileImage(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUpdatingPhoto
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              if (_currentMember.isBaptized)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _currentMember.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _currentMember.isBaptized
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _currentMember.isBaptized ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Text(
              _currentMember.isBaptized
                  ? 'BAPTIZED MEMBER'
                  : 'UNBAPTIZED PUBLISHER',
              style: TextStyle(
                color: _currentMember.isBaptized ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _buildInfoCard(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      color: Colors.blue,
      children: [
        // _buildContactRow(
        //   'Email',
        //   _currentMember.email.isEmpty ? 'Not provided' : _currentMember.email,
        //   Icons.email,
        //   onTap: _currentMember.email.isNotEmpty ? () => _launchEmail() : null,
        // ),
        const SizedBox(height: 16),
        _buildContactRow(
          'Phone',
          _currentMember.phone.isEmpty ? 'Not provided' : _currentMember.phone,
          Icons.phone,
          onTap: _currentMember.phone.isNotEmpty ? () => _launchPhone() : null,
        ),
      ],
    );
  }

  Widget _buildAcademicCard() {
    return _buildInfoCard(
      title: 'Academic Information',
      icon: Icons.school,
      color: Colors.purple,
      children: [
        _buildInfoRow(
          'Year',
          _currentMember.year.isEmpty ? 'Not specified' : _currentMember.year,
          Icons.grade,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Department',
          _currentMember.department.isEmpty
              ? 'Not specified'
              : _currentMember.department,
          Icons.business,
        ),
      ],
    );
  }

  Widget _buildMinistryCard() {
    return _buildInfoCard(
      title: 'Ministry Information',
      icon: Icons.work,
      color: Colors.teal,
      children: [
        _buildInfoRow(
          'Role',
          _currentMember.ministryRole.isEmpty
              ? 'Not assigned'
              : _currentMember.ministryRole,
          Icons.assignment_ind,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Date Added',
          DateFormat('MMMM dd, yyyy').format(_currentMember.dateAdded),
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactRow(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: value.contains('Not')
                          ? Colors.grey[400]
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: value.contains('Not')
                      ? Colors.grey[400]
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog() {
    if (_isDisposed || !mounted) return;

    // Create controllers for the text fields
    final nameController = TextEditingController(text: _currentMember.name);
    // final emailController = TextEditingController(text: _currentMember.email);
    final phoneController = TextEditingController(text: _currentMember.phone);
    final yearController = TextEditingController(text: _currentMember.year);
    final departmentController = TextEditingController(
      text: _currentMember.department,
    );
    final ministryRoleController = TextEditingController(
      text: _currentMember.ministryRole,
    );
    bool isBaptized = _currentMember.isBaptized;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Edit Member'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // TextField(
                    //   controller: emailController,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Email',
                    //     border: OutlineInputBorder(),
                    //   ),
                    //   keyboardType: TextInputType.emailAddress,
                    // ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ministryRoleController,
                      decoration: const InputDecoration(
                        labelText: 'Ministry Role',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isBaptized,
                          onChanged: (value) {
                            setDialogState(() {
                              isBaptized = value ?? false;
                            });
                          },
                        ),
                        const Text('Baptized Member'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Dispose controllers synchronously
                    try {
                      _safeDisposeControllers([
                        nameController,
                        // emailController,
                        phoneController,
                        yearController,
                        departmentController,
                        ministryRoleController,
                      ]);
                    } catch (e) {
                      debugPrint('Error disposing controllers: $e');
                    }

                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      // Update member with new data
                      _updateMember(
                        name: nameController.text,
                        // email: emailController.text,
                        phone: phoneController.text,
                        year: yearController.text,
                        department: departmentController.text,
                        ministryRole: ministryRoleController.text,
                        isBaptized: isBaptized,
                      );

                      // Dispose controllers synchronously
                      _safeDisposeControllers([
                        nameController,
                        // emailController,
                        phoneController,
                        yearController,
                        departmentController,
                        ministryRoleController,
                      ]);

                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (e) {
                      debugPrint('Error in save action: $e');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _safeDisposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      try {
        if (!controller.hasListeners) {
          controller.dispose();
        }
      } catch (e) {
        debugPrint('Error disposing controller: $e');
      }
    }
  }

  // Updated _updateMember method in MemberDetailScreen
  void _updateMember({
    required String name,
    // required String email,
    required String phone,
    required String year,
    required String department,
    required String ministryRole,
    required bool isBaptized,
  }) async {
    try {
      // Check if widget is still mounted and not disposed
      if (!mounted || _isDisposed) return;

      // Validate input data
      if (name.trim().isEmpty) {
        _showErrorSnackBar('Name cannot be empty');
        return;
      }

      // Create updated member
      final updatedMember = _currentMember.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        year: year.trim(),
        department: department.trim(),
        ministryRole: ministryRole.trim(),
        isBaptized: isBaptized,
      );

      debugPrint('Updating member: ${updatedMember.name}');

      // Update in database - Get the database service
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      await databaseService.updateMember(updatedMember);

      // Update local state safely
      if (mounted && !_isDisposed) {
        setState(() {
          _currentMember = updatedMember;
        });

        // Show success message
        _showSuccessSnackBar('Member updated successfully!');

        // Call the callback safely - this will notify the parent screen
        if (widget.onMemberUpdated != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isDisposed) {
              widget.onMemberUpdated!(updatedMember);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating member: $e');
      if (mounted && !_isDisposed) {
        _showErrorSnackBar('Failed to update member: ${e.toString()}');
      }
    }
  }

  Future<void> _checkLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      _uploadAndSetPhoto(response.file!);
    } else {
      debugPrint('Lost data error: ${response.exception?.code}');
    }
  }

  Future<void> _uploadAndSetPhoto(XFile pickedFile) async {
    if (!mounted || _isDisposed) return;

    setState(() => _isUpdatingPhoto = true);

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      // Upload image
      final photoUrl = await databaseService.uploadProfileImage(
        _currentMember.id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : _currentMember.id,
        File(pickedFile.path),
      );

      // Update member
      final updatedMember = _currentMember.copyWith(photoUrl: photoUrl);
      await databaseService.updateMember(updatedMember);

      if (mounted && !_isDisposed) {
        setState(() {
          _currentMember = updatedMember;
          _isUpdatingPhoto = false;
        });

        _showSuccessSnackBar('Profile picture updated!');

        if (widget.onMemberUpdated != null) {
          widget.onMemberUpdated!(updatedMember);
        }
      }
    } catch (e) {
      debugPrint('Error uploading lost photo: $e');
      if (mounted && !_isDisposed) {
        setState(() => _isUpdatingPhoto = false);
        _showErrorSnackBar('Failed to upload profile picture');
      }
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null || !mounted || _isDisposed) return;

      _uploadAndSetPhoto(pickedFile);
    } catch (e) {
      debugPrint('Error updated profile picture: $e');
      if (mounted && !_isDisposed) {
        setState(() => _isUpdatingPhoto = false);
        _showErrorSnackBar('Failed to update profile picture');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    if (_isDisposed || !mounted) return;

    switch (action) {
      case 'edit':
        _showEditDialog();
        break;
      case 'share':
        _shareContact();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _shareContact() async {
    if (_isDisposed || !mounted) return;

    try {
      final contactInfo = StringBuffer();
      contactInfo.writeln(_currentMember.name);
      contactInfo.writeln();

      if (_currentMember.phone.isNotEmpty) {
        contactInfo.writeln('📞 Phone: ${_currentMember.phone}');
      }
      if (_currentMember.department.isNotEmpty) {
        contactInfo.writeln('🏢 Department: ${_currentMember.department}');
      }
      if (_currentMember.year.isNotEmpty) {
        contactInfo.writeln('📅 Year: ${_currentMember.year}');
      }
      if (_currentMember.ministryRole.isNotEmpty) {
        contactInfo.writeln('⛪ Ministry Role: ${_currentMember.ministryRole}');
      }

      await SharePlus.instance.share(
        ShareParams(
          text: contactInfo.toString().trim(),
          subject: 'Contact: ${_currentMember.name}',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing contact: $e');
      // Fallback to clipboard if share fails
      try {
        final contactInfo =
            '${_currentMember.name}\nPhone: ${_currentMember.phone}';
        Clipboard.setData(ClipboardData(text: contactInfo));
        _showSuccessSnackBar('Contact copied to clipboard');
      } catch (_) {
        _showErrorSnackBar('Failed to share contact information');
      }
    }
  }

  void _showDeleteDialog() {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete Member'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete ${_currentMember.name}?',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isDeleting) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);

                          try {
                            final databaseService =
                                Provider.of<DatabaseService>(
                                  context,
                                  listen: false,
                                );

                            await databaseService.deleteMember(
                              _currentMember.id,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (mounted && !_isDisposed) {
                              _showSuccessSnackBar(
                                '${_currentMember.name} has been deleted',
                              );
                              // Navigate back to members list
                              Navigator.of(this.context).pop();
                            }
                          } catch (e) {
                            debugPrint('Error deleting member: $e');
                            setDialogState(() => isDeleting = false);
                            if (mounted && !_isDisposed) {
                              _showErrorSnackBar('Failed to delete member: $e');
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // void _launchEmail() {
  //   if (_isDisposed || !mounted) return;
  //   _showSuccessSnackBar('Opening email to ${_currentMember.email}');
  // }

  void _launchPhone() async {
    if (_isDisposed || !mounted) return;
    if (_currentMember.phone.isEmpty) {
      _showErrorSnackBar('No phone number provided');
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: _currentMember.phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
}
