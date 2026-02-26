import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
const _cardBg = Color(0xFFF0EDF6);
const _bg1 = Color(0xFFE6E2EE);
const _bg2 = Color(0xFFDAD4E6);

class ObservationsScreen extends StatefulWidget {
  const ObservationsScreen({super.key});

  @override
  State<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends State<ObservationsScreen> {
  final _service = SupabaseService();
  final _uuid = const Uuid();
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
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _deepPurple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Notes are saved permanently and cannot be edited.',
                style: GoogleFonts.inter(fontSize: 12, color: _mutedPurple),
              ),
              const SizedBox(height: 20),
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
                  style: GoogleFonts.inter(fontSize: 14, color: _deepPurple),
                  onChanged: (_) => setModal(() {}),
                  decoration: InputDecoration(
                    hintText: 'What would you like to note?',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFB8B0CC),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: GoogleFonts.inter(
                      fontSize: 11,
                      color: _mutedPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${ctrl.text.length}/$maxChars',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ctrl.text.length > 180
                        ? Colors.red.shade400
                        : _mutedPurple,
                  ),
                ),
              ),
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
                  onPressed: ctrl.text.trim().isEmpty
                      ? null
                      : () async {
                          final member = SessionManager().currentMember;
                          final teamId = SessionManager().currentCareTeam?.id;
                          if (teamId == null) return;
                          final note = Observation(
                            id: _uuid.v4(),
                            careTeamId: teamId,
                            content: ctrl.text.trim(),
                            category: 'note',
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
                    style: GoogleFonts.cormorantGaramond(
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
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1DCEA),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: _borderColor),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 15,
                          color: _mutedPurple,
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
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: _deepPurple,
                            ),
                          ),
                          Text(
                            '${_notes.length} entries',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _mutedPurple,
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
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
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
        style: GoogleFonts.lora(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _mutedPurple,
        ),
      ),
    );
  }

  Widget _noteCard(Observation note) {
    final time = note.createdAt != null
        ? DateFormat('h:mm a · MMM d').format(note.createdAt!)
        : '';
    final initials = (note.createdByMemberName ?? 'U')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

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
          Text(
            note.content ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _deepPurple,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
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
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _purple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                note.createdByMemberName ?? 'Unknown',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _mutedPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.lock_outline, size: 10, color: _lightPurple),
              const SizedBox(width: 3),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 10, color: _lightPurple),
              ),
            ],
          ),
        ],
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
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Note" to get started',
            style: GoogleFonts.inter(fontSize: 13, color: _mutedPurple),
          ),
        ],
      ),
    );
  }
}
