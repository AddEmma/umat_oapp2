// screens/attendance/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
// ignore: unused_import
import 'dart:convert';
import '../../services/database_service.dart';
import '../../models/member.dart';
import '../../models/attendance_record.dart';
import 'attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  String _selectedEventType = 'Sunday Service';
  DateTime _selectedDate = DateTime.now();
  Map<String, AttendanceRecord> _attendanceRecords = {};
  bool _isLoading = false;
  bool _isExporting = false;
  List<Member> _currentMembers = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _eventTypes = [
    'Sunday Service',
    'Bible Study',
    'Prayer Meeting',
    'Youth Meeting',
    'Special Event',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadExistingAttendance();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceHistoryScreen(),
              ),
            ),
          ),
          IconButton(
            icon: _isExporting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.download_rounded, color: Colors.white, size: 20),
            onPressed: _isExporting ? null : _exportAttendance,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Compact Filters Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Event Type Filter
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedEventType,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          items: _eventTypes.map((String eventType) {
                            return DropdownMenuItem<String>(
                              value: eventType,
                              child: Row(
                                children: [
                                  Icon(
                                    _getEventIcon(eventType),
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      eventType,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedEventType = newValue);
                              _loadExistingAttendance();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),

                  // Date Filter
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('MMM d, yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Content
            Expanded(
              child: StreamBuilder<List<Member>>(
                stream: Provider.of<DatabaseService>(context).getMembers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
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
                  _currentMembers = members;
                  return _buildAttendanceContent(members);
                },
              ),
            ),

            // Save Button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Attendance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceContent(List<Member> members) {
    int presentCount = _attendanceRecords.values
        .where((r) => r.isPresent)
        .length;
    int absentCount = members.length - presentCount;

    return Column(
      children: [
        // Compact Summary
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildStatItem('Total', members.length.toString(), Colors.blue),
              _buildStatItem('Present', presentCount.toString(), Colors.green),
              _buildStatItem('Absent', absentCount.toString(), Colors.orange),
            ],
          ),
        ),

        // Member List
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Member',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Arrival Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Present',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Member List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final attendanceRecord = _attendanceRecords[member.id];
                      return _buildMemberRow(member, attendanceRecord);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMemberRow(Member member, AttendanceRecord? record) {
    final isPresent = record?.isPresent ?? false;
    final arrivalTime = record?.arrivalTime;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.withOpacity(0.03) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Member Info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: member.isBaptized
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: member.isBaptized
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (member.ministryRole.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          member.ministryRole,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Arrival Time
          Expanded(
            flex: 2,
            child: Text(
              arrivalTime != null
                  ? DateFormat('h:mm a').format(arrivalTime)
                  : '--:--',
              style: TextStyle(
                fontSize: 11,
                color: arrivalTime != null
                    ? Colors.green[700]
                    : Colors.grey[400],
                fontWeight: arrivalTime != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Checkbox
          Expanded(
            flex: 1,
            child: Center(
              child: Checkbox(
                value: isPresent,
                onChanged: (bool? value) {
                  _toggleAttendance(member.id, value ?? false);
                },
                activeColor: Colors.green,
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
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
      case 'Youth Meeting':
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

  Future<void> _exportAttendance() async {
    setState(() => _isExporting = true);

    try {
      String csvContent = await _generateCSVContent();

      // Use app-specific directory that doesn't require permissions
      Directory directory;
      if (Platform.isAndroid) {
        // For Android: Use app-specific external directory
        directory =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        // For iOS: Use documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      String sanitizedEventType = _selectedEventType.replaceAll(' ', '_');
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

  Future<String> _generateCSVContent() async {
    StringBuffer csv = StringBuffer();

    csv.writeln('Church Attendance Report');
    csv.writeln('Event Type,${_selectedEventType}');
    csv.writeln('Date,${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
    csv.writeln(
      'Generated On,${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
    );
    csv.writeln('');

    int presentCount = _attendanceRecords.values
        .where((r) => r.isPresent)
        .length;
    int totalMembers = _currentMembers.length;
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

    for (Member member in _currentMembers) {
      AttendanceRecord? record = _attendanceRecords[member.id];
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
          title: Text('Export Complete'),
          content: Text('Attendance data exported successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
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
              child: Text('Share'),
            ),
          ],
        );
      },
    );
  }
}
