import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/session_manager.dart';
import '../domain/models.dart';

// ─── Hospice Data Model ───────────────────────────────────────────────────────
class HospiceOrg {
  final String id;
  final String name;
  final String address;
  final String mainPhone;
  final String nursePhone;
  final String afterHoursPhone;
  final String emergencyPhone;

  const HospiceOrg({
    required this.id,
    required this.name,
    required this.address,
    required this.mainPhone,
    required this.nursePhone,
    required this.afterHoursPhone,
    required this.emergencyPhone,
  });
}

// ─── Clinical Contact Model ───────────────────────────────────────────────────
class ClinicalContact {
  String role;
  String name;
  String phone;

  ClinicalContact({this.role = '', this.name = '', this.phone = ''});
}

// ─── Static Hospice Data (replace with Supabase query later) ─────────────────
const List<HospiceOrg> _hospiceList = [
  HospiceOrg(
    id: 'valley',
    name: 'Valley Care Hospice Center',
    address: '123 Valley Road, Springfield, IL 62701',
    mainPhone: '(217) 555-0101',
    nursePhone: '(217) 555-0102',
    afterHoursPhone: '(217) 555-0103',
    emergencyPhone: '(217) 555-0104',
  ),
  HospiceOrg(
    id: 'serenity',
    name: 'Serenity Pathways Palliative',
    address: '456 Serenity Lane, Chicago, IL 60601',
    mainPhone: '(312) 555-0201',
    nursePhone: '(312) 555-0202',
    afterHoursPhone: '(312) 555-0203',
    emergencyPhone: '(312) 555-0204',
  ),
  HospiceOrg(
    id: 'grace',
    name: 'Graceful Transitions Hospice',
    address: '789 Grace Ave, Naperville, IL 60540',
    mainPhone: '(630) 555-0301',
    nursePhone: '(630) 555-0302',
    afterHoursPhone: '(630) 555-0303',
    emergencyPhone: '(630) 555-0304',
  ),
  HospiceOrg(
    id: 'north',
    name: 'North Star Comfort Care',
    address: '321 North Star Blvd, Rockford, IL 61101',
    mainPhone: '(815) 555-0401',
    nursePhone: '(815) 555-0402',
    afterHoursPhone: '(815) 555-0403',
    emergencyPhone: '(815) 555-0404',
  ),
];

