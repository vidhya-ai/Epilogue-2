import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';
import 'widgets/animated_border_field.dart';

// ─── Hospice Data Model ───────────────────────────────────────────────────────
// Columns: name, address, zipCode, county, state, coverageArea, branchOf
// TODO: Vidhya to ask data analyst to populate zip code and county columns
class HospiceOrg {
  final String id;
  final String name;
  final String address;
  final String zipCode;
  final String county;
  final String state;
  final String coverageArea; // 30-mile radius confirmed for launch
  final String? branchOf; // null = main office; parent id if branch
  final String? nurseLineNumber; // 24/7 nurse on-call line

  const HospiceOrg({
    required this.id,
    required this.name,
    required this.address,
    required this.zipCode,
    required this.county,
    required this.state,
    required this.coverageArea,
    this.branchOf,
    this.nurseLineNumber,
  });
}

// ─── Static hospice table (replace with Supabase query later) ─────────────────
const List<HospiceOrg> _hospiceList = [
  HospiceOrg(
    id: 'valley_main',
    name: 'Valley Care Hospice Center',
    address: '123 Valley Road, Springfield, IL',
    zipCode: '62701',
    county: 'Sangamon',
    state: 'IL',
    coverageArea: '30-mile radius',
    nurseLineNumber: '555-100-1001',
  ),
  HospiceOrg(
    id: 'valley_north',
    name: 'Valley Care Hospice Center — North Branch',
    address: '450 North Valley Pkwy, Lincoln, IL',
    zipCode: '62656',
    county: 'Logan',
    state: 'IL',
    coverageArea: '30-mile radius',
    branchOf: 'valley_main',
    nurseLineNumber: '555-100-1001',
  ),
  HospiceOrg(
    id: 'serenity',
    name: 'Serenity Pathways Palliative',
    address: '456 Serenity Lane, Chicago, IL',
    zipCode: '60601',
    county: 'Cook',
    state: 'IL',
    coverageArea: '30-mile radius',
    nurseLineNumber: '555-200-2002',
  ),
  HospiceOrg(
    id: 'grace',
    name: 'Graceful Transitions Hospice',
    address: '789 Grace Ave, Naperville, IL',
    zipCode: '60540',
    county: 'DuPage',
    state: 'IL',
    coverageArea: '30-mile radius',
    nurseLineNumber: '555-300-3003',
  ),
  HospiceOrg(
    id: 'north',
    name: 'North Star Comfort Care',
    address: '321 North Star Blvd, Rockford, IL',
    zipCode: '61101',
    county: 'Winnebago',
    state: 'IL',
    coverageArea: '30-mile radius',
    nurseLineNumber: '555-400-4004',
  ),
];

// ─── US States (two-letter codes) ─────────────────────────────────────────────
const _usStates = [
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
  'DC',
];

