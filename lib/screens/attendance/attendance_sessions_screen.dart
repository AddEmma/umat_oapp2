import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/member.dart';
import '../../models/attendance_record.dart';
import 'attendance_screen.dart';

class AttendanceSessionsScreen extends StatefulWidget {
  const AttendanceSessionsScreen({super.key});

  @override
  State<AttendanceSessionsScreen> createState() =>
      _AttendanceSessionsScreenState();
}

class _AttendanceSessionsScreenState extends State<AttendanceSessionsScreen> {
  bool _isExporting = false;
  String _selectedActivityFilter = 'All';
  DateTime? _selectedDateFilter;

  final List<String> _activityTypes = [
    'All',
    'Sunday Service',
    'Bible Study',
    'Prayer Meeting',
    'Youth Meeting',
    'Special Event',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildFilterSection()),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Provider.of<DatabaseService>(
              context,
            ).getAttendanceSessions(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
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
                          'Error loading sessions',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              // Apply filters
              List<Map<String, dynamic>> sessions = snapshot.data!;
              if (_selectedActivityFilter != 'All') {
                sessions = sessions
                    .where((s) => s['eventType'] == _selectedActivityFilter)
                    .toList();
              }
              if (_selectedDateFilter != null) {
                sessions = sessions.where((s) {
                  final sessionDate = s['date'] as DateTime;
                  return sessionDate.year == _selectedDateFilter!.year &&
                      sessionDate.month == _selectedDateFilter!.month &&
                      sessionDate.day == _selectedDateFilter!.day;
                }).toList();
              }

              if (sessions.isEmpty) {
                return _buildEmptyState(isFiltered: true);
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSessionCard(sessions[index]),
                    childCount: sessions.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
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
        'Attendance Lists',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Activity Filter
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedActivityFilter,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.grey[400],
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: _activityTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedActivityFilter = newValue);
                  }
                },
              ),
            ),
          ),
          Container(
            height: 20,
            width: 1,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Date Filter
          GestureDetector(
            onTap: _selectDateFilter,
            child: Row(
              children: [
                Icon(
                  _selectedDateFilter == null
                      ? Icons.calendar_today_rounded
                      : Icons.calendar_month_rounded,
                  size: 16,
                  color: _selectedDateFilter == null
                      ? Colors.grey[400]
                      : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedDateFilter == null
                      ? 'Select Date'
                      : DateFormat('MMM d, y').format(_selectedDateFilter!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selectedDateFilter == null
                        ? Colors.grey[600]
                        : Theme.of(context).primaryColor,
                  ),
                ),
                if (_selectedDateFilter != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDateFilter = null),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateFilter() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateFilter) {
      setState(() => _selectedDateFilter = picked);
    }
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final DateTime date = session['date'];
    final String eventType = session['eventType'];
    final int present = session['presentCount'];
    final int total = session['totalMembers'];
    final double percentage = total > 0 ? (present / total) : 0.0;

    return GestureDetector(
      onTap: () => _navigateToDetail(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getEventColor(eventType).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getEventIcon(eventType),
                        color: _getEventColor(eventType),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildExportButton(session),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    _buildStatItem('Present', '$present', Colors.green),
                    _buildStatItem('Total', '$total', Colors.blue),
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 5,
                            backgroundColor: Colors.grey[100],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getPercentageColor(percentage),
                            ),
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
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

  Widget _buildExportButton(Map<String, dynamic> session) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isAdmin && !authService.isEditor)
          return const SizedBox.shrink();

        return IconButton(
          icon: const Icon(
            Icons.ios_share_rounded,
            color: Colors.blueAccent,
            size: 22,
          ),
          onPressed: _isExporting ? null : () => _exportSession(session),
          tooltip: 'Export CSV',
        );
      },
    );
  }

  Future<void> _exportSession(Map<String, dynamic> session) async {
    setState(() => _isExporting = true);

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final DateTime date = session['date'];
      final String eventType = session['eventType'];

      // Get detailed records for this session
      final recordsMap = await databaseService.getAttendanceForDate(
        date,
        eventType,
      );
      final members = await databaseService.getMembers().first;

      String csvContent = _generateCSV(eventType, date, recordsMap, members);

      Directory directory;
      if (Platform.isAndroid) {
        directory =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      String sanitizedEventType = eventType.replaceAll(' ', '_');
      String fileName = 'attendance_${sanitizedEventType}_$formattedDate.csv';
      String filePath = '${directory.path}/$fileName';

      File file = File(filePath);
      await file.writeAsString(csvContent);

      _showExportSuccessDialog(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _generateCSV(
    String eventType,
    DateTime date,
    Map<String, AttendanceRecord> records,
    List<Member> members,
  ) {
    StringBuffer csv = StringBuffer();

    csv.writeln('Church Attendance Report');
    csv.writeln('Event Type,$eventType');
    csv.writeln('Date,${DateFormat('yyyy-MM-dd').format(date)}');
    csv.writeln(
      'Generated On,${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
    );
    csv.writeln('');

    int presentCount = records.values.where((r) => r.isPresent).length;
    int totalMembers = members.length;
    int absentCount = totalMembers - presentCount;
    double attendanceRate = totalMembers > 0
        ? (presentCount / totalMembers) * 100
        : 0;

    csv.writeln('SUMMARY');
    csv.writeln('Total Members,$totalMembers');
    csv.writeln('Present,$presentCount');
    csv.writeln('Absent,$absentCount');
    csv.writeln('Attendance Rate,${attendanceRate.toStringAsFixed(1)}%');
    csv.writeln('');

    csv.writeln('DETAILED ATTENDANCE');
    csv.writeln('Name,Ministry Role,Baptized,Present,Arrival Time,Status');

    for (Member member in members) {
      AttendanceRecord? record = records[member.id];
      String name = _escapeCSV(member.name);
      String role = _escapeCSV(member.ministryRole);
      String baptized = member.isBaptized ? 'Yes' : 'No';
      String present = (record?.isPresent ?? false) ? 'Yes' : 'No';
      String arrivalTime = record?.arrivalTime != null
          ? DateFormat('HH:mm:ss').format(record!.arrivalTime!)
          : 'N/A';
      String status = (record?.isPresent ?? false) ? 'Present' : 'Absent';

      csv.writeln('$name,$role,$baptized,$present,$arrivalTime,$status');
    }

    return csv.toString();
  }

  String _escapeCSV(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  void _showExportSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Complete'),
          content: const Text('Attendance data exported successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'Church Attendance Report');
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
                }
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.search_off_rounded : Icons.history_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No matches found' : 'No Attendance Lists Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedActivityFilter = 'All';
                    _selectedDateFilter = null;
                  });
                },
                child: const Text('Clear All Filters'),
              ),
            ],
          ],
        ),
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
      case 'Youth Meeting':
        return Icons.groups_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'Sunday Service':
        return Colors.blue;
      case 'Bible Study':
        return Colors.green;
      case 'Prayer Meeting':
        return Colors.purple;
      case 'Youth Meeting':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage > 0.8) return Colors.green;
    if (percentage > 0.5) return Colors.orange;
    return Colors.red;
  }

  void _navigateToDetail(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceSessionDetailScreen(
          date: session['date'],
          eventType: session['eventType'],
        ),
      ),
    );
  }
}

