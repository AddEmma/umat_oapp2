// screens/meetings/meetings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:umat_srid_oapp/services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/meeting.dart';
import 'create_meeting_screen.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  _MeetingsScreenState createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Meetings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: StreamBuilder<List<Meeting>>(
        stream: Provider.of<DatabaseService>(context).getMeetings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading meetings...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildEmptyState(
                  'No upcoming meetings',
                  'Schedule your first meeting to get started',
                  Icons.event_available,
                  Colors.blue,
                ),
                _buildEmptyState(
                  'No past meetings',
                  'Your meeting history will appear here',
                  Icons.history,
                  Colors.grey,
                ),
              ],
            );
          }

          List<Meeting> meetings = snapshot.data!;
          List<Meeting> upcomingMeetings = meetings
              .where((meeting) => meeting.dateTime.isAfter(DateTime.now()))
              .toList();
          List<Meeting> pastMeetings = meetings
              .where((meeting) => meeting.dateTime.isBefore(DateTime.now()))
              .toList();

          // Sort meetings by date
          upcomingMeetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          pastMeetings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMeetingsList(upcomingMeetings, true),
              _buildMeetingsList(pastMeetings, false),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateMeetingScreen()),
            );
          },
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            'Schedule Meeting',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingsList(List<Meeting> meetings, bool isUpcoming) {
    if (meetings.isEmpty) {
      return _buildEmptyState(
        isUpcoming ? 'No upcoming meetings' : 'No past meetings',
        isUpcoming
            ? 'Schedule your first meeting to get started'
            : 'Your meeting history will appear here',
        isUpcoming ? Icons.event_available : Icons.history,
        isUpcoming ? Colors.blue : Colors.grey,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return _buildMeetingCard(meeting, isUpcoming);
      },
    );
  }

  Widget _buildMeetingCard(Meeting meeting, bool isUpcoming) {
    final now = DateTime.now();
    final timeUntil = meeting.dateTime.difference(now);
    final isToday =
        meeting.dateTime.day == now.day &&
        meeting.dateTime.month == now.month &&
        meeting.dateTime.year == now.year;
    final isTomorrow =
        meeting.dateTime.day == now.add(Duration(days: 1)).day &&
        meeting.dateTime.month == now.add(Duration(days: 1)).month &&
        meeting.dateTime.year == now.add(Duration(days: 1)).year;

    String timeLabel = '';
    Color timeColor = Colors.grey;

    if (isUpcoming) {
      if (isToday) {
        timeLabel = 'Today';
        timeColor = Colors.orange;
      } else if (isTomorrow) {
        timeLabel = 'Tomorrow';
        timeColor = Colors.green;
      } else if (timeUntil.inDays <= 7) {
        timeLabel = '${timeUntil.inDays} days';
        timeColor = Colors.blue;
      } else {
        timeLabel = DateFormat('MMM dd').format(meeting.dateTime);
        timeColor = Colors.grey;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isUpcoming && isToday
                ? Colors.orange.withOpacity(0.3)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                isUpcoming && isToday
                    ? Colors.orange.withOpacity(0.02)
                    : Colors.grey.withOpacity(0.01),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (isUpcoming && timeLabel.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: timeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                timeLabel,
                                style: TextStyle(
                                  color: timeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUpcoming ? Icons.access_time : Icons.check_circle,
                            size: 14,
                            color: isUpcoming ? Colors.green : Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isUpcoming ? 'Upcoming' : 'Completed',
                            style: TextStyle(
                              color: isUpcoming ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Description
                if (meeting.description.isNotEmpty) ...[
                  Text(
                    meeting.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Date and time info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, MMMM dd, yyyy',
                                ).format(meeting.dateTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                DateFormat('h:mm a').format(meeting.dateTime),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              meeting.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // RSVP buttons for upcoming meetings
                if (isUpcoming) ...[
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateRSVP(context, meeting.id, 'attending'),
                            icon: Icon(Icons.check_circle, size: 20),
                            label: Text(
                              'Attending',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateRSVP(
                              context,
                              meeting.id,
                              'not_attending',
                            ),
                            icon: Icon(Icons.cancel, size: 20),
                            label: Text(
                              'Not Attending',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateRSVP(BuildContext context, String meetingId, String response) {
    // Get current user ID from auth service
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    if (authService.user != null) {
      databaseService.updateMeetingRSVP(
        meetingId,
        authService.user!.uid,
        response,
      );

      // Show enhanced snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                response == 'attending' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                response == 'attending'
                    ? 'You\'re attending this meeting!'
                    : 'You\'re not attending this meeting',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: response == 'attending'
              ? Colors.green
              : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }
}
