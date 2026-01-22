// screens/members/members_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/member.dart';
import 'add_member_screen.dart';
import 'member_detail_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  String _filterBy = 'All';
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _filterOptions = [
    {
      'value': 'All',
      'label': 'All Members',
      'icon': Icons.people,
      'color': Colors.blue,
    },
    {
      'value': 'Baptized',
      'label': 'Baptized',
      'icon': Icons.water_drop,
      'color': Colors.green,
    },
    {
      'value': 'Unbaptized',
      'label': 'Not Baptized',
      'icon': Icons.person,
      'color': Colors.orange,
    },
    {
      'value': 'Ministry',
      'label': 'With Ministry Role',
      'icon': Icons.work,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Members',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        automaticallyImplyLeading: Navigator.canPop(context),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Compact header with integrated search and filter
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  children: [
                    // Search bar with integrated filter
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Search field
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search members...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                            ),
                          ),

                          // Filter button integrated
                          Container(
                            decoration: BoxDecoration(
                              color: _filterBy != 'All'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showFilterDropdown(),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getFilterIcon(_filterBy),
                                        color: _filterBy != 'All'
                                            ? Colors.white
                                            : Colors.grey[600],
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: _filterBy != 'All'
                                            ? Colors.white
                                            : Colors.grey[600],
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active filter indicator (compact)
                    if (_filterBy != 'All') ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getFilterIcon(_filterBy),
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _getFilterLabel(_filterBy),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _filterBy = 'All'),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Members list with reduced spacing
            Expanded(
              child: StreamBuilder<List<Member>>(
                stream: Provider.of<DatabaseService>(context).getMembers(),
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
                            'Loading members...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  List<Member> members = snapshot.data!;
                  List<Member> filteredMembers = _applyFilters(members);

                  if (filteredMembers.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return Column(
                    children: [
                      // Compact stats header
                      Container(
                        margin: EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                            _buildStatItem(
                              'Total',
                              members.length.toString(),
                              Colors.blue,
                              Icons.people,
                            ),
                            _buildStatItem(
                              'Baptized',
                              members
                                  .where((m) => m.isBaptized)
                                  .length
                                  .toString(),
                              Colors.green,
                              Icons.water_drop,
                            ),
                            _buildStatItem(
                              'Showing',
                              filteredMembers.length.toString(),
                              Theme.of(context).primaryColor,
                              Icons.visibility,
                            ),
                          ],
                        ),
                      ),

                      // Members list
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
                            return _buildMemberCard(member, index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Provider.of<AuthService>(context).canEdit
          ? Container(
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
                    MaterialPageRoute(builder: (context) => AddMemberScreen()),
                  );
                },
                icon: Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  'Add Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0,
              ),
            )
          : null,
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.withOpacity(0.01)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemberDetailScreen(
                      member: member,
                      onMemberUpdated: (updatedMember) {
                        print('Member updated: ${updatedMember.name}');
                      },
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar with status indicator
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              (member.isBaptized ? Colors.green : Colors.orange)
                                  .withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (member.isBaptized
                                        ? Colors.green
                                        : Colors.orange)
                                    .withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            (member.isBaptized ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.1),
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
                                  color: member.isBaptized
                                      ? Colors.green[800]
                                      : Colors.orange[800],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 12),

                    // Member info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '${member.year} • ${member.department}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (member.ministryRole.isNotEmpty) ...[
                            SizedBox(height: 3),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                member.ministryRole,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Quick Call Action
                    if (member.phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.blue.withOpacity(0.1),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {
                              final Uri phoneUri = Uri(
                                scheme: 'tel',
                                path: member.phone,
                              );
                              launchUrl(phoneUri);
                            },
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.call_rounded,
                                size: 18,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Status and arrow
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: member.isBaptized
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.isBaptized ? 'Baptized' : 'Not Baptized',
                            style: TextStyle(
                              fontSize: 9,
                              color: member.isBaptized
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people, size: 64, color: Colors.blue),
            ),
            SizedBox(height: 24),
            Text(
              'No members yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start building your ministry community by adding the first member',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off, size: 64, color: Colors.orange),
            ),
            SizedBox(height: 24),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _filterBy = 'All';
                });
              },
              child: Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + 100,
        position.dx,
        position.dy + 100,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: _filterOptions.map((option) {
        final isSelected = _filterBy == option['value'];
        return PopupMenuItem<String>(
          value: option['value'],
          child: Row(
            children: [
              Icon(
                option['icon'],
                color: isSelected ? option['color'] : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                option['label'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? option['color'] : Colors.grey[800],
                ),
              ),
              Spacer(),
              if (isSelected)
                Icon(Icons.check, color: option['color'], size: 18),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() => _filterBy = value);
      }
    });
  }

  List<Member> _applyFilters(List<Member> members) {
    List<Member> filtered = List.from(members);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (member) =>
                member.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                // member.email.toLowerCase().contains(
                //   _searchQuery.toLowerCase(),
                // ) ||
                member.department.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                member.ministryRole.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply category filter
    switch (_filterBy) {
      case 'Baptized':
        filtered = filtered.where((member) => member.isBaptized).toList();
        break;
      case 'Unbaptized':
        filtered = filtered.where((member) => !member.isBaptized).toList();
        break;
      case 'Ministry':
        filtered = filtered
            .where((member) => member.ministryRole.isNotEmpty)
            .toList();
        break;
    }

    return filtered;
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Baptized':
        return Icons.water_drop;
      case 'Unbaptized':
        return Icons.person;
      case 'Ministry':
        return Icons.work;
      default:
        return Icons.tune;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'Baptized':
        return 'Baptized';
      case 'Unbaptized':
        return 'Not Baptized';
      case 'Ministry':
        return 'With Ministry Role';
      default:
        return 'All Members';
    }
  }
}
