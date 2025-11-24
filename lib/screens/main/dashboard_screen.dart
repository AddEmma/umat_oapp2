// screens/main/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/member.dart';
import '../members/add_member_screen.dart';
import '../members/members_screen.dart';
import '../attendance/attendance_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _verseAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _verseSlideAnimation;
  late Timer _timer;
  late Timer _verseTimer;
  DateTime _currentTime = DateTime.now();
  int _currentVerseIndex = 0;

  // Inspirational Bible verses for ministry leaders
  final List<Map<String, String>> _bibleVerses = [
    {
      'verse':
          '"For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, to give you hope and a future."',
      'reference': 'Jeremiah 29:11',
    },
    {
      'verse':
          '"Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go."',
      'reference': 'Joshua 1:9',
    },
    {
      'verse':
          '"And let us consider how we may spur one another on toward love and good deeds, not giving up meeting together."',
      'reference': 'Hebrews 10:24-25',
    },
    {
      'verse':
          '"Therefore encourage one another and build each other up, just as in fact you are doing."',
      'reference': '1 Thessalonians 5:11',
    },
    {
      'verse':
          '"Commit to the Lord whatever you do, and he will establish your plans."',
      'reference': 'Proverbs 16:3',
    },
    {
      'verse':
          '"The Lord your God is with you, the Mighty Warrior who saves. He will take great delight in you; in his love he will no longer rebuke you, but will rejoice over you with singing."',
      'reference': 'Zephaniah 3:17',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _verseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _verseSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _verseAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _verseAnimationController.forward();

    // Start the timer for real-time updates
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Timer to change Bible verse every 15 seconds
    _verseTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) {
        _cycleVerse();
      }
    });
  }

  void _cycleVerse() {
    _verseAnimationController.reverse().then((_) {
      setState(() {
        _currentVerseIndex = (_currentVerseIndex + 1) % _bibleVerses.length;
      });
      _verseAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _verseAnimationController.dispose();
    _timer.cancel();
    _verseTimer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    String period = time.hour >= 12 ? 'PM' : 'AM';
    int hour = time.hour == 0
        ? 12
        : (time.hour > 12 ? time.hour - 12 : time.hour);
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    List<String> weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    List<String> months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    String weekday = weekdays[date.weekday % 7];
    String month = months[date.month];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.user?.displayName ?? 'Organizer';

    return Scaffold(
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
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    slivers: [
                      // Custom App Bar
                      _buildCustomAppBar(context, authService),

                      // Bible Verse Section
                      SliverToBoxAdapter(child: _buildBibleVerseSection()),

                      // Main Content
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Welcome Section with Real-time Clock
                            _buildWelcomeSection(userName),
                            const SizedBox(height: 24),

                            // Real-time Clock Card
                            _buildClockCard(),
                            const SizedBox(height: 24),

                            // Stats Cards with Live Data
                            StreamBuilder<List<Member>>(
                              stream: Provider.of<DatabaseService>(
                                context,
                              ).getMembers(),
                              builder: (context, snapshot) {
                                final memberCount = snapshot.hasData
                                    ? snapshot.data!.length
                                    : 0;
                                final baptizedCount = snapshot.hasData
                                    ? snapshot.data!
                                          .where((m) => m.isBaptized)
                                          .length
                                    : 0;
                                final unbaptizedCount =
                                    memberCount - baptizedCount;
                                final ministryCount = snapshot.hasData
                                    ? snapshot.data!
                                          .where(
                                            (m) => m.ministryRole.isNotEmpty,
                                          )
                                          .length
                                    : 0;

                                return Column(
                                  children: [
                                    // First Row of Stats
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatsCard(
                                            'Total Members',
                                            memberCount.toString(),
                                            Colors.blue,
                                            Icons.people,
                                            onTap: () =>
                                                _navigateToMembers(context),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatsCard(
                                            'Baptized',
                                            baptizedCount.toString(),
                                            Colors.green,
                                            Icons.water_drop,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Second Row of Stats
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatsCard(
                                            'Not Baptized',
                                            unbaptizedCount.toString(),
                                            Colors.orange,
                                            Icons.person,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatsCard(
                                            'Ministry Roles',
                                            ministryCount.toString(),
                                            Colors.purple,
                                            Icons.work,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Third Row of Stats
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatsCard(
                                            'Attendance',
                                            'Track',
                                            Colors.indigo,
                                            Icons.fact_check,
                                            onTap: () =>
                                                _navigateToAttendance(context),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatsCard(
                                            'Add Member',
                                            'New',
                                            Colors.teal,
                                            Icons.person_add,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AddMemberScreen(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(
                              height: 100,
                            ), // Bottom padding for FAB
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBibleVerseSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AnimatedBuilder(
        animation: _verseAnimationController,
        builder: (context, child) {
          return SlideTransition(
            position: _verseSlideAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Inspiration',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_currentVerseIndex + 1}/${_bibleVerses.length}',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _bibleVerses[_currentVerseIndex]['verse']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '- ${_bibleVerses[_currentVerseIndex]['reference']} -',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Navigation methods
  void _navigateToMembers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MembersScreen()),
    );
  }

  void _navigateToAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AttendanceScreen()),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, AuthService authService) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.church, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Church Ministry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => authService.signOut(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String userName) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    Color greetingColor;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
      greetingColor = Colors.amber;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
      greetingColor = Colors.orange;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
      greetingColor = Colors.indigo;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: greetingColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(greetingIcon, size: 28, color: greetingColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ready to serve and lead with purpose today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Current Time',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatTime(_currentTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(_currentTime),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String count,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: onTap != null
              ? Border.all(color: color.withOpacity(0.2), width: 1)
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
