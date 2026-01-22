import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/member.dart';
import '../members/add_member_screen.dart';
import '../members/members_screen.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/attendance_sessions_screen.dart';
import '../messaging/announcement_screen.dart';

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
    {
      'verse':
          '"Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight."',
      'reference': 'Proverbs 3:5-6',
    },
    {
      'verse':
          '"But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint."',
      'reference': 'Isaiah 40:31',
    },
    {
      'verse':
          '"Let the word of Christ dwell in you richly, teaching and admonishing one another in all wisdom."',
      'reference': 'Colossians 3:16',
    },
    {
      'verse':
          '"Whatever you do, work at it with all your heart, as working for the Lord, not for human masters."',
      'reference': 'Colossians 3:23',
    },
    {
      'verse': '"I can do all this through him who gives me strength."',
      'reference': 'Philippians 4:13',
    },
    {
      'verse':
          '"Let your light shine before others, that they may see your good deeds and glorify your Father in heaven."',
      'reference': 'Matthew 5:16',
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
    if (_verseAnimationController.isAnimating) return;
    _verseAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentVerseIndex = (_currentVerseIndex + 1) % _bibleVerses.length;
        });
        _verseAnimationController.forward();
      }
    });
  }

  void _shareVerse() {
    final verse = _bibleVerses[_currentVerseIndex]['verse'];
    final ref = _bibleVerses[_currentVerseIndex]['reference'];
    Share.share('$verse\n\n- $ref\nSent via UMaT SRID App');
  }

  void _copyVerse() {
    final verse = _bibleVerses[_currentVerseIndex]['verse'];
    final ref = _bibleVerses[_currentVerseIndex]['reference'];
    Clipboard.setData(ClipboardData(text: '$verse\n- $ref'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Inspiration copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.03),
              Colors.white,
              Theme.of(context).primaryColor.withValues(alpha: 0.01),
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
                            // Welcome Section
                            _buildWelcomeSection(authService),
                            const SizedBox(height: 24),

                            // Stats Grid Title
                            _buildSectionHeader('Ministry Overview'),
                            const SizedBox(height: 12),

                            if (authService.user == null)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              StreamBuilder<List<Member>>(
                                stream: Provider.of<DatabaseService>(
                                  context,
                                ).getMembers(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    print(
                                      'Dashboard Stats Error: ${snapshot.error}',
                                    );
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[50],
                                        border: Border.all(
                                          color: Colors.amber[200]!,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.amber[700],
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Limited access: Some data could not be loaded. Please verify your permissions.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

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

                                  final baptizedPercentage = memberCount > 0
                                      ? baptizedCount / memberCount
                                      : 0.0;

                                  return Column(
                                    children: [
                                      GridView.count(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 1.1,
                                        children: [
                                          _buildStatsCard(
                                            'Total Members',
                                            memberCount.toString(),
                                            Colors.blue,
                                            Icons.groups_rounded,
                                            onTap: () =>
                                                _navigateToMembers(context),
                                          ),
                                          _buildProgressStatsCard(
                                            'Baptized',
                                            baptizedCount.toString(),
                                            baptizedPercentage,
                                            Colors.green,
                                            Icons.water_drop_rounded,
                                          ),
                                          _buildStatsCard(
                                            'Ministry Roles',
                                            ministryCount.toString(),
                                            Colors.purple,
                                            Icons.auto_awesome_rounded,
                                          ),
                                          _buildStatsCard(
                                            'Not Baptized',
                                            unbaptizedCount.toString(),
                                            Colors.orange,
                                            Icons.person_outline_rounded,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Quick Actions Section
                                      _buildSectionHeader('Quick Actions'),
                                      const SizedBox(height: 12),

                                      GridView.count(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 1.5,
                                        children: [
                                          _buildActionCard(
                                            'Take Attendance',
                                            Colors.indigo,
                                            Icons.fact_check_rounded,
                                            onTap: () =>
                                                _navigateToAttendance(context),
                                          ),
                                          _buildActionCard(
                                            'Attendance Lists',
                                            Colors.blueAccent,
                                            Icons.analytics_rounded,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const AttendanceSessionsScreen(),
                                              ),
                                            ),
                                          ),
                                          if (authService.user == null)
                                            _buildActionCard(
                                              'Announcements',
                                              Colors.redAccent,
                                              Icons
                                                  .notifications_active_rounded,
                                              onTap: () {},
                                            )
                                          else
                                            StreamBuilder<QuerySnapshot>(
                                              stream:
                                                  Provider.of<DatabaseService>(
                                                    context,
                                                  ).getLatestAnnouncementStream(),
                                              builder: (context, announcementSnapshot) {
                                                // Handle permission denied or other errors gracefully during sign-out
                                                if (announcementSnapshot
                                                    .hasError) {
                                                  return _buildActionCard(
                                                    'Announcements',
                                                    Colors.redAccent
                                                        .withOpacity(0.5),
                                                    Icons
                                                        .notifications_off_rounded,
                                                    onTap: () {},
                                                  );
                                                }

                                                bool hasUnread = false;
                                                if (announcementSnapshot
                                                        .hasData &&
                                                    announcementSnapshot
                                                        .data!
                                                        .docs
                                                        .isNotEmpty) {
                                                  var doc = announcementSnapshot
                                                      .data!
                                                      .docs
                                                      .first;
                                                  var data =
                                                      doc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  Timestamp? ts =
                                                      data['timestamp']
                                                          as Timestamp?;
                                                  if (ts != null) {
                                                    final now = DateTime.now();
                                                    final postTime = ts
                                                        .toDate();
                                                    if (now
                                                            .difference(
                                                              postTime,
                                                            )
                                                            .inHours <
                                                        24) {
                                                      hasUnread = true;
                                                    }
                                                  }
                                                }

                                                return _buildActionCard(
                                                  'Announcements',
                                                  Colors.redAccent,
                                                  Icons
                                                      .notifications_active_rounded,
                                                  showBadge: hasUnread,
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const AnnouncementScreen(),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          _buildActionCard(
                                            'Add Member',
                                            authService.canEdit
                                                ? Colors.teal
                                                : Colors.grey,
                                            Icons.person_add_alt_1_rounded,
                                            onTap: authService.canEdit
                                                ? () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AddMemberScreen(),
                                                    ),
                                                  )
                                                : () => _showPermissionDenied(
                                                    context,
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 40),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedBuilder(
        animation: _verseAnimationController,
        builder: (context, child) {
          return Opacity(
            opacity: _verseAnimationController.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _verseAnimationController.value)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.amber[800],
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Daily Inspiration',
                              style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            // Actions
                            Row(
                              children: [
                                _buildVerseAction(
                                  Icons.copy_rounded,
                                  _copyVerse,
                                  'Copy',
                                ),
                                const SizedBox(width: 8),
                                _buildVerseAction(
                                  Icons.share_rounded,
                                  _shareVerse,
                                  'Share',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity! < 0) {
                              _cycleVerse();
                            } else if (details.primaryVelocity! > 0) {
                              // Cycle backwards
                              _verseAnimationController.reverse().then((_) {
                                if (mounted) {
                                  setState(() {
                                    _currentVerseIndex =
                                        (_currentVerseIndex -
                                            1 +
                                            _bibleVerses.length) %
                                        _bibleVerses.length;
                                  });
                                  _verseAnimationController.forward();
                                }
                              });
                            }
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 80),
                            child: Text(
                              _bibleVerses[_currentVerseIndex]['verse']!,
                              style: TextStyle(
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[800],
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    offset: const Offset(0.5, 0.5),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 1.5,
                              width: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.amber[300]!,
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                _bibleVerses[_currentVerseIndex]['reference']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber[800],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              height: 1.5,
                              width: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber[300]!,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _bibleVerses.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentVerseIndex == index ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentVerseIndex == index
                                    ? Colors.amber[700]
                                    : Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerseAction(IconData icon, VoidCallback onTap, String tooltip) {
    return Material(
      color: Colors.amber.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: Colors.amber[800]),
        ),
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
      expandedHeight: 0,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'CCCM - UMAT SRID',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => authService.signOut(),
            tooltip: 'Sign Out',
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(AuthService authService) {
    final userName = authService.user?.displayName ?? 'Organizer';
    final photoUrl = authService.user?.photoURL;
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay_rounded;
    }

    final uid = authService.user?.uid;

    // If no user is logged in, just display static content without Firestore stream
    if (uid == null || uid.isEmpty) {
      return _buildWelcomeContainer(userName, photoUrl, greeting, greetingIcon);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: Provider.of<DatabaseService>(
        context,
        listen: false,
      ).getUserProfileStream(uid),
      builder: (context, snapshot) {
        // Handle errors gracefully (e.g., PERMISSION_DENIED on sign-out)
        if (snapshot.hasError) {
          return _buildWelcomeContainer(
            userName,
            photoUrl,
            greeting,
            greetingIcon,
          );
        }

        String displayUserName = userName;
        String? displayPhotoUrl = photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayUserName = data['name'] ?? userName;
          displayPhotoUrl = data['photoUrl'] ?? photoUrl;
        }

        return _buildWelcomeContainer(
          displayUserName,
          displayPhotoUrl,
          greeting,
          greetingIcon,
        );
      },
    );
  }

  Widget _buildWelcomeContainer(
    String displayUserName,
    String? displayPhotoUrl,
    String greeting,
    IconData greetingIcon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayUserName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (displayPhotoUrl != null && displayPhotoUrl.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(displayPhotoUrl),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(greetingIcon, color: Colors.white, size: 28),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(_currentTime),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(_currentTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStatsCard(
    String title,
    String count,
    double percentage,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    Color color,
    IconData icon, {
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 24),
                      if (showBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Text('Only authorized users can add members.'),
          ],
        ),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Deprecated clock card removed
  // Widget _buildClockCard() ...

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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: onTap != null
              ? Border.all(color: color.withValues(alpha: 0.1), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const Spacer(),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