// ─── Phone number formatter + validator ───────────────────────────────────────
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue newVal,
  ) {
    final digits = newVal.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newVal.copyWith(text: '');
    String formatted;
    if (digits.length <= 3) {
      formatted = '($digits';
    } else if (digits.length <= 6) {
      formatted = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      formatted =
          '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, digits.length.clamp(0, 10))}';
    }
    return newVal.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ignore: unused_element
bool _isValidPhone(String phone) =>
    phone.replaceAll(RegExp(r'\D'), '').length == 10;

// ─── Colors ───────────────────────────────────────────────────────────────────
const _bg1 = Color(0xFFE6E2EE);
const _bg2 = Color(0xFFDAD4E6);
const _purple = Color(0xFF7A64A4);
const _deepPurple = Color(0xFF443C63);
const _mutedPurple = Color(0xFF6C648B);
const _borderColor = Color(0xFFD4CDDF);
const _cardBg = Color(0xFFF0EDF6);

class HospiceSetupScreen extends StatefulWidget {
  final String patientName;
  final String caregiverName;
  final String email;

  const HospiceSetupScreen({
    super.key,
    required this.patientName,
    required this.caregiverName,
    required this.email,
  });

  @override
  State<HospiceSetupScreen> createState() => _HospiceSetupScreenState();
}

class _HospiceSetupScreenState extends State<HospiceSetupScreen>
    with SingleTickerProviderStateMixin {
  // ── Hospice selection ──
  HospiceOrg? _selectedHospice;
  bool _showSearch = false;
  String _searchQuery = '';
  bool _showDropdown = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  // ── Care address ──
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _selectedState;
  final _zipCtrl = TextEditingController();

  // County is derived automatically via Google Geocoding API (not user input)
  String? _derivedCounty;
  bool _derivingCounty = false;

  // ── Loading ──
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Main hospices only for dropdown
  List<HospiceOrg> get _mainHospices =>
      _hospiceList.where((h) => h.branchOf == null).toList();

  // Branches under a given parent
  List<HospiceOrg> _branchesOf(String parentId) =>
      _hospiceList.where((h) => h.branchOf == parentId).toList();

  // Search filters by name, county, or zip
  List<HospiceOrg> get _filteredHospices {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _hospiceList;
    return _hospiceList
        .where(
          (h) =>
              h.name.toLowerCase().contains(q) ||
              h.county.toLowerCase().contains(q) ||
              h.zipCode.contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  // ── Derive county via Google Geocoding API ────────────────────────────────
  // TODO: Replace stub with real HTTP call:
  // GET https://maps.googleapis.com/maps/api/geocode/json
  //     ?address={street},{city},{state}+{zip}&key=YOUR_API_KEY
  // Parse 'administrative_area_level_2' from address_components
  // Zip code alone is insufficient — two addresses 1 mile apart can be
  // in different counties.
  Future<void> _deriveCounty() async {
    final street = _streetCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = _selectedState;
    final zip = _zipCtrl.text.trim();
    if (street.isEmpty || city.isEmpty || state == null || zip.length < 5) {
      return;
    }
    setState(() {
      _derivingCounty = true;
      _derivedCounty = null;
    });
    await Future.delayed(const Duration(milliseconds: 800)); // stub
    if (mounted) {
      setState(() {
        _derivingCounty = false;
        _derivedCounty = 'Pending Google API integration';
      });
    }
  }

  Future<void> _continueToDashboard() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final teamId = uuid.v4();
      final memberId = uuid.v4();
      // Generate a 4-digit PIN so the member can rejoin / login later
      final pin = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000))
          .toString();

      final careTeam = CareTeam(
        id: teamId,
        patientFirstName: widget.patientName.trim().isEmpty
            ? null
            : widget.patientName.trim(),
        hospiceOrgId: _selectedHospice?.id,
        nurseLineNumber: _selectedHospice?.nurseLineNumber,
        createdAt: now,
      );

      final member = Member(
        id: memberId,
        careTeamId: teamId,
        name: widget.caregiverName.trim().isEmpty
            ? 'Caregiver'
            : widget.caregiverName.trim(),
        email: widget.email.trim().isEmpty
            ? 'unknown@example.com'
            : widget.email.trim(),
        role: 'family',
        isAdmin: true,
        accessPin: pin,
        joinedAt: now,
        lastActive: now,
      );

      // Save to Supabase — must succeed for medication tracking to work
      final service = SupabaseService();
      await service.createCareTeam(careTeam);
      await service.addMember(member);

      await SessionManager().setSession(careTeam, member);

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      debugPrint('Setup error: $e');
      if (mounted) _showSnack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(fontSize: 13)),
        backgroundColor: _deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_showDropdown) setState(() => _showDropdown = false);
      },
      child: Scaffold(
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _backButton(),
                      const SizedBox(height: 28),
                      _stepBadge(),
                      const SizedBox(height: 16),
                      _title(),
                      const SizedBox(height: 32),
                      _sectionDivider(),
                      const SizedBox(height: 28),

                      // ══════════════════════════════════════
                      // SECTION 1 — Select Your Hospice Provider
                      // ══════════════════════════════════════
                      _sectionLabel('Select Your Hospice Provider'),
                      const SizedBox(height: 10),

                      // Primary dropdown (shows name only when selected)
                      _hospiceDropdown(),

                      // Show selected hospice name only — no contact info here
                      if (_selectedHospice != null) ...[
                        const SizedBox(height: 10),
                        _selectedHospiceNameDisplay(),
                      ],

                      const SizedBox(height: 12),

                      // "Can't find your provider? Search" secondary option
                      GestureDetector(
                        onTap: () => setState(() {
                          _showSearch = !_showSearch;
                          if (_showSearch) {
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _searchFocus.requestFocus(),
                            );
                          } else {
                            _searchCtrl.clear();
                            _searchQuery = '';
                            _showDropdown = false;
                          }
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              size: 15,
                              color: _purple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Can't find your provider? Search",
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: _purple,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: _purple,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search box + results (toggled)
                      if (_showSearch) ...[
                        const SizedBox(height: 12),
                        _searchBox(),
                        if (_showDropdown) _searchResults(),
                      ],

                      const SizedBox(height: 32),

                      // ══════════════════════════════════════
                      // SECTION 2 — Care Address
                      // ══════════════════════════════════════
                      _sectionLabel('Where will care be delivered?'),
                      const SizedBox(height: 4),
                      Text(
                        'Care will be delivered at this address.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: _mutedPurple,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Street Address
                      _fieldLabel('Street Address'),
                      _inputField(
                        controller: _streetCtrl,
                        hint: 'e.g. 1234 Elm Street',
                        icon: Icons.home_outlined,
                        onChanged: (_) => _deriveCounty(),
                      ),
                      const SizedBox(height: 12),

                      // City
                      _fieldLabel('City'),
                      _inputField(
                        controller: _cityCtrl,
                        hint: 'e.g. Springfield',
                        icon: Icons.location_city_outlined,
                        onChanged: (_) => _deriveCounty(),
                      ),
                      const SizedBox(height: 12),

                      // State + Zip side by side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('State'),
                                _stateDropdown(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Zip Code'),
                                _inputField(
                                  controller: _zipCtrl,
                                  hint: '00000',
                                  icon: Icons.pin_drop_outlined,
                                  type: TextInputType.number,
                                  maxLength: 5,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (_) => _deriveCounty(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // County status — auto-derived, never shown as editable
                      if (_derivingCounty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Determining county...',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: _mutedPurple,
                              ),
                            ),
                          ],
                        ),
                      ] else if (_derivedCounty != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: _purple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _derivedCounty!,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: _mutedPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 44),
                      _continueButton(),
                      const SizedBox(height: 16),
                      _privacyNote(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Primary dropdown — shows branches under parents ──────────────────────
  Widget _hospiceDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HospiceOrg>(
          value: _selectedHospice,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select a hospice provider',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFFB8B0CC),
              ),
            ),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down, color: _mutedPurple),
          ),
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
          items: [
            // Main offices
            ..._mainHospices.map((h) {
              final branches = _branchesOf(h.id);
              return DropdownMenuItem<HospiceOrg>(
                value: h,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        h.name,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _deepPurple,
                        ),
                      ),
                      if (branches.isNotEmpty)
                        Text(
                          '${branches.length} branch location${branches.length > 1 ? 's' : ''}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: _mutedPurple,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            // Branch locations — indented with vertical line
            ..._hospiceList
                .where((h) => h.branchOf != null)
                .map(
                  (h) => DropdownMenuItem<HospiceOrg>(
                    value: h,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28, right: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _borderColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.name,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: _mutedPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
          onChanged: (val) => setState(() {
            _selectedHospice = val;
            _showSearch = false;
            _searchCtrl.clear();
            _searchQuery = '';
            _showDropdown = false;
          }),
        ),
      ),
    );
  }

  // ─── Selected hospice — name only, no contact info ────────────────────────
  Widget _selectedHospiceNameDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 15, color: _purple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedHospice!.name,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _purple,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedHospice = null),
            child: const Icon(Icons.close, size: 16, color: _mutedPurple),
          ),
        ],
      ),
    );
  }

  // ─── Search box ───────────────────────────────────────────────────────────
  Widget _searchBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showDropdown ? _purple : _borderColor,
          width: _showDropdown ? 2 : 1.5,
        ),
        boxShadow: _showDropdown
            ? [
                BoxShadow(
                  color: _purple.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: _deepPurple,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (v) => setState(() {
          _searchQuery = v;
          _showDropdown = v.isNotEmpty;
        }),
        onTap: () =>
            setState(() => _showDropdown = _searchCtrl.text.isNotEmpty),
        decoration: InputDecoration(
          hintText: 'Search by name, county, or zip code...',
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFFB8B0CC),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: _mutedPurple,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: _mutedPurple),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _showDropdown = false;
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ─── Search results ───────────────────────────────────────────────────────
  Widget _searchResults() {
    final results = _filteredHospices;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No providers found. Try a different search.',
                style: GoogleFonts.nunito(fontSize: 13, color: _mutedPurple),
              ),
            )
          : Column(
              children: results.map((h) {
                final isBranch = h.branchOf != null;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    _selectedHospice = h;
                    _showDropdown = false;
                    _showSearch = false;
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      isBranch ? 28 : 16,
                      14,
                      16,
                      14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _borderColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_hospital_outlined,
                            size: 18,
                            color: _purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.name,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: isBranch
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: _deepPurple,
                                ),
                              ),
                              Text(
                                '${h.county} County · ${h.zipCode} · ${h.coverageArea}',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: _mutedPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: _mutedPurple,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ─── State two-letter dropdown ─────────────────────────────────────────────
  Widget _stateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          isExpanded: true,
          hint: Text(
            'State',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: const Color(0xFFB8B0CC),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: _mutedPurple,
          ),
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
          items: _usStates
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: GoogleFonts.nunito(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() => _selectedState = v);
            _deriveCounty();
          },
        ),
      ),
    );
  }

  // ─── Input field ──────────────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? type,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return AnimatedBorderField(
      controller: controller,
      hint: hint,
      prefixIcon: icon,
      keyboardType: type,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      borderRadius: 16,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ─── Reused style widgets (identical to original page) ────────────────────
  Widget _backButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE1DCEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: _mutedPurple,
        ),
      ),
    );
  }

  Widget _stepBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE1DCEA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        'STEP 2 OF 2',
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: const Color(0xFF7A7195),
        ),
      ),
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your hospice\nprovider',
          style: GoogleFonts.nunito(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: _deepPurple,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Select your provider and confirm where\ncare will be delivered.',
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: _mutedPurple,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _sectionDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _borderColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _miniRing(),
        ),
        Expanded(child: Divider(color: _borderColor, thickness: 1)),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _deepPurple,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _mutedPurple,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _continueButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B5B8E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        onPressed: _isLoading ? null : _continueToDashboard,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _privacyNote() {
    return Center(
      child: Text(
        '🔒  Your information stays private to your care team',
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: const Color(0xFF9B92B8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _miniRing() {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor, width: 1),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor, width: 1),
            ),
          ),
        ],
      ),
    );
  }
}
