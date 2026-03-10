import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';
import 'premium_bottom_nav.dart';

const _deepPurple = Color(0xFF2E2540);
const _purple = Color(0xFF7A64A4);
const _mutedPurple = Color(0xFF6C648B);
const _lightPurple = Color(0xFFB0A8C8);
const _borderColor = Color(0xFFD4CDDF);
const _bg1 = Color(0xFF74659A);
const _bg2 = Color(0xFFDFDBE5);

class ObservationsScreen extends StatefulWidget {
  const ObservationsScreen({super.key});

  @override
  State<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends State<ObservationsScreen> {
  final _service = SupabaseService();
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  List<Observation> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final teamId = SessionManager().currentCareTeam?.id;
      if (teamId == null) return;
      final result = await _service.getObservations(teamId);
      result.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      if (mounted) setState(() => _notes = result);
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddNoteModal() {
    final ctrl = TextEditingController();
    const maxChars = 200;
    String inputMode = 'text';
    XFile? pickedPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEDE8F5), Color(0xFFDAD4E6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Note',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _deepPurple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Notes are saved permanently and cannot be edited.',
                style: GoogleFonts.nunito(fontSize: 16, color: const Color.fromARGB(255, 3, 3, 3)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _modeButton(
                      icon: Icons.edit_outlined,
                      label: 'Text',
                      selected: inputMode == 'text',
                      onTap: () => setModal(() => inputMode = 'text'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _modeButton(
                      icon: Icons.mic_none_rounded,
                      label: 'Voice',
                      selected: inputMode == 'voice',
                      onTap: () => setModal(() => inputMode = 'voice'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _modeButton(
                      icon: Icons.photo_camera_back_outlined,
                      label: 'Photo',
                      selected: inputMode == 'photo',
                      onTap: () => setModal(() => inputMode = 'photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (inputMode == 'text') ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: TextField(
                    controller: ctrl,
                    maxLength: maxChars,
                    maxLines: 5,
                    style: GoogleFonts.nunito(fontSize: 16, color: _deepPurple),
                    onChanged: (_) => setModal(() {}),
                    decoration: InputDecoration(
                      hintText: 'What would you like to note?',
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 16,
                        color: const Color.fromARGB(255, 44, 44, 45),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${ctrl.text.length}/$maxChars',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: ctrl.text.length > 180
                          ? Colors.red.shade400
                          : _mutedPurple,
                    ),
                  ),
                ),
              ],
              if (inputMode == 'voice') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _purple.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_none_rounded,
                          color: _purple,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Voice recording will appear here.',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _deepPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Recorder hookup is pending.',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: _mutedPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (inputMode == 'photo') ...[
                if (pickedPhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(pickedPhoto!.path),
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: _purple,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Attach a photo note',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final file = await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 85,
                          );
                          if (file != null) {
                            setModal(() => pickedPhoto = file);
                          }
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final file = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (file != null) {
                            setModal(() => pickedPhoto = file);
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose Photo'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5B8E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  onPressed: (inputMode == 'text' && ctrl.text.trim().isEmpty) ||
                          (inputMode == 'photo' && pickedPhoto == null) ||
                          inputMode == 'voice'
                      ? null
                      : () async {
                          final member = SessionManager().currentMember;
                          final teamId = SessionManager().currentCareTeam?.id;
                          if (teamId == null) return;
                          final note = Observation(
                            id: _uuid.v4(),
                            careTeamId: teamId,
                            content: inputMode == 'photo'
                                ? pickedPhoto!.path
                                : ctrl.text.trim(),
                            category: inputMode == 'photo' ? 'photo' : 'note',
                            createdAt: DateTime.now(),
                            createdByMemberId: member?.id,
                            createdByMemberName: member?.name,
                          );
                          await _service.addObservation(note);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _loadNotes();
                        },
                  child: Text(
                    'Save Note',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<Observation>> _groupNotes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    final groups = <String, List<Observation>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'This Month': [],
      'Older': [],
    };

    for (final note in _notes) {
      final d = note.createdAt ?? DateTime(2000);
      final noteDay = DateTime(d.year, d.month, d.day);
      if (noteDay == today) {
        groups['Today']!.add(note);
      } else if (noteDay == yesterday) {
        groups['Yesterday']!.add(note);
      } else if (d.isAfter(weekAgo)) {
        groups['This Week']!.add(note);
      } else if (d.isAfter(monthAgo)) {
        groups['This Month']!.add(note);
      } else {
        groups['Older']!.add(note);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupNotes();

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
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Notes',
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "${SessionManager().currentCareTeam?.patientFirstName ?? 'Your'}'s Care Space",
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: _borderColor, thickness: 1),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _purple),
                      )
                    : _notes.isEmpty
                    ? _emptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        children: [
                          for (final group in groups.entries)
                            if (group.value.isNotEmpty) ...[
                              _groupHeader(group.key),
                              ...group.value.map((n) => _noteCard(n)),
                              const SizedBox(height: 8),
                            ],
                        ],
                      ),
              ),
              const PremiumBottomNav(currentIndex: 0),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: GestureDetector(
          onTap: _showAddNoteModal,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5B8E),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Note',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _mutedPurple,
        ),
      ),
    );
  }

  Widget _noteCard(Observation note) {
    final time = note.createdAt != null
        ? DateFormat('h:mm a Ã‚Â· MMM d').format(note.createdAt!)
        : '';
    final initials = (note.createdByMemberName ?? 'U')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    final isPhotoNote = note.category == 'photo';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPhotoNote && (note.content ?? '').isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(note.content!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Text(
                    'Photo unavailable',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _mutedPurple,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else
            Text(
              note.content ?? '',
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: _deepPurple,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (isPhotoNote) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Photo',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _purple,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _purple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                note.createdByMemberName ?? 'Unknown',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: _mutedPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.lock_outline, size: 10, color: _lightPurple),
              const SizedBox(width: 3),
              Text(
                time,
                style: GoogleFonts.nunito(fontSize: 16, color: _lightPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _purple : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _purple : _borderColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : _deepPurple,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE1DCEA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 32,
              color: _lightPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Note" to get started',
            style: GoogleFonts.nunito(fontSize: 15, color: _mutedPurple),
          ),
        ],
      ),
    );
  }
}

