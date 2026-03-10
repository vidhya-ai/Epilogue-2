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
import 'history_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _deepPurple = Color(0xFF2E2540);
const _purple = Color(0xFF7A64A4);
const _mutedPurple = Color(0xFF6C648B);
const _lightPurple = Color(0xFFB0A8C8);
const _borderColor = Color(0xFFD4CDDF);
const _cardBg = Color(0xFFF0EDF6);
const _bg1 = Color(0xFF74659A);
const _bg2 = Color(0xFFDFDBE5);

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
  Map<String, DateTime> _lastAdministeredByMedicationId = {};
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
      final results = await Future.wait([
        _service.getMedications(careTeamId),
        _service.getDoseLogs(careTeamId),
      ]);
      final response = results[0] as List<Medication>;
      final doseLogs = results[1] as List<DoseLog>;
      final lastAdministeredByMedicationId = <String, DateTime>{};

      for (final log in doseLogs) {
        final medicationId = log.medicationId;
        final doseTime = log.doseTime;
        if (medicationId == null || doseTime == null) continue;
        lastAdministeredByMedicationId.putIfAbsent(medicationId, () => doseTime);
      }

      if (!mounted) return;
      setState(() {
        _medications = response;
        _lastAdministeredByMedicationId = lastAdministeredByMedicationId;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- Just Administered (Log Medication Given) ----------
  Future<void> _showAdministerDialog(Medication med) async {
    DateTime selectedTime = DateTime.now();
    final member = SessionManager().currentMember;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final dateStr = DateFormat('MMM d, yyyy').format(selectedTime);
            final timeStr = DateFormat('h:mm a').format(selectedTime);
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Log Administration',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    med.name ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Timestamp row — tappable to edit
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: ctx,
                        initialDate: selectedTime,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate == null) return;
                      if (!ctx.mounted) return;
                      final pickedTime = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(selectedTime),
                      );
                      if (pickedTime == null) return;
                      setModalState(() {
                        selectedTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _purple.withOpacity(0.20)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 20,
                            color: _purple,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$dateStr  ·  $timeStr',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _deepPurple,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: _mutedPurple,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tap to change date/time',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: _mutedPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final log = DoseLog(
                          id: _uuid.v4(),
                          careTeamId: _careTeamId,
                          medicationId: med.id,
                          medicationName: med.name,
                          doseTime: selectedTime,
                          amountGiven: med.typicalDose,
                          whoGave: member?.name,
                          loggedByMemberId: member?.id,
                          loggedByMemberName: member?.name,
                        );
                        try {
                          await _service.logDose(log);
                          if (!ctx.mounted) return;
                          await _loadMedications();
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Dose logged for ${med.name}',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: _purple,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint('Error logging dose: $e');
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to log dose: $e',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
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
                        'Confirm Administration',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Deprescribe ----------
  Future<void> _showDeprescribeDialog(Medication med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Deprescribe Medication',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _deepPurple,
          ),
        ),
        content: Text(
          'This will deprescribe "${med.name}" and preserve its history. You can add a new entry to replace it.',
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: _deepPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: _deepPurple,
                fontWeight: FontWeight.w600,
              ),
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
              'Deprescribe',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
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
          deprescribedAt: DateTime.now(),
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
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
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

  Future<bool> _confirmMedicationDetails({
    required String patientName,
    required Medication medication,
  }) async {
    final details = <MapEntry<String, String>>[
      MapEntry('Medication name', medication.name ?? 'Unknown'),
      if ((medication.strength ?? '').isNotEmpty)
        MapEntry('Dosage', medication.strength!),
      if ((medication.typicalDose ?? '').isNotEmpty)
        MapEntry('Unit', medication.typicalDose!),
      if ((medication.route ?? '').isNotEmpty)
        MapEntry('Route', medication.route!),
      if ((medication.pattern ?? '').isNotEmpty)
        MapEntry('Frequency', medication.pattern!),
      if ((medication.scheduleDetails ?? '').isNotEmpty)
        MapEntry('Schedule details', medication.scheduleDetails!),
      if ((medication.notes ?? '').isNotEmpty)
        MapEntry('Notes', medication.notes!),
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm ${medication.name ?? 'Medication'} for $patientName',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _deepPurple,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review all details before saving this medication.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ...details.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: _deepPurple,
                      ),
                      children: [
                        TextSpan(
                          text: '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: entry.value,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Go Back',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _deepPurple,
              ),
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
              'Confirm',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  // ---------- Add Medication Modal ----------
  void _showAddMedicationModal() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    List<String> routeOptions = [
      'By mouth',
      'Sublingual',
      'Topical',
      'Injection',
      'Suppository',
      'Inhaled',
      'Other',
    ];
    String route = 'By mouth';
    // Unit field: abbreviation only
    List<String> unitOptions = ['mg', 'mcg', 'mL', 'tabs', 'caps', 'drops'];
    String selectedUnit = 'mg';

    // As needed is mutually exclusive
    bool isPrn = false;

    String? selectedFreqType = 'hour'; // 'hour', 'daily', 'day'
    int hoursValue = 4;
    int daysValue = 2;
    String dailyFrequency = 'Once daily';
    String? prescribedDate;

    String getFreqPattern() {
      if (isPrn) return 'PRN (As Needed)';
      switch (selectedFreqType) {
        case 'hour':
          return 'Every $hoursValue hours';
        case 'daily':
          return dailyFrequency;
        case 'day':
          return 'Every $daysValue days';
        default:
          return 'Not set';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
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
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  'Add medication',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _deepPurple,
                  ),
                ),
                const SizedBox(height: 24),

                _modalLabel('Medication name'),
                _MedicationAutocomplete(
                  controller: nameCtrl,
                  onSelected: (med) {
                    nameCtrl.text = med.name;
                    setModal(() {
                      routeOptions = med.routeOptions;
                      route = routeOptions.first;
                      unitOptions = med.unitOptions;
                      selectedUnit = unitOptions.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _modalLabel('Dosage'),
                          _modalField(
                            controller: dosageCtrl,
                            hint: 'e.g. 10',
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
                          _modalDropdown(
                            value: selectedUnit,
                            items: unitOptions,
                            onChanged: (v) => setModal(() => selectedUnit = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _modalLabel('How it\'s given'),
                _modalDropdown(
                  value: route,
                  items: routeOptions,
                  onChanged: (v) => setModal(() => route = v!),
                ),
                const SizedBox(height: 24),

                // As Needed Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isPrn ? _purple : _borderColor),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'As needed (PRN)',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _deepPurple,
                      ),
                    ),
                    subtitle: Text(
                      'Given only when symptoms occur',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: _mutedPurple,
                      ),
                    ),
                    value: isPrn,
                    activeColor: _purple,
                    onChanged: (val) => setModal(() => isPrn = val),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Frequency Fields - Grayed out if PRN
                Opacity(
                  opacity: isPrn ? 0.35 : 1.0,
                  child: IgnorePointer(
                    ignoring: isPrn,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _modalLabel('Frequency'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFrequencyOption(
                                title: 'Every few hours',
                                isSelected: selectedFreqType == 'hour',
                                onTap: () => setModal(
                                  () => selectedFreqType = 'hour',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFrequencyOption(
                                title: 'Once daily',
                                isSelected: selectedFreqType == 'daily',
                                onTap: () => setModal(
                                  () => selectedFreqType = 'daily',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFrequencyOption(
                                title: 'Every few days',
                                isSelected: selectedFreqType == 'day',
                                onTap: () => setModal(
                                  () => selectedFreqType = 'day',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (selectedFreqType == 'hour') ...[
                          _buildFriendlyStepper(
                            label: 'hours',
                            value: hoursValue,
                            onDecrement: () {
                              if (hoursValue > 1) setModal(() => hoursValue--);
                            },
                            onIncrement: () => setModal(() => hoursValue++),
                          ),
                        ],
                        if (selectedFreqType == 'daily') ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Give this medicine',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: dailyFrequency,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: _deepPurple,
                                      ),
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _deepPurple,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Once daily',
                                          child: Text('Once daily'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Twice daily',
                                          child: Text('Twice daily'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Thrice daily',
                                          child: Text('Thrice daily'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setModal(() => dailyFrequency = value);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (selectedFreqType == 'day') ...[
                          _buildFriendlyStepper(
                            label: 'days',
                            value: daysValue,
                            onDecrement: () {
                              if (daysValue > 1) setModal(() => daysValue--);
                            },
                            onIncrement: () => setModal(() => daysValue++),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.78),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Text(
                            isPrn
                                ? 'This medication is given only when needed.'
                                : 'Frequency summary: ${getFreqPattern()}',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _modalLabel('Notes (Optional)'),
                _modalField(controller: notesCtrl, hint: 'e.g. Take with food'),
                const SizedBox(height: 16),

                _modalLabel('Prescribed Date'),
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
                          size: 20,
                          color: _deepPurple,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          prescribedDate ?? 'Select date',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: prescribedDate != null
                                ? _deepPurple
                                : _mutedPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

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
                      if (nameCtrl.text.trim().isEmpty) return;
                      if (_careTeamId == null) return;

                      final member = SessionManager().currentMember;
                      final patientName =
                          SessionManager().currentCareTeam?.patientFirstName ??
                          'Patient';
                      final newMed = Medication(
                        id: _uuid.v4(),
                        careTeamId: _careTeamId,
                        name: nameCtrl.text.trim(),
                        strength: dosageCtrl.text.trim().isEmpty
                            ? null
                            : dosageCtrl.text.trim(),
                        typicalDose: selectedUnit,
                        route: route,
                        pattern: getFreqPattern(),
                        scheduleDetails: scheduleCtrl.text.trim().isEmpty
                            ? prescribedDate
                            : '${scheduleCtrl.text.trim()}${prescribedDate != null ? ' · Prescribed: $prescribedDate' : ''}',
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                        createdAt: DateTime.now(),
                        createdByMemberId: member?.id,
                      );
                      try {
                        final confirmed = await _confirmMedicationDetails(
                          patientName: patientName,
                          medication: newMed,
                        );
                        if (!confirmed) return;
                        await _service.addMedication(newMed);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _loadMedications();
                      } catch (e) {
                        debugPrint('Error adding medication: $e');
                      }
                    },
                    child: Text(
                      'Save Medication',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
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
          },
        );
      },
    );
  }

  Widget _buildFriendlyStepper({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Give every',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _deepPurple,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: _deepPurple),
                ),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _deepPurple,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: _purple),
                ),
              ),
            ],
          ),
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _purple : Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _purple : _borderColor,
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : _deepPurple,
              ),
            ),
          ],
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
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
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
                            'Medications',
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
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
                      padding:const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: _borderColor, thickness: 1),
                    ),
                

              const SizedBox(height: 16),

              // ── Body with Pull-to-Refresh ──
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMedications,
                  color: _purple,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _medications.isEmpty
                      ? _emptyState()
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              if (activeMeds.isNotEmpty) ...[
                                Text(
                                  'Active Prescriptions',
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...activeMeds.map(
                                  (m) => MedicationCard(
                                    med: m,
                                    isActive: true,
                                    lastAdministeredAt:
                                        _lastAdministeredByMedicationId[m.id],
                                    onDeprescribe: () =>
                                        _showDeprescribeDialog(m),
                                    onLogAdministered: () =>
                                        _showAdministerDialog(m),
                                  ),
                                ),
                              ],

                              // Deprescribed shown directly underneath in a different color
                              if (inactiveMeds.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Deprescribed',
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...inactiveMeds.map(
                                  (m) => MedicationCard(
                                    med: m,
                                    isActive: false,
                                    lastAdministeredAt:
                                        _lastAdministeredByMedicationId[m.id],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
              const PremiumBottomNav(currentIndex: 0),
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
                  color: _purple.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Add Medication',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Modal & Empty State helpers ─────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 103, 102, 102).withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.medication_outlined,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No medications yet',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color.fromARGB(255, 9, 9, 9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Medication" to get started',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: const Color.fromARGB(255, 5, 5, 5).withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _deepPurple,
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
          icon: const Icon(Icons.keyboard_arrow_down, color: _deepPurple),
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: _deepPurple,
            fontWeight: FontWeight.w700,
          ),
          items: items
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Medication Card (Stateful for Expansion) ───────────────────────────────
class MedicationCard extends StatefulWidget {
  final Medication med;
  final bool isActive;
  final DateTime? lastAdministeredAt;
  final VoidCallback? onDeprescribe;
  final VoidCallback? onLogAdministered;

  const MedicationCard({
    super.key,
    required this.med,
    required this.isActive,
    this.lastAdministeredAt,
    this.onDeprescribe,
    this.onLogAdministered,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  bool _expanded = false;

  String _lastAdministeredLabel() {
    final lastAdministeredAt = widget.lastAdministeredAt;
    if (lastAdministeredAt == null) {
      return 'Last administered: Not yet logged';
    }
    final formatted = DateFormat('MMM d, yyyy h:mm a').format(lastAdministeredAt);
    return 'Last administered: $formatted';
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _deepPurple),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: _deepPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.med;
    final isPrn = med.pattern?.toLowerCase().contains('prn') ?? false;

    // Dim the color significantly if inactive
    final cardColor = widget.isActive
        ? Colors.white.withOpacity(0.95)
        : const Color(0xFFE0E0E0);
    final inactiveTextColor = Colors.black87;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isActive ? _borderColor : const Color(0xFFB0B0B0),
          ),
          boxShadow: _expanded && widget.isActive
              ? [
                  BoxShadow(
                    color: _purple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? const Color(0xFF8E7CB1).withOpacity(0.15)
                          : const Color(0xFFC6C6C6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      size: 20,
                      color: widget.isActive ? _purple : Colors.black87,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: widget.isActive
                                ? _deepPurple
                                : inactiveTextColor,
                          ),
                        ),
                        if (med.strength != null)
                          Text(
                            med.strength!,
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: widget.isActive
                                  ? _deepPurple
                                  : inactiveTextColor,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          _lastAdministeredLabel(),
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPrn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PRN',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _deepPurple,
                        ),
                      ),
                    ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _mutedPurple.withOpacity(0.5),
                  ),
                ],
              ),

              if (med.typicalDose != null ||
                  med.route != null ||
                  med.pattern != null) ...[
                const SizedBox(height: 12),
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

              // Expanded Action Area
              if (_expanded) ...[
                const SizedBox(height: 16),
                const Divider(color: _borderColor, height: 1),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _purple.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Actions',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _deepPurple,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'administer') {
                        widget.onLogAdministered?.call();
                      } else if (value == 'history') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      } else if (value == 'deprescribe') {
                        widget.onDeprescribe?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (widget.isActive)
                        PopupMenuItem(
                          value: 'administer',
                          child: Text(
                            'Administer',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      PopupMenuItem(
                        value: 'history',
                        child: Text(
                          'View History',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.isActive)
                        PopupMenuItem(
                          value: 'deprescribe',
                          child: Text(
                            'Deprescribe',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
                fontSize: 16,
                color: const Color(0xFF2E2540),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search medication name or brand...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 16,
                  color: const Color(0xFF6C648B),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: Color(0xFF2E2540),
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 20,
                          color: Color(0xFF2E2540),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E2540),
                            ),
                          ),
                          if (med.primaryUse.isNotEmpty)
                            Text(
                              med.primaryUse,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: const Color(0xFF6C648B),
                                fontWeight: FontWeight.w600,
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