const List<String> _clinicalRoles = [
  'Hospice Nurse Case Manager',
  'Hospice Physician',
  'Primary / Attending Physician',
  'Registered Nurse (RN)',
  'Licensed Practical Nurse (LPN/LVN)',
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
  // Hospice selection
  HospiceOrg? _selectedHospice;
  bool _isOtherHospice = false;
  final _otherHospiceNameCtrl = TextEditingController();
  final _otherHospiceAddressCtrl = TextEditingController();
  final _otherMainPhoneCtrl = TextEditingController();
  final _otherNursePhoneCtrl = TextEditingController();
  final _otherAfterHoursCtrl = TextEditingController();
  final _otherEmergencyCtrl = TextEditingController();

  // Search
  String _searchQuery = '';
  bool _showDropdown = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  // Caregiver org
  final _caregiverOrgCtrl = TextEditingController();

  // Clinical contacts
  final List<ClinicalContact> _clinicalContacts = [ClinicalContact()];

  // Loading
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<HospiceOrg> get _filteredHospices {
    if (_searchQuery.isEmpty) return _hospiceList;
    return _hospiceList
        .where((h) => h.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
    _otherHospiceNameCtrl.dispose();
    _otherHospiceAddressCtrl.dispose();
    _otherMainPhoneCtrl.dispose();
    _otherNursePhoneCtrl.dispose();
    _otherAfterHoursCtrl.dispose();
    _otherEmergencyCtrl.dispose();
    _caregiverOrgCtrl.dispose();
    super.dispose();
  }

  Future<void> _continueToDashboard() async {
    if (_isLoading) return;

    // Validate: must have hospice selected or other filled
    if (!_isOtherHospice && _selectedHospice == null) {
      _showSnack('Please select a hospice organization');
      return;
    }
    if (_isOtherHospice && _otherHospiceNameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter the hospice name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final teamId = 'team_${now.microsecondsSinceEpoch}';
      final memberId = 'member_${now.microsecondsSinceEpoch}';

      final hospiceId = _isOtherHospice
          ? 'other_${_otherHospiceNameCtrl.text.trim()}'
          : _selectedHospice!.id;

      final nursePhone = _isOtherHospice
          ? _otherNursePhoneCtrl.text.trim()
          : _selectedHospice!.nursePhone;

      final careTeam = CareTeam(
        id: teamId,
        patientFirstName: widget.patientName.trim().isEmpty
            ? null
            : widget.patientName.trim(),
        hospiceOrgId: hospiceId,
        nurseLineNumber: nursePhone.isEmpty ? null : nursePhone,
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
        joinedAt: now,
        lastActive: now,
      );

      await SessionManager().setSession(careTeam, member);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (mounted) _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
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

                      // ── Hospice Search ──
                      _sectionLabel('Hospice Organization'),
                      const SizedBox(height: 10),
                      _hospiceSearchField(),
                      if (_showDropdown) _dropdownList(),
                      if (_selectedHospice != null && !_isOtherHospice) ...[
                        const SizedBox(height: 12),
                        _selectedHospiceCard(),
                      ],
                      if (_isOtherHospice) ...[
                        const SizedBox(height: 16),
                        _otherHospiceFields(),
                      ],

                      const SizedBox(height: 28),

                      // ── Clinical Team ──
                      _sectionLabel('Clinical Team Contacts'),
                      const SizedBox(height: 6),
                      Text(
                        'Add key contacts from your hospice care team',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _mutedPurple,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ..._clinicalContacts.asMap().entries.map(
                        (e) => _clinicalContactCard(e.key, e.value),
                      ),
                      const SizedBox(height: 10),
                      _addContactButton(),

                      const SizedBox(height: 28),

                      // ── Caregiver Org (Optional) ──
                      _sectionLabel('Caregiver Organization'),
                      const SizedBox(height: 4),
                      Text(
                        'Optional — skip if your family is self-caring',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _mutedPurple,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _styledInput(
                        controller: _caregiverOrgCtrl,
                        hint: 'Organization name (optional)',
                        icon: Icons.business_outlined,
                      ),

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

  // ─── Widgets ────────────────────────────────────────────────────────────────

  Widget _backButton() {
    return GestureDetector(
      onTap: () => context.go('/setup'),
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
        style: GoogleFonts.inter(
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
          style: GoogleFonts.cormorantGaramond(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: _deepPurple,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Select your organization to auto-fill contact\ninformation, or add one manually.',
          style: GoogleFonts.cormorantGaramond(
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
      style: GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _deepPurple,
      ),
    );
  }

  Widget _hospiceSearchField() {
    return Column(
      children: [
        AnimatedContainer(
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
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _deepPurple,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (v) {
              setState(() {
                _searchQuery = v;
                _showDropdown = true;
                if (_selectedHospice != null) {
                  _selectedHospice = null;
                  _isOtherHospice = false;
                }
              });
            },
            onTap: () => setState(() => _showDropdown = true),
            decoration: InputDecoration(
              hintText: 'Search for a hospice...',
              hintStyle: GoogleFonts.inter(
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
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: _mutedPurple,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _selectedHospice = null;
                          _isOtherHospice = false;
                          _showDropdown = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownList() {
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
      child: Column(
        children: [
          ..._filteredHospices.map((h) => _dropdownItem(h)),
          _dropdownOtherItem(),
        ],
      ),
    );
  }

  Widget _dropdownItem(HospiceOrg h) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedHospice = h;
          _isOtherHospice = false;
          _searchCtrl.text = h.name;
          _searchQuery = '';
          _showDropdown = false;
        });
        _searchFocus.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _deepPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    h.address,
                    style: GoogleFonts.inter(fontSize: 11, color: _mutedPurple),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownOtherItem() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _isOtherHospice = true;
          _selectedHospice = null;
          _searchCtrl.text = 'Other hospice...';
          _showDropdown = false;
        });
        _searchFocus.unfocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE1DCEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, size: 18, color: _purple),
            ),
            const SizedBox(width: 12),
            Text(
              'Other — add manually',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedHospiceCard() {
    final h = _selectedHospice!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: _purple,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  h.name,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _deepPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            h.address,
            style: GoogleFonts.inter(fontSize: 12, color: _mutedPurple),
          ),
          const Divider(height: 20, color: _borderColor),
          _phoneRow(Icons.phone_outlined, 'Main Office', h.mainPhone),
          _phoneRow(
            Icons.local_hospital_outlined,
            '24-hr Nurse Line',
            h.nursePhone,
          ),
          _phoneRow(
            Icons.nights_stay_outlined,
            'After-Hours',
            h.afterHoursPhone,
          ),
          _phoneRow(Icons.emergency_outlined, 'Emergency', h.emergencyPhone),
        ],
      ),
    );
  }

  Widget _phoneRow(IconData icon, String label, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _mutedPurple),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _mutedPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            number,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _otherHospiceFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hospice Details',
            style: GoogleFonts.lora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),
          const SizedBox(height: 14),
          _compactInput(
            ctrl: _otherHospiceNameCtrl,
            label: 'Organization Name *',
            hint: 'Enter hospice name',
          ),
          const SizedBox(height: 12),
          _compactInput(
            ctrl: _otherHospiceAddressCtrl,
            label: 'Address',
            hint: 'Street, city, state',
          ),
          const SizedBox(height: 16),
          Text(
            'Phone Numbers',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _mutedPurple,
            ),
          ),
          const SizedBox(height: 10),
          _compactInput(
            ctrl: _otherMainPhoneCtrl,
            label: 'Main Office',
            hint: '(000) 000-0000',
            type: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _compactInput(
            ctrl: _otherNursePhoneCtrl,
            label: '24-hr Nurse Line',
            hint: '(000) 000-0000',
            type: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _compactInput(
            ctrl: _otherAfterHoursCtrl,
            label: 'After-Hours / Weekend',
            hint: '(000) 000-0000',
            type: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _compactInput(
            ctrl: _otherEmergencyCtrl,
            label: 'Emergency / Urgent Care',
            hint: '(000) 000-0000',
            type: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _clinicalContactCard(int index, ClinicalContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contact ${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _mutedPurple,
                  ),
                ),
              ),
              if (_clinicalContacts.length > 1)
                GestureDetector(
                  onTap: () =>
                      setState(() => _clinicalContacts.removeAt(index)),
                  child: const Icon(Icons.close, size: 18, color: _mutedPurple),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Role dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: contact.role.isEmpty ? null : contact.role,
                hint: Text(
                  'Select role',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFB8B0CC),
                  ),
                ),
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _mutedPurple,
                ),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _deepPurple,
                  fontWeight: FontWeight.w500,
                ),
                items: _clinicalRoles
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r, style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _clinicalContacts[index].role = v ?? ''),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Name field
          _compactInput(
            ctrl: TextEditingController(text: contact.name),
            label: 'Name',
            hint: 'Full name',
            onChanged: (v) => _clinicalContacts[index].name = v,
          ),
          const SizedBox(height: 10),

          // Phone field
          _compactInput(
            ctrl: TextEditingController(text: contact.phone),
            label: 'Phone / Extension',
            hint: '(000) 000-0000',
            type: TextInputType.phone,
            onChanged: (v) => _clinicalContacts[index].phone = v,
          ),
        ],
      ),
    );
  }

  Widget _addContactButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _clinicalContacts.add(ClinicalContact()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE1DCEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: _purple),
            const SizedBox(width: 8),
            Text(
              'Add another contact',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _purple,
              ),
            ),
          ],
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
                    'Go to Dashboard',
                    style: GoogleFonts.cormorantGaramond(
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
        style: GoogleFonts.inter(
          fontSize: 11,
          color: const Color(0xFF9B92B8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _styledInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: _deepPurple,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFB8B0CC),
          ),
          prefixIcon: Icon(icon, size: 18, color: _mutedPurple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _compactInput({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    TextInputType? type,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _mutedPurple,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            onChanged: onChanged,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _deepPurple,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFB8B0CC),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
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
