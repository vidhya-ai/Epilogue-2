import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';
import '../domain/medication_data.dart';
import 'premium_bottom_nav.dart';
import 'widgets/animated_border_field.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _deepPurple = Color(0xFF2E2540);
const _purple = Color(0xFF7A64A4);
const _mutedPurple = Color(0xFF6C648B);
const _lightPurple = Color(0xFFB0A8C8);
const _borderColor = Color(0xFFD4CDDF);
const _cardBg = Color(0xFFF0EDF6);
const _bg1 = Color(0xFFE6E2EE);
const _bg2 = Color(0xFFDAD4E6);

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen>
    with SingleTickerProviderStateMixin {
  final _service = SupabaseService();
  final _uuid = const Uuid();
  List<Medication> _medications = [];
  bool _isLoading = true;
  String? _careTeamId;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadMedications();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      final careTeamId = SessionManager().currentCareTeam?.id;
      if (careTeamId == null) return;
      _careTeamId = careTeamId;
      final response = await _service.getMedications(careTeamId);
      if (!mounted) return;
      setState(() => _medications = response);
      _animCtrl.forward(from: 0); // always animate, even for empty state
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Deactivate by setting pattern to 'inactive' — preserves history
  Future<void> _deactivateMedication(Medication med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Deactivate Medication',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _deepPurple,
          ),
        ),
        content: Text(
          'This will deactivate "${med.name}" and preserve its history. You can add a new entry to replace it.',
          style: GoogleFonts.nunito(fontSize: 13, color: _mutedPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(color: _mutedPurple),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Deactivate',
              style: GoogleFonts.nunito(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        // Update pattern to 'inactive' to preserve history
        final updated = Medication(
          id: med.id,
          careTeamId: med.careTeamId,
          name: med.name,
          strength: med.strength,
          typicalDose: med.typicalDose,
          route: med.route,
          pattern: 'inactive',
          scheduleDetails: med.scheduleDetails,
          createdAt: med.createdAt,
          createdByMemberId: med.createdByMemberId,
        );
        await _service.updateMedication(updated);
        _loadMedications();
      } catch (e) {
        debugPrint('Error deactivating medication: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to deactivate: $e',
              style: GoogleFonts.nunito(fontSize: 13),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAddMedicationModal() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    String route = 'By mouth';
    String frequency = 'Regular schedule';
    String? prescribedDate;
    String? lastUpdatedBy;

    final routes = [
      'By mouth',
      'Sublingual',
      'Topical',
      'Injection',
      'Suppository',
      'Inhaled',
      'Other',
    ];
    final frequencies = [
      'Regular schedule',
      'PRN (As needed)',
      'Once daily',
      'Twice daily',
      'Three times daily',
      'Every 4 hours',
      'Every 6 hours',
      'Every 8 hours',
      'Every 12 hours',
      'At bedtime',
    ];

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
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
                  'Add medication',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: _deepPurple,
                  ),
                ),
                const SizedBox(height: 24),

                // Medication name — autocomplete from hospice list
                _modalLabel('Medication name'),
                _MedicationAutocomplete(
                  controller: nameCtrl,
                  onSelected: (med) {
                    nameCtrl.text = med.name;
                    // Auto-fill route if it matches a dropdown option
                    final autoRoute = _matchRoute(med.route, routes);
                    if (autoRoute != null) {
                      setModal(() => route = autoRoute);
                    }
                    // Auto-fill dose unit into the unit field
                    if (unitCtrl.text.isEmpty && med.doseUnit.isNotEmpty) {
                      final shortUnit = med.doseUnit.split(',').first.trim();
                      unitCtrl.text = shortUnit;
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Dosage + Unit row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _modalLabel('Dosage'),
                          _modalField(
                            controller: dosageCtrl,
                            hint: 'e.g. 10mg',
                            type: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _modalLabel('Unit'),
                          _modalField(
                            controller: unitCtrl,
                            hint: 'e.g. 1 tablet',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // How it's given (route)
                _modalLabel('How it\'s given'),
                _modalDropdown(
                  value: route,
                  items: routes,
                  onChanged: (v) => setModal(() => route = v!),
                ),
                const SizedBox(height: 16),

                // Frequency
                _modalLabel('Frequency'),
                _modalDropdown(
                  value: frequency,
                  items: frequencies,
                  onChanged: (v) => setModal(() => frequency = v!),
                ),
                const SizedBox(height: 16),

                // Schedule details
                _modalLabel('Schedule details'),
                _modalField(
                  controller: scheduleCtrl,
                  hint: 'e.g. Morning and Night',
                ),
                const SizedBox(height: 16),

                // Last prescribed date
                _modalLabel('Date last prescribed / updated by nurse'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _purple,
                            onPrimary: Colors.white,
                            surface: Color(0xFFF0EDF6),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModal(
                        () => prescribedDate = DateFormat(
                          'MMM d, yyyy',
                        ).format(picked),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: _mutedPurple,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          prescribedDate ?? 'Select date',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: prescribedDate != null
                                ? _deepPurple
                                : const Color(0xFFB8B0CC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Add button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B8E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please enter a medication name',
                              style: GoogleFonts.nunito(fontSize: 13),
                            ),
                            backgroundColor: _deepPurple,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }
                      if (_careTeamId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No care team found. Please log in again.',
                              style: GoogleFonts.nunito(fontSize: 13),
                            ),
                            backgroundColor: _deepPurple,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }

                      // ── Confirmation dialog ──
                      final confirmed = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => Dialog(
                          backgroundColor: const Color(0xFFF0EDF6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _purple.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medication_rounded,
                                    color: _purple,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Confirm medication',
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Please verify the details below are correct.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: _mutedPurple,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _confirmRow('Name', nameCtrl.text.trim()),
                                      if (dosageCtrl.text.trim().isNotEmpty)
                                        _confirmRow(
                                          'Dosage',
                                          dosageCtrl.text.trim(),
                                        ),
                                      if (unitCtrl.text.trim().isNotEmpty)
                                        _confirmRow(
                                          'Unit',
                                          unitCtrl.text.trim(),
                                        ),
                                      _confirmRow('Route', route),
                                      _confirmRow('Frequency', frequency),
                                      if (scheduleCtrl.text.trim().isNotEmpty)
                                        _confirmRow(
                                          'Schedule',
                                          scheduleCtrl.text.trim(),
                                        ),
                                      if (prescribedDate != null)
                                        _confirmRow(
                                          'Prescribed',
                                          prescribedDate!,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _mutedPurple,
                                          side: const BorderSide(
                                            color: _borderColor,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(dCtx, false),
                                        child: Text(
                                          'Go back',
                                          style: GoogleFonts.nunito(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF6B5B8E,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(dCtx, true),
                                        child: Text(
                                          'Confirm',
                                          style: GoogleFonts.nunito(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (confirmed != true) return;

                      final member = SessionManager().currentMember;
                      final newMed = Medication(
                        id: _uuid.v4(),
                        careTeamId: _careTeamId,
                        name: nameCtrl.text.trim(),
                        strength: dosageCtrl.text.trim().isEmpty
                            ? null
                            : dosageCtrl.text.trim(),
                        typicalDose: unitCtrl.text.trim().isEmpty
                            ? null
                            : unitCtrl.text.trim(),
                        route: route,
                        pattern: frequency,
                        scheduleDetails: scheduleCtrl.text.trim().isEmpty
                            ? prescribedDate
                            : '${scheduleCtrl.text.trim()}${prescribedDate != null ? ' · Prescribed: $prescribedDate' : ''}',
                        createdAt: DateTime.now(),
                        createdByMemberId: member?.id,
                      );
                      try {
                        await _service.addMedication(newMed);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _loadMedications();
                      } catch (e) {
                        debugPrint('Error adding medication: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to add medication: $e',
                              style: GoogleFonts.nunito(fontSize: 13),
                            ),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Add medication',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMeds = _medications
        .where((m) => m.pattern != 'inactive')
        .toList();
    final inactiveMeds = _medications
        .where((m) => m.pattern == 'inactive')
        .toList();

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
                      child: Text(
                        'Medications',
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: _deepPurple,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadMedications,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1DCEA),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: _borderColor),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: _mutedPurple,
                        ),
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
                        child: CircularProgressIndicator(color: _purple),
                      )
                    : _medications.isEmpty
                    ? _emptyState()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: activeMeds.isEmpty
                            ? _emptyState()
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  100,
                                ),
                                children: [
                                  // Active meds
                                  Text(
                                    'Active',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _mutedPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...activeMeds.map(
                                    (m) => _medCard(m, isActive: true),
                                  ),

                                  // Inactive meds
                                  if (inactiveMeds.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Text(
                                      'Inactive / History',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _lightPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...inactiveMeds.map(
                                      (m) => _medCard(m, isActive: false),
                                    ),
                                  ],
                                ],
                              ),
                      ),
              ),

              // ── Bottom Nav ──
              const PremiumBottomNav(currentIndex: 1),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      // ── FAB ──
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: GestureDetector(
          onTap: _showAddMedicationModal,
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
                  'Add Medication',
                  style: GoogleFonts.nunito(
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

  // ─── Med Card ──────────────────────────────────────────────────────────────
  Widget _medCard(Medication med, {required bool isActive}) {
    final isPrn = med.pattern?.toLowerCase().contains('prn') ?? false;
    final dateStr = med.createdAt != null
        ? DateFormat('MMM d, yyyy').format(med.createdAt!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.75)
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? _borderColor : _borderColor.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF8E7CB1).withOpacity(0.15)
                        : _borderColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    size: 18,
                    color: isActive ? _purple : _lightPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name ?? 'Unknown',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isActive ? _deepPurple : _lightPurple,
                        ),
                      ),
                      if (med.strength != null)
                        Text(
                          med.strength!,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: _mutedPurple,
                          ),
                        ),
                    ],
                  ),
                ),
                // PRN badge
                if (isPrn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      'PRN',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _purple,
                      ),
                    ),
                  ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _lightPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Inactive',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: _lightPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isActive)
                  GestureDetector(
                    onTap: () => _deactivateMedication(med),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1DCEA),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: _mutedPurple,
                      ),
                    ),
                  ),
              ],
            ),

            if (med.typicalDose != null ||
                med.route != null ||
                med.pattern != null) ...[
              const SizedBox(height: 12),
              const Divider(color: _borderColor, height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (med.typicalDose != null)
                    _infoChip(Icons.scale_outlined, med.typicalDose!),
                  if (med.route != null)
                    _infoChip(Icons.directions_outlined, med.route!),
                  if (med.pattern != null && med.pattern != 'inactive')
                    _infoChip(Icons.schedule_outlined, med.pattern!),
                ],
              ),
            ],

            if (med.scheduleDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                med.scheduleDetails!,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: _mutedPurple,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            if (dateStr != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 11,
                    color: _lightPurple,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Added $dateStr',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: _lightPurple,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _mutedPurple),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: _mutedPurple,
              fontWeight: FontWeight.w500,
            ),
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
              Icons.medication_outlined,
              size: 32,
              color: _lightPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No medications yet',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 12, 12, 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Medication" to get started',
            style: GoogleFonts.nunito(fontSize: 13, color: _mutedPurple),
          ),
        ],
      ),
    );
  }

  // ─── Modal helpers ─────────────────────────────────────────────────────────
  Widget _modalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _mutedPurple,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _modalField({
    required TextEditingController controller,
    required String hint,
    TextInputType? type,
  }) {
    return AnimatedBorderField(
      controller: controller,
      hint: hint,
      keyboardType: type,
    );
  }

  Widget _modalDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _mutedPurple),
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: _deepPurple,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: GoogleFonts.nunito(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Confirmation detail row ───────────────────────────────────────────────
  static Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _mutedPurple,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper ──────────────────────────────────────────────────────────────────
/// Maps the Excel "Typical route/form" text to one of the dropdown options.
String? _matchRoute(String excelRoute, List<String> dropdownRoutes) {
  final lower = excelRoute.toLowerCase();
  if (lower.contains('oral') || lower.contains('by mouth')) return 'By mouth';
  if (lower.contains('sublingual') || lower.contains('sl '))
    return 'Sublingual';
  if (lower.contains('topical') ||
      lower.contains('patch') ||
      lower.contains('cream'))
    return 'Topical';
  if (lower.contains('inject') ||
      lower.contains('iv') ||
      lower.contains('sc ') ||
      lower.contains('im '))
    return 'Injection';
  if (lower.contains('suppository') || lower.contains('rectal'))
    return 'Suppository';
  if (lower.contains('inhal') ||
      lower.contains('nebuliz') ||
      lower.contains('mdi'))
    return 'Inhaled';
  return null; // leave at default
}

// ─── Medication autocomplete ─────────────────────────────────────────────────
class _MedicationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final void Function(MedicationInfo) onSelected;

  const _MedicationAutocomplete({
    required this.controller,
    required this.onSelected,
  });

  @override
  State<_MedicationAutocomplete> createState() =>
      _MedicationAutocompleteState();
}