class AttendanceSessionDetailScreen extends StatelessWidget {
  final DateTime date;
  final String eventType;

  const AttendanceSessionDetailScreen({
    super.key,
    required this.date,
    required this.eventType,
  });

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceScreen(
                    initialDate: date,
                    initialEventType: eventType,
                  ),
                ),
              );
            },
            tooltip: 'Edit Attendance',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDetailHeader(context),
          Expanded(
            child: FutureBuilder<Map<String, AttendanceRecord>>(
              future: databaseService.getAttendanceForDate(date, eventType),
              builder: (context, recordsSnapshot) {
                if (recordsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!recordsSnapshot.hasData || recordsSnapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No records found for this session.'),
                  );
                }

                final records = recordsSnapshot.data!;

                return StreamBuilder<List<Member>>(
                  stream: databaseService.getMembers(),
                  builder: (context, membersSnapshot) {
                    if (membersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!membersSnapshot.hasData ||
                        membersSnapshot.data!.isEmpty) {
                      return const Center(child: Text('No members found.'));
                    }

                    final members = membersSnapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final record = records[member.id];
                        final isPresent = record?.isPresent ?? false;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: isPresent
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  backgroundImage:
                                      (member.photoUrl != null &&
                                          member.photoUrl!.isNotEmpty)
                                      ? NetworkImage(member.photoUrl!)
                                      : null,
                                  child:
                                      (member.photoUrl == null ||
                                          member.photoUrl!.isEmpty)
                                      ? Text(
                                          member.name.isNotEmpty
                                              ? member.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isPresent
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      isPresent ? Icons.check : Icons.close,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(member.ministryRole),
                            trailing: isPresent && record?.arrivalTime != null
                                ? Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(record!.arrivalTime!),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  )
                                : Text(
                                    isPresent ? 'Present' : 'Absent',
                                    style: TextStyle(
                                      color: isPresent
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventType,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.event_available_rounded,
            color: Colors.white,
            size: 48,
          ),
        ],
      ),
    );
  }
}
