import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

const _deepPurple = Color(0xFF2E2540);
const _purple = Color(0xFF7A64A4);
const _mutedPurple = Color(0xFF6C648B);
const _borderColor = Color(0xFFD4CDDF);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _session = SessionManager();
  final _service = SupabaseService();

  int _doseBadge = 0;
  int _observationBadge = 0;
  int _symptomBadge = 0;
  int _momentBadge = 0;
  bool _isLoading = true;

  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadData();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final teamId = _session.currentCareTeam?.id;
    if (teamId == null) {
      if (mounted) context.go('/');
      return;
    }
    try {
      final results = await Future.wait([
        _service.getDoseLogs(teamId),
        _service.getObservations(teamId),
        _service.getSymptomEvents(teamId),
        _service.getMoments(teamId),
      ]);
      if (!mounted) return;
      setState(() {
        _doseBadge = (results[0] as List).length;
        _observationBadge = (results[1] as List).length;
        _symptomBadge = (results[2] as List).length;
        _momentBadge = (results[3] as List).length;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _staggerCtrl.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final careTeam = _session.currentCareTeam;
    final member = _session.currentMember;

    if (careTeam == null || member == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Session expired',
                style: GoogleFonts.nunito(fontSize: 24, color: _deepPurple),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Return to home'),
              ),
            ],
          ),
        ),
      );
    }

    final firstName = member.name.split(' ').first.toLowerCase();
    final patientName = careTeam.patientFirstName ?? 'your loved one';
    final today = DateFormat('EEE, MMM d').format(DateTime.now());

    return Scaffold(
      drawer: _AppDrawer(patientName: patientName),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74659A), Color(0xFFDFDBE5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // ── Top Bar (dark band from top of screen) ──
            Container(
              width: double.infinity,
              color: const Color(0xFF74659A),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: _isLoading
                      ? const SizedBox.shrink()
                      : _topBar(today, careTeam, context),
                ),
              ),
            ),

            // ── Rest of the page ──
            Expanded(
              child: SafeArea(
                top: false,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _purple),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),

                          // ── Welcome ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, $firstName',
                                  style: GoogleFonts.nunito(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'How can we help today?',
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ── Grid ──
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _grid(),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Emergency ──
                          if (careTeam.nurseLineNumber != null &&
                              careTeam.nurseLineNumber!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: _emergencyCard(careTeam),
                            ),

                          const SizedBox(height: 10),

                          // ── Bottom Nav ──
                          _BottomNav(currentIndex: 0),

                          const SizedBox(height: 10),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ───────────────────────────────────────────────────────────────
  Widget _topBar(String today, CareTeam careTeam, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
          child: Center(
            child: Text(
              'E',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _purple,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Epilogue',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                "${careTeam.patientFirstName ?? 'Your'}'s Care Space",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  color: const Color.fromARGB(
                    255,
                    255,
                    255,
                    255,
                  ).withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Text(
              today,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Grid ──────────────────────────────────────────────────────────────────
  Widget _grid() {
    final cards = [
      _CardData(
        title: 'Medications',
        subtitle: 'Doses & logs',
        icon: Icons.medication_outlined,
        badge: _doseBadge,
        route: '/medications',
      ),
      _CardData(
        title: 'Quick Notes',
        subtitle: 'Capture thoughts',
        icon: Icons.description_outlined,
        badge: _observationBadge,
        route: '/observations',
      ),
      _CardData(
        title: 'Symptoms',
        subtitle: 'Track changes',
        icon: Icons.monitor_heart_outlined,
        badge: _symptomBadge,
        route: '/symptoms',
      ),
      _CardData(
        title: 'Moments',
        subtitle: 'What matters',
        icon: Icons.favorite_border_rounded,
        badge: _momentBadge,
        route: '/moments',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final cardW = (constraints.maxWidth - spacing) / 2;
        final cardH = (constraints.maxHeight - spacing) / 2;
        final cardSize = cardW < cardH ? cardW : cardH;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _gridCard(cards[0], cardSize),
                  SizedBox(width: spacing),
                  _gridCard(cards[1], cardSize),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _gridCard(cards[2], cardSize),
                  SizedBox(width: spacing),
                  _gridCard(cards[3], cardSize),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gridCard(_CardData c, double size) {
    return GestureDetector(
      onTap: () => context.push(c.route),
      child: SizedBox(
        width: size,
        height: size,
        // ✅ clipBehavior.none allows badge to overflow outside card boundary
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.65),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: size * 0.3,
                        height: size * 0.3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E7CB1).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(size * 0.09),
                        ),
                        child: Icon(
                          c.icon,
                          color: Colors.white,
                          size: size * 0.14,
                        ),
                      ),
                      SizedBox(height: size * 0.07),
                      Text(
                        c.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: size * 0.09,
                          fontWeight: FontWeight.w600,
                          color: _deepPurple,
                        ),
                      ),
                      SizedBox(height: size * 0.02),
                      Text(
                        c.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: size * 0.074,
                          color: _mutedPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Badge — always visible, top-right corner
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    c.badge.toString(),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

  // ─── Emergency ─────────────────────────────────────────────────────────────
  Widget _emergencyCard(CareTeam careTeam) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 239, 235, 235),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_outlined,
              size: 16,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Help',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                Text(
                  'Nurse on call 24/7',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final num = careTeam.nurseLineNumber;
              if (num == null || num.isEmpty) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    'Emergency Call',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to call the nurse line?',
                    style: GoogleFonts.nunito(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('Cancel', style: GoogleFonts.nunito()),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'Yes, Call Now',
                        style: GoogleFonts.nunito(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await launchUrl(Uri.parse('tel:$num'));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'CALL NOW',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Data ────────────────────────────────────────────────────────────────
class _CardData {
  final String title, subtitle, route;
  final IconData icon;
  final int badge;
  const _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.route,
  });
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/dashboard'),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      label: 'Calendar',
      route: '/calendar',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Messages',
      route: '/messages',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8F5).withOpacity(0.82),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.75),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A64A4).withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(child: _buildItem(context, i)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => context.go(item.route),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF7A64A4).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              size: 19,
              color: isActive
                  ? const Color(0xFF6B5B8E)
                  : const Color(0xFFB0A8C8),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.label,
            style: GoogleFonts.nunito(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive
                  ? const Color(0xFF6B5B8E)
                  : const Color(0xFFB0A8C8),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

// ─── Drawer ───────────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final String patientName;
  const _AppDrawer({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF0EDF6),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Epilogue',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF443C63),
                    ),
                  ),
                  Text(
                    "$patientName's Care Space",
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: _mutedPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: _borderColor),
            const SizedBox(height: 8),
            _drawerItem(
              context,
              icon: Icons.people_outline,
              label: 'Care Team',
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.medical_information_outlined,
              label: 'Care Plan',
              onTap: () {
                Navigator.pop(context);
                context.push('/care_plan');
              },
            ),
            _drawerItem(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Calendar',
              onTap: () {
                Navigator.pop(context);
                context.push('/calendar');
              },
            ),
            const Spacer(),
            const Divider(color: _borderColor),
            _drawerItem(
              context,
              icon: Icons.logout_rounded,
              label: 'Sign out',
              color: Colors.red.shade400,
              onTap: () async {
                await SessionManager().clearSession();
                if (context.mounted) context.go('/');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? _mutedPurple, size: 20),
      title: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? const Color(0xFF443C63),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
