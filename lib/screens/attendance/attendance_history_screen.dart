// screens/attendance/attendance_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/member.dart';
import '../../models/attendance_record.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  _AttendanceHistoryScreenState createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _selectedEventType = 'All';
  String _selectedTimeFrame = '30 Days';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Cache for members to avoid repeated queries
  Map<String, Member> _membersCache = {};
  bool _membersLoaded = false;

  final List<String> _eventTypes = [
    'All',
    'Sunday Service',
    'Bible Study',
    'Prayer Meeting',
    'Songs Practice',
    
  ];

  final List<String> _timeFrames = [
    '7 Days',
    '30 Days',
    '90 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _setDateRange();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load and cache all members
  void _loadMembers() async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final members = await databaseService.getMembers().first;

      setState(() {
        _membersCache = {for (var member in members) member.id: member};
        _membersLoaded = true;
      });
    } catch (e) {
      print('Error loading members: $e');
      setState(() => _membersLoaded = true);
    }
  }

  void _setDateRange() {
    DateTime now = DateTime.now();
    switch (_selectedTimeFrame) {
      case '7 Days':
        _startDate = now.subtract(Duration(days: 7));
        _endDate = now;
        break;
      case '30 Days':
        _startDate = now.subtract(Duration(days: 30));
        _endDate = now;
        break;
      case '90 Days':
        _startDate = now.subtract(Duration(days: 90));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Last Month':
        DateTime lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(now.year, now.month, 1).subtract(Duration(days: 1));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filters Section
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
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 13),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                SizedBox(height: 12),

                // Filter Row
                Row(
                  children: [
                    // Event Type Filter
                    Expanded(
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
                            icon: Icon(Icons.keyboard_arrow_down, size: 18),
                            isExpanded: true,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                            items: _eventTypes.map((String eventType) {
                              return DropdownMenuItem<String>(
                                value: eventType,
                                child: Text(eventType),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedEventType = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Time Frame Filter
                    Expanded(
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
                            value: _selectedTimeFrame,
                            icon: Icon(Icons.keyboard_arrow_down, size: 18),
                            isExpanded: true,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                            items: _timeFrames.map((String timeFrame) {
                              return DropdownMenuItem<String>(
                                value: timeFrame,
                                child: Text(timeFrame),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedTimeFrame = newValue;
                                  if (newValue != 'Custom Range') {
                                    _setDateRange();
                                  } else {
                                    _showCustomDatePicker();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Show selected date range for custom range
                if (_selectedTimeFrame == 'Custom Range' &&
                    _startDate != null &&
                    _endDate != null)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Attendance Records Table
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
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
                  // Table Header
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
                            'Name',
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
                            'Time',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Event Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Date',
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
                            'Status',
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

                  // Table Body
                  Expanded(child: _buildAttendanceTable()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    if (!_membersLoaded) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return StreamBuilder<List<AttendanceRecord>>(
      stream: Provider.of<DatabaseService>(context).getAttendanceRecords(
        eventType: _selectedEventType == 'All' ? null : _selectedEventType,
        startDate: _startDate,
        endDate: _endDate,
      ),
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

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        List<AttendanceRecord> records = snapshot.data!;

        // Filter by event type in memory to avoid index requirements
        if (_selectedEventType != 'All') {
          records = records
              .where((record) => record.eventType == _selectedEventType)
              .toList();
        }

        // Filter records based on search query
        if (_searchQuery.isNotEmpty) {
          records = records.where((record) {
            final memberName = _getMemberName(record.memberId);
            return memberName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();
        }

        // Sort records by date (newest first)
        records.sort((a, b) => b.date.compareTo(a.date));

        if (records.isEmpty) {
          return _buildEmptyState(isFiltered: true);
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: records.length,
          itemBuilder: (context, index) {
            return _buildTableRow(records[index], index);
          },
        );
      },
    );
  }

  Widget _buildTableRow(AttendanceRecord record, int index) {
    final member = _membersCache[record.memberId];
    final memberName = member?.name ?? 'Unknown Member';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: record.isPresent
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                  child: Icon(
                    record.isPresent ? Icons.check : Icons.close,
                    size: 14,
                    color: record.isPresent
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    memberName,
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

          // Time
          Expanded(
            flex: 2,
            child: Text(
              record.arrivalTime != null
                  ? DateFormat('h:mm a').format(record.arrivalTime!)
                  : '--:--',
              style: TextStyle(
                fontSize: 12,
                color: record.arrivalTime != null
                    ? Colors.grey[800]
                    : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Event Type
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getEventColor(record.eventType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.eventType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getEventColor(record.eventType),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM d').format(record.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),

          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: record.isPresent
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.isPresent ? 'P' : 'A',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: record.isPresent
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
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
            child: Icon(
              isFiltered ? Icons.search_off : Icons.history,
              size: 48,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          Text(
            isFiltered ? 'No Matching Records' : 'No Records Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try adjusting your search or filters'
                : 'No attendance records available for the selected period',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedEventType = 'All';
                  _selectedTimeFrame = '30 Days';
                  _setDateRange();
                });
              },
              icon: Icon(Icons.clear_all, size: 18),
              label: Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMemberName(String memberId) {
    return _membersCache[memberId]?.name ?? 'Unknown Member';
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'Sunday Service':
        return Colors.blue;
      case 'Bible Study':
        return Colors.green;
      case 'Prayer Meeting':
        return Colors.purple;
      case 'Songs Practice':
        return Colors.orange;
      case 'Special Event':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCustomDatePicker() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
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

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