class _MedicationAutocompleteState extends State<_MedicationAutocomplete>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Color?> _borderTween;
  bool _focused = false;
  List<MedicationInfo> _suggestions = [];

  static const _violet = Color(0xFF7A64A4);
  static const _idle = Color(0xFFD4CDDF);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _borderTween = ColorTween(
      begin: _idle,
      end: _violet,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _suggestions = kHospiceMedications.where((m) {
        return m.name.toLowerCase().contains(query) ||
            m.brand.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onFocus(bool focused) {
    setState(() => _focused = focused);
    focused ? _anim.forward() : _anim.reverse();
    if (!focused) {
      // Delay hiding suggestions so tap on item registers first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _suggestions = []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          onFocusChange: _onFocus,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_focused ? 0.95 : 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _borderTween.value ?? _idle,
                  width: _focused ? 1.8 : 1.0,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: _violet.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: child,
            ),
            child: TextField(
              controller: widget.controller,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: _deepPurple,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search medication name or brand...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFFB8B0CC),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _mutedPurple,
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: _mutedPurple,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _idle),
              boxShadow: [
                BoxShadow(
                  color: _violet.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: _idle.withOpacity(0.5)),
                itemBuilder: (context, i) {
                  final med = _suggestions[i];
                  return InkWell(
                    onTap: () {
                      widget.controller.text = med.name;
                      widget.controller.selection = TextSelection.collapsed(
                        offset: med.name.length,
                      );
                      setState(() => _suggestions = []);
                      widget.onSelected(med);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.displayName,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _deepPurple,
                            ),
                          ),
                          if (med.primaryUse.isNotEmpty)
                            Text(
                              med.primaryUse,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: _mutedPurple,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
