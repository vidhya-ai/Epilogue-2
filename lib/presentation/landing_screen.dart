import 'dart:async';
import 'dart:ui';

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
                colors: [
                  Color(0xFF74659A), // deep purple at top
                  Color(0xFFDFDBE5), // soft lilac at bottom
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, 0.10),
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
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today',
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.0,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE').format(_currentDate),
                                  style: GoogleFonts.nunito(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMMM d, y')
                                      .format(_currentDate),
                                  style: GoogleFonts.nunito(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 36,
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

                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withOpacity(0.30),
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
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9999),
                                  color: Colors.white.withOpacity(0.70),
                                  border: Border.all(
                                    color: const Color(0xFF6B5B95).withOpacity(0.40),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9999),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                    child: Text(
                                      'Compassionate Care At Home',
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.0,
                                        color: const Color(0xFF1A1A24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Epilogue',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 80,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: 320,
                                child: Text(
                                  'Supporting families through hospice care at home, one gentle day at a time.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A24),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Start button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.go('/setup'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6B5B95),
                                    foregroundColor: Colors.white,
                                    elevation: 6,
                                    shadowColor: const Color(0xFF6B5B95).withOpacity(0.30),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(9999),
                                    ),
                                  ),
                                  child: Text(
                                    'Start Your Care Team',
                                    style: GoogleFonts.nunito(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              Text(
                                'Already have an invite code?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  color: const Color(0xFF1A1A24),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 16),

                              ElevatedButton(
                                onPressed: () =>
                                    context.go('/join'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF6B5B95),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: const Color(0xFF6B5B95).withOpacity(0.30),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(9999),
                                  ),
                                ),
                                child: Text(
                                  'Join here',
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
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
        border: Border.all(
          color: const Color(0xFF6B5B95).withOpacity(0.05),
          width: 1.5,
        ),
      ),
    );
  }
}
