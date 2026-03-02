import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';
import '../domain/symptom_data.dart';
import 'premium_bottom_nav.dart';

const _deepPurple = Color(0xFF2E2540);
const _purple = Color(0xFF7A64A4);
const _mutedPurple = Color(0xFF6C648B);
const _lightPurple = Color(0xFFB0A8C8);
const _borderColor = Color(0xFFD4CDDF);
const _bg1 = Color(0xFFE6E2EE);
const _bg2 = Color(0xFFDAD4E6);

/// Sorted symptom list for the UI, alphabetical by name.
final _sortedSymptoms = List<SymptomDefinition>.from(kHospiceSymptoms)
  ..sort((a, b) => a.name.compareTo(b.name));

class SymptomEventsScreen extends StatefulWidget {
  const SymptomEventsScreen({super.key});

  @override
  State<SymptomEventsScreen> createState() => _SymptomEventsScreenState();
}

class _SymptomEventsScreenState extends State<SymptomEventsScreen> {
  final _service = SupabaseService();
  final _uuid = const Uuid();
  List<SymptomEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final teamId = SessionManager().currentCareTeam?.id;
      if (teamId == null) return;
      final result = await _service.getSymptomEvents(teamId);
      if (mounted) setState(() => _events = result);
    } catch (e) {
      debugPrint('Error loading symptom events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogSymptomModal() {
    // Maps symptom ID → selected option value (for dropdown symptoms).
    final selectedValues = <String, String>{};
    // Set of selected symptom IDs.
    final selectedIds = <String>{};
    final notesCtrl = TextEditingController();
    final otherCtrl = TextEditingController();
    bool nurseContacted = false;
    bool showOtherField = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          // Check if any selected symptom triggers a nurse alert
          final hasAlert = selectedIds.any((id) {
            final def = kSymptomById[id];
            return def != null && def.isAlertTrigger;
          });

          // Also alert when a severity-type symptom is set to "Severe"
          final hasSevereValue = selectedValues.values
              .any((v) => v == 'Severe');
          final showNurseAlert = hasAlert || hasSevereValue;

          // Gather selected definitions that have options for the detail section
          final withOptions = selectedIds
              .map((id) => kSymptomById[id])
              .where((d) => d != null && d.options.isNotEmpty)
              .cast<SymptomDefinition>()
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.92,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEDE8F5), Color(0xFFDAD4E6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('Log Symptoms',
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: _deepPurple,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                        // ── Symptoms ──
                        Text('Symptoms',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _mutedPurple,
                            )),
                        const SizedBox(height: 4),
                        Text('Select all that apply',
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: _lightPurple)),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._sortedSymptoms.map((def) {
                              final isSelected =
                                  selectedIds.contains(def.id);
                              final isAlert = def.isAlertTrigger;

                              return GestureDetector(
                                onTap: () {
                                  setModal(() {
                                    if (isSelected) {
                                      selectedIds.remove(def.id);
                                      selectedValues.remove(def.id);
                                    } else {
                                      selectedIds.add(def.id);
                                      // Auto-select first option for dropdown
                                      if (def.inputType ==
                                              SymptomInputType.dropdown &&
                                          def.options.isNotEmpty) {
                                        selectedValues[def.id] =
                                            def.options.first;
                                      } else if (def.inputType ==
                                              SymptomInputType.event &&
                                          def.options.isNotEmpty) {
                                        selectedValues[def.id] =
                                            def.options.first;
                                      }
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isAlert
                                            ? Colors.red.withOpacity(0.12)
                                            : _purple.withOpacity(0.12))
                                        : Colors.white.withOpacity(0.6),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isAlert
                                              ? Colors.red.shade300
                                              : _purple)
                                          : _borderColor,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isAlert && isSelected)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 4),
                                          child: Icon(
                                              Icons.warning_amber_rounded,
                                              size: 12,
                                              color:
                                                  Colors.red.shade400),
                                        ),
                                      Text(def.name,
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? (isAlert
                                                    ? Colors.red.shade600
                                                    : _purple)
                                                : _mutedPurple,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            // "Other" chip
                            GestureDetector(
                              onTap: () {
                                setModal(() {
                                  showOtherField = !showOtherField;
                                });
                              },
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: showOtherField
                                      ? _purple.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.6),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: showOtherField
                                        ? _purple
                                        : _borderColor,
                                    width: showOtherField ? 1.5 : 1,
                                  ),
                                ),
                                child: Text('Other',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: showOtherField
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: showOtherField
                                          ? _purple
                                          : _mutedPurple,
                                    )),
                              ),
                            ),
                          ],
                        ),

                        // Other field
                        if (showOtherField) ...[
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderColor),
                            ),
                            child: TextField(
                              controller: otherCtrl,
                              style: GoogleFonts.nunito(
                                  fontSize: 13, color: _deepPurple),
                              decoration: InputDecoration(
                                hintText:
                                    'Describe other symptom...',
                                hintStyle: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color:
                                        const Color(0xFFB8B0CC)),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                        ],

                        // ── Per-symptom detail selectors ──
                        if (withOptions.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Symptom Details',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _mutedPurple,
                              )),
                          const SizedBox(height: 4),
                          Text('Set the level for each selected symptom',
                              style: GoogleFonts.nunito(
                                  fontSize: 11, color: _lightPurple)),
                          const SizedBox(height: 10),
                          ...withOptions.map((def) {
                            final current =
                                selectedValues[def.id] ??
                                    def.options.first;
                            final label = def.description != null
                                ? '${def.name}  ·  ${def.description}'
                                : def.name;
                            return _optionRow(
                              label: label,
                              options: def.options,
                              current: current,
                              isAlert: def.isAlertTrigger,
                              onChanged: (v) =>
                                  setModal(() => selectedValues[def.id] = v),
                            );
                          }),
                        ],

                        const SizedBox(height: 20),

                        // ── Nurse Alert Banner ──
                        if (showNurseAlert)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red.shade500,
                                    size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Severe symptoms detected. The nurse will be automatically notified.',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (showNurseAlert)
                          const SizedBox(height: 12),

                        // ── Already contacted nurse ──
                        GestureDetector(
                          onTap: () => setModal(
                              () => nurseContacted = !nurseContacted),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: nurseContacted
                                  ? _purple.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: nurseContacted
                                    ? _purple.withOpacity(0.4)
                                    : _borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: nurseContacted
                                        ? _purple
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    border: Border.all(
                                      color: nurseContacted
                                          ? _purple
                                          : _borderColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: nurseContacted
                                      ? const Icon(Icons.check,
                                          size: 14,
                                          color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'I already contacted the nurse',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: _deepPurple,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Additional notes ──
                        Text('Additional notes (optional)',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _mutedPurple,
                            )),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderColor),
                          ),
                          child: TextField(
                            controller: notesCtrl,
                            maxLines: 3,
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: _deepPurple),
                            decoration: InputDecoration(
                              hintText:
                                  'Any additional context...',
                              hintStyle: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: const Color(0xFFB8B0CC)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Submit ──
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF6B5B8E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(32)),
                            ),
                            onPressed: (selectedIds.isEmpty && !showOtherField)
                                ? null
                                : () async {
                                    final member = SessionManager()
                                        .currentMember;
                                    final teamId = SessionManager()
                                        .currentCareTeam
                                        ?.id;
                                    if (teamId == null) return;

                                    // Build symptom strings with values
                                    final symptoms = <String>[];
                                    for (final id in selectedIds) {
                                      final def = kSymptomById[id];
                                      if (def == null) continue;
                                      final val = selectedValues[id];
                                      if (val != null) {
                                        symptoms.add('${def.name}: $val');
                                      } else {
                                        symptoms.add(def.name);
                                      }
                                    }

                                    if (showOtherField &&
                                        otherCtrl.text
                                            .trim()
                                            .isNotEmpty) {
                                      symptoms.add(
                                          'Other: ${otherCtrl.text.trim()}');
                                    }

                                    // Derive severity from worst value
                                    String severity = 'Mild';
                                    if (hasSevereValue) {
                                      severity = 'Severe';
                                    } else if (selectedValues.values
                                        .any((v) => v == 'Moderate')) {
                                      severity = 'Moderate';
                                    }
                                    // Alert symptoms always Severe
                                    if (hasAlert) severity = 'Severe';

                                    final event = SymptomEvent(
                                      id: _uuid.v4(),
                                      careTeamId: teamId,
                                      symptoms: symptoms,
                                      severity: severity,
                                      whatHappened:
                                          notesCtrl.text.trim().isEmpty
                                              ? null
                                              : notesCtrl.text.trim(),
                                      eventTime: DateTime.now(),
                                      createdByMemberId: member?.id,
                                      createdByMemberName:
                                          member?.name,
                                    );
                                    await _service
                                        .logSymptomEvent(event);
                                    if (!mounted) return;
                                    Navigator.pop(ctx);
                                    _loadEvents();
                                  },
                            child: Text('Log Symptoms',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Compact row showing a symptom name and its selectable options.
  Widget _optionRow({
    required String label,
    required List<String> options,
    required String current,
    required bool isAlert,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAlert ? Colors.red.shade200 : _borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isAlert)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 13, color: Colors.red.shade400),
                  ),
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAlert
                            ? Colors.red.shade700
                            : _deepPurple,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: options.map((opt) {
                final isSel = current == opt;
                return GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSel
                          ? _purple.withOpacity(0.15)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? _purple : _borderColor,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(opt,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel ? _purple : _mutedPurple,
                        )),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // ── Header ──
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
                          Text('Symptoms',
                              style: GoogleFonts.nunito(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: _deepPurple,
                              )),
                          Text('${_events.length} logged events',
                              style: GoogleFonts.nunito(
                                  fontSize: 11, color: _mutedPurple)),
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

              // ── Body ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: _purple))
                    : _events.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                20, 12, 20, 100),
                            itemCount: _events.length,
                            itemBuilder: (_, i) =>
                                _eventCard(_events[i]),
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
          onTap: _showLogSymptomModal,
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
                Text('Log Symptoms',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventCard(SymptomEvent event) {
    final time = event.eventTime != null
        ? DateFormat('MMM d · h:mm a').format(event.eventTime!)
        : '';
    final severityColor = {
          'Mild': const Color(0xFF4CAF50),
          'Moderate': const Color(0xFFFF9800),
          'Severe': const Color(0xFFF44336),
        }[event.severity] ??
        _mutedPurple;

    final hasSevere = (event.symptoms ?? [])
        .any((s) => kAlertSymptomNames.any((sv) => s.contains(sv)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSevere
              ? Colors.red.shade200
              : _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: severityColor.withOpacity(0.4)),
                ),
                child: Text(event.severity ?? 'Unknown',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: severityColor,
                    )),
              ),
              if (hasSevere) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 11, color: Colors.red.shade500),
                      const SizedBox(width: 3),
                      Text('Nurse notified',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: Colors.red.shade500,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(time,
                  style: GoogleFonts.nunito(
                      fontSize: 10, color: _lightPurple)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (event.symptoms ?? []).map((s) {
              final isSev = kAlertSymptomNames.any((sv) => s.contains(sv));
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSev
                      ? Colors.red.withOpacity(0.08)
                      : const Color(0xFFEDE8F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSev
                        ? Colors.red.shade200
                        : _borderColor,
                  ),
                ),
                child: Text(s,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: isSev
                          ? Colors.red.shade600
                          : _mutedPurple,
                    )),
              );
            }).toList(),
          ),
          if (event.whatHappened != null) ...[
            const SizedBox(height: 8),
            Text(event.whatHappened!,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: _mutedPurple,
                  fontStyle: FontStyle.italic,
                )),
          ],
          const SizedBox(height: 8),
          Text('Logged by ${event.createdByMemberName ?? 'Unknown'}',
              style: GoogleFonts.nunito(
                  fontSize: 10, color: _lightPurple)),
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
            child: const Icon(Icons.monitor_heart_outlined,
                size: 32, color: _lightPurple),
          ),
          const SizedBox(height: 16),
          Text('No symptoms logged',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _deepPurple,
              )),
          const SizedBox(height: 6),
          Text('Tap "Log Symptoms" to get started',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: _mutedPurple)),
        ],
      ),
    );
  }
}