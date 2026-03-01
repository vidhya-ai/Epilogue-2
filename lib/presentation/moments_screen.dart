import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';
import 'premium_bottom_nav.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _deepPurple = Color(0xFF2E2540);
const _purple = Color(0xFF7A64A4);
const _mutedPurple = Color(0xFF6C648B);
const _lightPurple = Color(0xFFB0A8C8);
const _borderColor = Color(0xFFD4CDDF);
const _bg1 = Color(0xFFE6E2EE);
const _bg2 = Color(0xFFDAD4E6);
const _warmAmber = Color(0xFFE8A87C);
const _softRose = Color(0xFFD4849A);

// ─── Moment categories ────────────────────────────────────────────────────────
class _MomentCategory {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  const _MomentCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

const _categories = [
  _MomentCategory(
      id: 'memory',
      label: 'Memory',
      emoji: '✨',
      color: Color(0xFF9B7EBD)),
  _MomentCategory(
      id: 'gratitude',
      label: 'Gratitude',
      emoji: '🙏',
      color: Color(0xFFE8A87C)),
  _MomentCategory(
      id: 'photo',
      label: 'Photo',
      emoji: '📷',
      color: Color(0xFF7ABFB8)),
  _MomentCategory(
      id: 'message',
      label: 'Message',
      emoji: '💌',
      color: Color(0xFFD4849A)),
  _MomentCategory(
      id: 'milestone',
      label: 'Milestone',
      emoji: '🌟',
      color: Color(0xFFB5C99A)),
  _MomentCategory(
      id: 'prayer',
      label: 'Prayer',
      emoji: '🕊️',
      color: Color(0xFF8BB8E8)),
];

// ─── Demo moment model ────────────────────────────────────────────────────────
class _DemoMoment {
  final String id;
  final String category;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final String? photoPath;
  final bool isVideo;

