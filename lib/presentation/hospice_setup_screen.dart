import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'care_address_screen.dart';

// ─── Hospice Data Model ───────────────────────────────────────────────────────
class HospiceOrg {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String county;
  final String coverageArea;
  final String? branchOf;
  final String? nurseLineNumber;

  const HospiceOrg({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.county,
    required this.coverageArea,
    this.branchOf,
    this.nurseLineNumber,
  });

  // Full location string shown in results
  String get locationLine => '$address, $city, $state $zipCode';
  String get countyLine => '$county County · $coverageArea';
}

// ─── Static hospice table (replace with Supabase query later) ─────────────────
const List<HospiceOrg> _hospiceList = [
  HospiceOrg(id: 'valley_main', name: 'Valley Care Hospice Center',
    address: '123 Valley Road', city: 'Springfield', state: 'IL', zipCode: '62701',
    county: 'Sangamon', coverageArea: '30-mile radius', nurseLineNumber: '555-100-1001'),
  HospiceOrg(id: 'valley_north', name: 'Valley Care Hospice Center',
    address: '450 North Valley Pkwy', city: 'Lincoln', state: 'IL', zipCode: '62656',
    county: 'Logan', coverageArea: '30-mile radius', branchOf: 'valley_main', nurseLineNumber: '555-100-1001'),
  HospiceOrg(id: 'valley_south', name: 'Valley Care Hospice Center',
    address: '88 South Creek Blvd', city: 'Decatur', state: 'IL', zipCode: '62521',
    county: 'Macon', coverageArea: '30-mile radius', branchOf: 'valley_main', nurseLineNumber: '555-100-1001'),
  HospiceOrg(id: 'serenity', name: 'Serenity Pathways Palliative',
    address: '456 Serenity Lane', city: 'Chicago', state: 'IL', zipCode: '60601',
    county: 'Cook', coverageArea: '30-mile radius', nurseLineNumber: '555-200-2002'),
  HospiceOrg(id: 'grace', name: 'Graceful Transitions Hospice',
    address: '789 Grace Ave', city: 'Naperville', state: 'IL', zipCode: '60540',
    county: 'DuPage', coverageArea: '30-mile radius', nurseLineNumber: '555-300-3003'),
  HospiceOrg(id: 'grace_west', name: 'Graceful Transitions Hospice',
    address: '22 Westfield Dr', city: 'Aurora', state: 'IL', zipCode: '60505',
    county: 'Kane', coverageArea: '30-mile radius', branchOf: 'grace', nurseLineNumber: '555-300-3003'),
  HospiceOrg(id: 'north', name: 'North Star Comfort Care',
    address: '321 North Star Blvd', city: 'Rockford', state: 'IL', zipCode: '61101',
    county: 'Winnebago', coverageArea: '30-mile radius', nurseLineNumber: '555-400-4004'),
];

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
  HospiceOrg? _selectedHospice;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showResults = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Autocomplete: match against name, city, zip, county
  List<HospiceOrg> get _results {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return [];
    return _hospiceList.where((h) =>
      h.name.toLowerCase().contains(q) ||
      h.city.toLowerCase().contains(q) ||
      h.zipCode.contains(q) ||
      h.county.toLowerCase().contains(q) ||
      h.address.toLowerCase().contains(q)
    ).toList();
  }

  // Group results: parent name → list of locations
  Map<String, List<HospiceOrg>> get _groupedResults {
    final map = <String, List<HospiceOrg>>{};
    for (final h in _results) {
      final key = h.name; // group by org name
      map.putIfAbsent(key, () => []).add(h);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && _searchQuery.isNotEmpty) {
        setState(() => _showResults = true);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      _showResults = val.trim().isNotEmpty;
      // Clear selection if user edits after picking
      if (_selectedHospice != null && val != _selectedHospice!.name) {
        _selectedHospice = null;
      }
    });
  }

  void _selectHospice(HospiceOrg h) {
    setState(() {
      _selectedHospice = h;
      _showResults = false;
      _searchQuery = h.name;
      _searchCtrl.text = h.name;
    });
    _searchFocus.unfocus();
  }

  void _clearSearch() {
    setState(() {
      _selectedHospice = null;
      _searchQuery = '';
      _showResults = false;
    });
    _searchCtrl.clear();
    _searchFocus.requestFocus();
  }

  void _goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareAddressScreen(
          patientName: widget.patientName,
          caregiverName: widget.caregiverName,
          email: widget.email,
          hospiceId: _selectedHospice?.id ?? '',
          hospiceName: _selectedHospice != null
              ? '${_selectedHospice!.name} — ${_selectedHospice!.city}'
              : '',
          nurseLineNumber: _selectedHospice?.nurseLineNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _showResults = false);
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

                      // Back
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1DCEA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: _mutedPurple),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Step badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1DCEA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Text('STEP 2 OF 3',
                          style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: const Color(0xFF7A7195))),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text('Your hospice\nprovider',
                        style: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.w600, color: _deepPurple, height: 1.0)),
                      const SizedBox(height: 10),
                      Text('Search by name, city, or zip code.',
                        style: GoogleFonts.nunito(fontSize: 17, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: _mutedPurple, height: 1.4)),

                      const SizedBox(height: 32),

                      // Divider
                      Row(children: [
                        Expanded(child: Divider(color: _borderColor, thickness: 1)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(width: 18, height: 18,
                            child: Stack(alignment: Alignment.center, children: [
                              Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _borderColor, width: 1))),
                              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _borderColor, width: 1))),
                            ]))),
                        Expanded(child: Divider(color: _borderColor, thickness: 1)),
                      ]),

                      const SizedBox(height: 28),

                      // ── Single autocomplete search field ──
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _searchFocus.hasFocus ? _purple : _borderColor,
                            width: _searchFocus.hasFocus ? 2 : 1.5,
                          ),
                          boxShadow: _searchFocus.hasFocus
                            ? [BoxShadow(color: _purple.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.nunito(fontSize: 15, color: _deepPurple, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Search hospice name, city, or zip...',
                            hintStyle: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFFB8B0CC), fontWeight: FontWeight.w400),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                _selectedHospice != null ? Icons.check_circle_rounded : Icons.search_rounded,
                                size: 22,
                                color: _selectedHospice != null ? _purple : _mutedPurple,
                              ),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: _mutedPurple),
                                  onPressed: _clearSearch,
                                )
                              : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                      ),

                      // ── Autocomplete results ──
                      if (_showResults) ...[
                        const SizedBox(height: 6),
                        _buildResults(),
                      ],

                      // ── Selected location confirmation ──
                      if (_selectedHospice != null && !_showResults) ...[
                        const SizedBox(height: 14),
                        _selectedConfirmation(),
                      ],

                      // Helper text when nothing typed
                      if (_searchQuery.isEmpty && _selectedHospice == null) ...[
                        const SizedBox(height: 14),
                        Row(children: [
                          const Icon(Icons.info_outline, size: 14, color: _mutedPurple),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            'Start typing to find your hospice provider. If they have multiple locations, you can select the closest one.',
                            style: GoogleFonts.nunito(fontSize: 12, color: _mutedPurple, height: 1.5),
                          )),
                        ]),
                      ],

                      const SizedBox(height: 44),

                      // Continue
                      SizedBox(
                        width: double.infinity, height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5B8E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          ),
                          onPressed: _goNext,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Continue', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Center(child: Text('🔒  Your information stays private to your care team',
                        style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF9B92B8), fontWeight: FontWeight.w500))),
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

  // ── Grouped autocomplete results (GPS-style) ──────────────────────────────
  Widget _buildResults() {
    final grouped = _groupedResults;
    if (grouped.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Row(children: [
          const Icon(Icons.search_off_rounded, size: 20, color: _mutedPurple),
          const SizedBox(width: 12),
          Expanded(child: Text(
            'No hospice found. Try a different name, city, or zip.',
            style: GoogleFonts.nunito(fontSize: 13, color: _mutedPurple),
          )),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [BoxShadow(color: _purple.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.expand((entry) {
            final orgName = entry.key;
            final locations = entry.value;
            final isMulti = locations.length > 1;

            return [
              // Org name header (only shown when multiple locations)
              if (isMulti)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(children: [
                    const Icon(Icons.business_rounded, size: 13, color: _mutedPurple),
                    const SizedBox(width: 6),
                    Text(orgName,
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: _mutedPurple, letterSpacing: 0.4)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                      child: Text('${locations.length} locations',
                        style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: _purple)),
                    ),
                  ]),
                ),

              // Each location row
              ...locations.map((h) => _locationRow(h, isIndented: isMulti)),
            ];
          }).toList(),
        ),
      ),
    );
  }

  Widget _locationRow(HospiceOrg h, {bool isIndented = false}) {
    final isSelected = _selectedHospice?.id == h.id;
    return InkWell(
      onTap: () => _selectHospice(h),
      child: Container(
        padding: EdgeInsets.fromLTRB(isIndented ? 32 : 16, 12, 16, 12),
        decoration: BoxDecoration(
          color: isSelected ? _purple.withOpacity(0.06) : Colors.transparent,
          border: Border(bottom: BorderSide(color: _borderColor.withOpacity(0.5))),
        ),
        child: Row(children: [
          // Location pin icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isSelected ? _purple.withOpacity(0.12) : _cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIndented ? Icons.location_on_rounded : Icons.local_hospital_outlined,
              size: 18,
              color: isSelected ? _purple : _mutedPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Show org name if single result, city if multi
            Text(
              isIndented ? '${h.city}, ${h.state}' : h.name,
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: _deepPurple),
            ),
            Text(h.address, style: GoogleFonts.nunito(fontSize: 12, color: _mutedPurple)),
            const SizedBox(height: 2),
            Text(h.countyLine, style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFFB0A8C8))),
          ])),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, size: 18, color: _purple)
          else
            const Icon(Icons.chevron_right, size: 18, color: _mutedPurple),
        ]),
      ),
    );
  }

  // ── Selected confirmation chip ────────────────────────────────────────────
  Widget _selectedConfirmation() {
    final h = _selectedHospice!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.25), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: _purple.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 18, color: _purple),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h.name, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: _purple)),
          Text('${h.address}, ${h.city}, ${h.state}', style: GoogleFonts.nunito(fontSize: 12, color: _mutedPurple)),
          Text(h.countyLine, style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFFB0A8C8))),
        ])),
        GestureDetector(
          onTap: _clearSearch,
          child: const Icon(Icons.close, size: 16, color: _mutedPurple),
        ),
      ]),
    );
  }
}