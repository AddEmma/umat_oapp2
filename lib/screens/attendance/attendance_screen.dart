// screens/attendance/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// ignore: unused_import
import 'dart:convert';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/member.dart';
import '../../models/attendance_record.dart';
import 'attendance_sessions_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialEventType;

  const AttendanceScreen({super.key, this.initialDate, this.initialEventType});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedEventType = 'Sunday Service';
  DateTime _selectedDate = DateTime.now();
  Map<String, AttendanceRecord> _attendanceRecords = {};
  bool _isLoading = false;
  bool _showAbsenteesOnly = false;

  // Search and Selection
  bool _hasUnsavedChanges = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _eventTypes = [
    'Sunday Service',
    'Bible Study',
    'Prayer Meeting',
    'Songs Practice',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialEventType != null) {
      _selectedEventType = widget.initialEventType!;
    }
    _loadExistingAttendance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadExistingAttendance() async {
    setState(() => _isLoading = true);

    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final existingRecords = await databaseService.getAttendanceForDate(
      _selectedDate,
      _selectedEventType,
    );

    setState(() {
      _attendanceRecords = existingRecords;
      _isLoading = false;
    });
  }

  void _bulkMarkAttendance(List<Member> members, bool isPresent) {
    setState(() {
      for (var member in members) {
        _toggleAttendance(member.id, isPresent);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Unsaved Changes'),
            content: Text(
              'You have unsaved attendance changes. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.03),
                Colors.white,
                Theme.of(context).primaryColor.withOpacity(0.01),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Modern App Bar
                    _buildSliverAppBar(context),

                    // Filter Card
                    SliverToBoxAdapter(child: _buildFilterCard()),

                    // Attendance Content
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: StreamBuilder<List<Member>>(
                        stream: Provider.of<DatabaseService>(
                          context,
                        ).getMembers(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Error loading members',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          }

                          List<Member> members = snapshot.data!;
                          return _buildAttendanceContent(members);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Save Panel
              _buildBottomActionPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Take Attendance',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.history_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceSessionsScreen(),
            ),
          ),
          tooltip: 'History',
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Absentees Filter Chip
                FilterChip(
                  label: Text(
                    'Show Absentees',
                    style: TextStyle(
                      color: _showAbsenteesOnly ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                  selected: _showAbsenteesOnly,
                  onSelected: (bool selected) {
                    setState(() {
                      _showAbsenteesOnly = selected;
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.red[400],
                  checkmarkColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),

                // Event Type Picker (Using GestureDetector as before or FilterChip style)
                GestureDetector(
                  onTap: () => _showEventTypePicker(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEventIcon(_selectedEventType),
                          color: Theme.of(context).primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedEventType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Date Picker
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEventTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Event Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._eventTypes
                  .map(
                    (type) => ListTile(
                      leading: Icon(
                        _getEventIcon(type),
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        type,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: _selectedEventType == type
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedEventType = type);
                        _loadExistingAttendance();
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasUnsavedChanges)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange[700],
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'You have unsaved changes',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (!authService.canEdit || _isLoading)
                      ? null
                      : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Attendance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent(List<Member> members) {
    int presentCount = _attendanceRecords.values
        .where((r) => r.isPresent)
        .length;
    int absentCount = members.length - presentCount;
    double presentPercentage = members.isNotEmpty
        ? presentCount / members.length
        : 0.0;

    // Filter members based on search query
    // Filter members based on search query
    List<Member> filteredMembers = members.where((member) {
      // 1. Filter out Alumni/Graduate
      if (member.year.toLowerCase().contains('alumni') ||
          member.year.toLowerCase().contains('graduate')) {
        return false;
      }

      // 2. Filter by Search Query
      if (_searchQuery.isNotEmpty &&
          !member.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // 3. Filter by Absentees Only
      if (_showAbsenteesOnly) {
        final isAbsent = !(_attendanceRecords[member.id]?.isPresent ?? false);
        if (!isAbsent) return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        // Summary Stats Card
        _buildSummaryCard(
          members.length,
          presentCount,
          absentCount,
          presentPercentage,
        ),

        // Search and Bulk Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              Consumer<AuthService>(
                builder: (context, authService, _) {
                  if (!authService.canEdit) return const SizedBox.shrink();

                  bool isAllSelected =
                      filteredMembers.isNotEmpty &&
                      filteredMembers.every(
                        (m) => _attendanceRecords[m.id]?.isPresent ?? false,
                      );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: isAllSelected,
                            onChanged: (val) => _bulkMarkAttendance(
                              filteredMembers,
                              val ?? false,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mark All Present',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isAllSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        if (_attendanceRecords.values.any((r) => r.isPresent))
                          TextButton(
                            onPressed: () =>
                                _bulkMarkAttendance(filteredMembers, false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Colors.grey[600],
                            ),
                            child: const Text(
                              'Reset All',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Member List Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Text(
                'MEMBERS (${filteredMembers.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'ARRIVAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 45),
              Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        // Member List
        ...filteredMembers.map((member) {
          final attendanceRecord = _attendanceRecords[member.id];
          return _buildMemberRow(member, attendanceRecord);
        }).toList(),

        const SizedBox(height: 100), // Bottom spacing
      ],
    );
  }

  Widget _buildSummaryCard(
    int total,
    int present,
    int absent,
    double percentage,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Summary',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatMiniItem('Total', '$total', Colors.blue),
                    _buildStatMiniItem('Present', '$present', Colors.green),
                    _buildStatMiniItem('Absent', '$absent', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(Member member, AttendanceRecord? record) {
    final isPresent = record?.isPresent ?? false;
    final arrivalTime = record?.arrivalTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresent ? Colors.green.withOpacity(0.2) : Colors.grey[100]!,
          width: 1.5,
        ),
        boxShadow: [
          if (isPresent)
            BoxShadow(
              color: Colors.green.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Member Info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: member.isBaptized
                          ? [Colors.green[400]!, Colors.green[600]!]
                          : [Colors.orange[300]!, Colors.orange[500]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (member.isBaptized ? Colors.green : Colors.orange)
                                .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_showAbsenteesOnly) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 10,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.phone,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ] else if (member.ministryRole.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.ministryRole,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_showAbsenteesOnly) ...[
            // Absentee Details: Hostel
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.home, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      member.hostel.isNotEmpty ? member.hostel : 'No Hostel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ] else ...[
            // Normal View: Arrival Time & Checkbox
            Expanded(
              flex: 2,
              child: Text(
                arrivalTime != null
                    ? DateFormat('h:mm a').format(arrivalTime)
                    : '--:--',
                style: TextStyle(
                  fontSize: 12,
                  color: arrivalTime != null
                      ? Colors.green[700]
                      : Colors.grey[400],
                  fontWeight: arrivalTime != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Checkbox for Attendance
            Expanded(
              flex: 1,
              child: Center(
                child: Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: isPresent,
                        onChanged: authService.canEdit
                            ? (bool? value) =>
                                  _toggleAttendance(member.id, value ?? false)
                            : null,
                        activeColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_rounded, size: 48, color: Colors.grey),
          ),
          SizedBox(height: 16),
          Text(
            'No Members Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add members to start taking attendance',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'Sunday Service':
        return Icons.church_rounded;
      case 'Bible Study':
        return Icons.book_rounded;
      case 'Prayer Meeting':
        return Icons.favorite_rounded;
      case 'Songs Practice':
        return Icons.groups_rounded;
      case 'Special Event':
        return Icons.event_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  void _toggleAttendance(String memberId, bool isPresent) {
    setState(() {
      if (isPresent) {
        _attendanceRecords[memberId] = AttendanceRecord(
          memberId: memberId,
          eventType: _selectedEventType,
          date: _selectedDate,
          isPresent: true,
          arrivalTime: DateTime.now(),
        );
      } else {
        _attendanceRecords[memberId] = AttendanceRecord(
          memberId: memberId,
          eventType: _selectedEventType,
          date: _selectedDate,
          isPresent: false,
          arrivalTime: null,
        );
      }
    });
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadExistingAttendance();
    }
  }

  void _saveAttendance() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      for (final record in _attendanceRecords.values) {
        await databaseService.saveAttendanceRecord(record);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