  const _DemoMoment({
    required this.id,
    required this.category,
    required this.content,
    required this.authorName,
    required this.createdAt,
    this.photoPath,
    this.isVideo = false,
  });
}

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen>
    with SingleTickerProviderStateMixin {
  final _service = SupabaseService();
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  List<_DemoMoment> _moments = [];
  bool _isLoading = false;
  String? _selectedCategoryFilter;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadDemoMoments();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _loadDemoMoments() {
    // Demo moments — replace with Supabase later
    setState(() {
      _moments = [
        _DemoMoment(
          id: '1',
          category: 'memory',
          content:
              'Dad told me about the first time he drove a car — a red Ford in 1967. He laughed the whole time he told it. I never want to forget that laugh.',
          authorName: 'Sarah',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        _DemoMoment(
          id: '2',
          category: 'gratitude',
          content:
              'Grateful for the nurses who come with such kindness. You can feel they genuinely care. It makes everything a little easier.',
          authorName: 'Mom',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        _DemoMoment(
          id: '3',
          category: 'message',
          content:
              'Dad — I want you to know that every sacrifice you made for us was seen and felt. You are so loved. Rest easy.',
          authorName: 'James',
          createdAt:
              DateTime.now().subtract(const Duration(hours: 14)),
        ),
        _DemoMoment(
          id: '4',
          category: 'milestone',
          content:
              'Dad held baby Lily today for the first time. She grabbed his finger and he cried. Four generations in one room.',
          authorName: 'Sarah',
          createdAt:
              DateTime.now().subtract(const Duration(hours: 5)),
        ),
        _DemoMoment(
          id: '5',
          category: 'prayer',
          content:
              'Lord, surround him with peace. Let him feel our love even as he rests. We trust you with him.',
          authorName: 'Mom',
          createdAt:
              DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
      _animCtrl.forward(from: 0);
    });
  }

  // Check if current user is family (not medical staff)
  bool get _isFamilyMember {
    final role =
        SessionManager().currentMember?.role?.toLowerCase() ?? '';
    return !['nurse', 'doctor', 'physician', 'rn', 'lpn', 'lvn',
            'medical', 'hospice nurse', 'np']
        .any((r) => role.contains(r));
  }

  List<_DemoMoment> get _filtered {
    if (_selectedCategoryFilter == null) return _moments;
    return _moments
        .where((m) => m.category == _selectedCategoryFilter)
        .toList();
  }

  void _showAddMomentSheet() {
    if (!_isFamilyMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Only family members can add Moments.',
              style: GoogleFonts.nunito(fontSize: 13)),
          backgroundColor: _deepPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    String selectedCategory = 'memory';
    final contentCtrl = TextEditingController();
    XFile? pickedMedia;
    bool isVideo = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEDE8F5), Color(0xFFDAD4E6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a Moment',
                        style: GoogleFonts.nunito(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: _deepPurple,
                        )),
                    Text(
                      'Capture something worth keeping.',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: _mutedPurple),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom:
                        MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Category picker ──
                      Text('What kind of moment is this?',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _mutedPurple,
                          )),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected =
                              selectedCategory == cat.id;
                          return GestureDetector(
                            onTap: () => setModal(
                                () => selectedCategory = cat.id),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.color.withOpacity(0.18)
                                    : Colors.white.withOpacity(0.55),
                                borderRadius:
                                    BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? cat.color
                                      : _borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(cat.emoji,
                                      style: const TextStyle(
                                          fontSize: 15)),
                                  const SizedBox(width: 6),
                                  Text(cat.label,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? cat.color
                                            : _mutedPurple,
                                      )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // ── Media picker ──
                      Text('Add a photo or video (optional)',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _mutedPurple,
                          )),
                      const SizedBox(height: 10),

                      if (pickedMedia != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: isVideo
                                  ? Container(
                                      height: 180,
                                      width: double.infinity,
                                      color: _deepPurple
                                          .withOpacity(0.1),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons
                                                  .videocam_rounded,
                                              size: 48,
                                              color: _purple),
                                          const SizedBox(height: 8),
                                          Text('Video selected',
                                              style:
                                                  GoogleFonts.nunito(
                                                fontSize: 13,
                                                color: _mutedPurple,
                                              )),
                                        ],
                                      ),
                                    )
                                  : Image.file(
                                      File(pickedMedia!.path),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setModal(() {
                                  pickedMedia = null;
                                  isVideo = false;
                                }),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            // Camera
                            Expanded(
                              child: _mediaButton(
                                icon: Icons.camera_alt_outlined,
                                label: 'Take Photo',
                                onTap: () async {
                                  final file =
                                      await _picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 85,
                                  );
                                  if (file != null) {
                                    setModal(() {
                                      pickedMedia = file;
                                      isVideo = false;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Gallery
                            Expanded(
                              child: _mediaButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Choose Photo',
                                onTap: () async {
                                  final file =
                                      await _picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (file != null) {
                                    setModal(() {
                                      pickedMedia = file;
                                      isVideo = false;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Video
                            Expanded(
                              child: _mediaButton(
                                icon: Icons.videocam_outlined,
                                label: 'Record Video',
                                onTap: () async {
                                  final file =
                                      await _picker.pickVideo(
                                    source: ImageSource.camera,
                                    maxDuration:
                                        const Duration(minutes: 5),
                                  );
                                  if (file != null) {
                                    setModal(() {
                                      pickedMedia = file;
                                      isVideo = true;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // ── Text content ──
                      Text('Write something (optional)',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _mutedPurple,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        'A memory, a message, a prayer — whatever feels right.',
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: _lightPurple),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: TextField(
                          controller: contentCtrl,
                          maxLines: 6,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: _deepPurple,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'In their own words, or yours...',
                            hintStyle: GoogleFonts.nunito(
                                fontSize: 14,
                                color: const Color(0xFFB8B0CC)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Save button ──
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF6B5B8E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(32)),
                          ),
                          onPressed: (contentCtrl.text
                                      .trim()
                                      .isEmpty &&
                                  pickedMedia == null)
                              ? null
                              : () {
                                  final member = SessionManager()
                                      .currentMember;
                                  setState(() {
                                    _moments.insert(
                                      0,
                                      _DemoMoment(
                                        id: _uuid.v4(),
                                        category: selectedCategory,
                                        content: contentCtrl.text
                                            .trim(),
                                        authorName:
                                            member?.name ?? 'You',
                                        createdAt: DateTime.now(),
                                        photoPath:
                                            pickedMedia?.path,
                                        isVideo: isVideo,
                                      ),
                                    );
                                  });
                                  Navigator.pop(ctx);
                                },
                          child: Text('Save Moment',
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: _purple),
            const SizedBox(height: 5),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: _mutedPurple,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bg1, _bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1DCEA),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: _borderColor),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 15, color: _mutedPurple),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Moments',
                              style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: _deepPurple,
                              )),
                          Text(
                            'Family memories & messages',
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: _mutedPurple),
                          ),
                        ],
                      ),
                    ),
                    // Family-only badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _warmAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _warmAmber.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home_outlined,
                              size: 12, color: _warmAmber),
                          const SizedBox(width: 4),
                          Text('Family',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _warmAmber,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Category filter ──
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _catFilter(null, '✦', 'All'),
                    ..._categories.map(
                        (c) => _catFilter(c.id, c.emoji, c.label)),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: _borderColor, thickness: 1),
              ),

              // ── Moments feed ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: _purple))
                    : filtered.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                20, 8, 20, 100),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final moment = filtered[i];
                              final delay = i * 0.08;
                              return _momentCard(moment,
                                  animDelay: delay);
                            },
                          ),
              ),

              // ── Bottom Nav ──
              const PremiumBottomNav(currentIndex: 3),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      // ── FAB ──
      floatingActionButton: _isFamilyMember
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: GestureDetector(
                onTap: _showAddMomentSheet,
                child: Container(
                  height: 52,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF9B7EBD),
                        Color(0xFF6B5B8E),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Add Moment',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ─── Category filter chip ──────────────────────────────────────────────────
  Widget _catFilter(String? id, String emoji, String label) {
    final isSelected = _selectedCategoryFilter == id;
    final cat = id != null
        ? _categories.firstWhere((c) => c.id == id)
        : null;
    final color = cat?.color ?? _purple;

    return GestureDetector(
      onTap: () =>
          setState(() => _selectedCategoryFilter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : _borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected ? color : _mutedPurple,
                )),
          ],
        ),
      ),
    );
  }

  // ─── Moment card ──────────────────────────────────────────────────────────
  Widget _momentCard(_DemoMoment moment, {double animDelay = 0}) {
    final cat = _categories.firstWhere(
      (c) => c.id == moment.category,
      orElse: () => _categories.first,
    );
    final timeStr = _formatTime(moment.createdAt);
    final initials = moment.authorName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: cat.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo/video if present
          if (moment.photoPath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              child: moment.isVideo
                  ? Container(
                      height: 180,
                      width: double.infinity,
                      color: _deepPurple.withOpacity(0.08),
                      child: const Center(
                        child: Icon(Icons.play_circle_outline,
                            size: 56, color: _purple),
                      ),
                    )
                  : Image.file(
                      File(moment.photoPath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag + time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: cat.color.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(cat.label,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cat.color,
                              )),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(timeStr,
                        style: GoogleFonts.nunito(
                            fontSize: 10, color: _lightPurple)),
                  ],
                ),

                // Content
                if (moment.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    moment.content,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: _deepPurple,
                      height: 1.65,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Author row
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(initials,
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cat.color,
                            )),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(moment.authorName,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _mutedPurple,
                        )),
                    const Spacer(),
                    // Heart reaction
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Icon(Icons.favorite_border_rounded,
                              size: 16, color: _softRose),
                          const SizedBox(width: 3),
                          Text('Love',
                              style: GoogleFonts.nunito(
                                  fontSize: 11, color: _softRose)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE1DCEA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('✨',
                  style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 18),
          Text('No moments yet',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _deepPurple,
              )),
          const SizedBox(height: 6),
          Text(
            'Capture memories, messages\nand moments worth keeping.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 13, color: _mutedPurple, height: 1.5),
          ),
        ],
      ),
    );
  }
}