import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';
import '../widget/premium_bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _session = SessionManager();
  final _supabaseService = SupabaseService();

  List<DoseLog> _recentDoses = [];
  List<Observation> _recentObservations = [];
  List<CalendarEvent> _upcomingEvents = [];
  int _momentsCount = 0;
  int _unreadMessagesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final careTeamId = _session.currentCareTeam?.id;

    if (careTeamId == null) {
      if (mounted) context.go('/');
      return;
    }

    try {
      final doses = await _supabaseService.getDoseLogs(careTeamId);
      final observations = await _supabaseService.getObservations(careTeamId);
      final events = await _supabaseService.getCalendarEvents(careTeamId);
      final moments = await _supabaseService.getMoments(careTeamId);

      if (!mounted) return;

      setState(() {
        _recentDoses = doses.take(3).toList();
        _recentObservations = observations.take(3).toList();
        _upcomingEvents = events.take(3).toList();
        _momentsCount = moments.length;
        _unreadMessagesCount = 4;
      });
    } catch (e) {
      debugPrint('Dashboard error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final careTeam = _session.currentCareTeam;
    final member = _session.currentMember;

    if (careTeam == null || member == null) {
      return const Scaffold(
        body: Center(child: Text('Session expired. Please log in again.')),
      );
    }

    final firstName = member.name.split(' ').first;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          /// 🌈 BACKGROUND + CONTENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8F6FC),
                  Color(0xFFEDEAF6),
                  Color(0xFFD7CFE9),
                  Color(0xFFC2B6DC),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _header(careTeam),

                            const SizedBox(height: 28),

                            Text(
                              'Welcome back, $firstName',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4B3F66),
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'How can we help today?',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF6B5B95),
                              ),
                            ),

                            const SizedBox(height: 26),

                            /// ===== PREMIUM GRID =====
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 1,
                              children: [
                                _premiumCard(
                                  title: 'Medications',
                                  subtitle: 'Doses & logs',
                                  icon: Icons.medication_outlined,
                                  badge: _recentDoses.length,
                                  onTap: () => context.push('/medications'),
                                ),
                                _premiumCard(
                                  title: 'Quick notes',
                                  subtitle: 'Daily jots',
                                  icon: Icons.description_outlined,
                                  badge: _recentObservations.length,
                                  onTap: () => context.push('/observations'),
                                ),
                                _premiumCard(
                                  title: 'Symptoms',
                                  subtitle: 'Track changes',
                                  icon: Icons.monitor_heart_outlined,
                                  badge: _upcomingEvents.length,
                                  onTap: () => context.push('/symptoms'),
                                ),
                                if (member.role != 'professional')
                                  _premiumCard(
                                    title: 'Moments',
                                    subtitle: 'What matters',
                                    icon: Icons.favorite_border_rounded,
                                    badge: _momentsCount,
                                    onTap: () => context.push('/moments'),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            _messagesCard(),

                            const SizedBox(height: 22),

                            if (careTeam.nurseLineNumber != null &&
                                careTeam.nurseLineNumber!.isNotEmpty)
                              _emergencyCard(),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          /// ⭐ FLOATING PREMIUM NAV
          const PremiumBottomNav(currentIndex: 0),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header(careTeam) {
    return Builder(
      builder: (context) => Row(
        children: [
          _glassContainer(
            width: 52,
            height: 52,
            child: const Center(
              child: Text(
                'E',
                style: TextStyle(
                  color: Color(0xFF6B5B95),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Epilogue',
                  style: TextStyle(
                    color: Color(0xFF4B3F66),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "${careTeam.patientFirstName}'s Care Space",
                  style: const TextStyle(color: Color(0xFF6B5B95)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.people, color: Color(0xFF4B3F66)),
          ),
        ],
      ),
    );
  }

  // ================= PREMIUM CARD =================
  Widget _premiumCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          _glassContainer(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E7CB1), Color(0xFFA99BD1)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF3F3561),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B7BA8),
                  ),
                ),
              ],
            ),
          ),
          if (badge > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= GLASS =================
  Widget _glassContainer({
    Widget? child,
    EdgeInsets? padding,
    double? width,
    double? height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: child,
        ),
      ),
    );
  }

  // ================= MESSAGES =================
  Widget _messagesCard() {
    return _glassContainer(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Color(0xFF6B5B95)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Messages — Team communication',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF3F3561),
              ),
            ),
          ),
          if (_unreadMessagesCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5B95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _unreadMessagesCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  // ================= EMERGENCY =================
  Widget _emergencyCard() {
    final careTeam = _session.currentCareTeam;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC4446), Color(0xFFB33638)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone, color: Colors.white),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Emergency Help — Nurse on call 24/7',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (careTeam?.nurseLineNumber != null &&
                  careTeam!.nurseLineNumber!.isNotEmpty) {
                final uri = Uri.parse('tel:${careTeam.nurseLineNumber}');
                await launchUrl(uri);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'CALL NOW',
                style: TextStyle(
                  color: Color(0xFFB33638),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                await SessionManager().clearSession();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}
