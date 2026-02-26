import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isDrawerOpen = false;
  DateTime _currentDate = DateTime.now();
  Timer? _dateTimer;

  @override
  void initState() {
    super.initState();
    _dateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      if (now.year != _currentDate.year ||
          now.month != _currentDate.month ||
          now.day != _currentDate.day) {
        if (mounted) {
          setState(() {
            _currentDate = now;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE6E2EE), Color(0xFFDAD4E6)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.05),
                    child: SizedBox(
                      width: 760,
                      height: 760,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [_ring(760), _ring(520), _ring(360)],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TODAY',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.2,
                                    color: const Color(0xFF7A7195),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE').format(_currentDate),
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF443C63),
                                    height: 0.95,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMMM d, y')
                                      .format(_currentDate),
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF6C648B),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Color(0xFF5F587F),
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isDrawerOpen = !_isDrawerOpen;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFD4CDDF),
                      ),

                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFFE1DCEA),
                                  border: Border.all(
                                    color: const Color(0xFFCFC8DB),
                                  ),
                                ),
                                child: Text(
                                  '• COMPASSIONATE CARE AT HOME',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'Epilogue',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 82,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF7A64A4),
                                  height: 0.88,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Supporting families through hospice care at\nhome, one gentle day at a time.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 34),

                              // Start button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.go('/setup'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6B5B8E),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Start Your Care Team',
                                        style:
                                            GoogleFonts.cormorantGaramond(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 18),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              Text(
                                'Already have an invite code?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                width: 210,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.go('/join'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6B5B8E),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Text('Join here',
                                          style: TextStyle(
                                              color: Colors.white)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward,
                                          size: 16,
                                          color: Colors.white),
                                    ],
                                  ),
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
          ),

          // Drawer overlay
          if (_isDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _isDrawerOpen = false),
                child: Container(
                    color: Colors.black.withOpacity(0.5)),
              ),
            ),

          // Drawer panel
          if (_isDrawerOpen)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 250,
                height: double.infinity,
                color: Colors.white,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _isDrawerOpen = false),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ✅ FIXED — using push
                        GestureDetector(
                          onTap: () {
                            setState(() => _isDrawerOpen = false);
                            context.push('/what_we_provide');
                          },
                          child: Text(
                            'What We Provide',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF2E2540),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () {
                            setState(() => _isDrawerOpen = false);
                            context.go('/how_it_works');
                          },
                          child: Text(
                            'How it Works',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF2E2540),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ring(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD3CBDD), width: 1),
      ),
    );
  }
}