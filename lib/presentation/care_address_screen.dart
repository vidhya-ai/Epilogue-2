import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

const _bg1 = Color(0xFFE6E2EE);
const _bg2 = Color(0xFFDAD4E6);
const _purple = Color(0xFF7A64A4);
const _deepPurple = Color(0xFF443C63);
const _mutedPurple = Color(0xFF6C648B);
const _borderColor = Color(0xFFD4CDDF);

const _usStates = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
  'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
  'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
  'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
  'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC',
];

class CareAddressScreen extends StatefulWidget {
  final String patientName;
  final String caregiverName;
  final String email;
  final String hospiceId;
  final String hospiceName;
  final String? nurseLineNumber;

  const CareAddressScreen({
    super.key,
    required this.patientName,
    required this.caregiverName,
    required this.email,
    required this.hospiceId,
    required this.hospiceName,
    this.nurseLineNumber,
  });

  @override
  State<CareAddressScreen> createState() => _CareAddressScreenState();
}

class _CareAddressScreenState extends State<CareAddressScreen> with SingleTickerProviderStateMixin {
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _selectedState;
  final _zipCtrl = TextEditingController();
  String? _derivedCounty;
  bool _derivingCounty = false;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose(); _streetCtrl.dispose(); _cityCtrl.dispose(); _zipCtrl.dispose(); super.dispose();
  }

  // TODO: Replace with Google Geocoding API
  // GET https://maps.googleapis.com/maps/api/geocode/json?address={street},{city},{state}+{zip}&key=YOUR_KEY
  // Parse 'administrative_area_level_2' — zip alone is insufficient (two addresses 1 mile apart can be in different counties)
  Future<void> _deriveCounty() async {
    final street = _streetCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = _selectedState;
    final zip = _zipCtrl.text.trim();
    if (street.isEmpty || city.isEmpty || state == null || zip.length < 5) return;
    setState(() { _derivingCounty = true; _derivedCounty = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() { _derivingCounty = false; _derivedCounty = 'Pending Google API integration'; });
  }

  Future<void> _goToDashboard() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final teamId = uuid.v4();
      final memberId = uuid.v4();
      final pin = (1000 + (now.microsecondsSinceEpoch % 9000)).toString();

      final careTeam = CareTeam(
        id: teamId,
        patientFirstName: widget.patientName.trim().isEmpty ? null : widget.patientName.trim(),
        hospiceOrgId: widget.hospiceId.isEmpty ? null : widget.hospiceId,
        nurseLineNumber: widget.nurseLineNumber,
        createdAt: now,
      );

      final member = Member(
        id: memberId,
        careTeamId: teamId,
        name: widget.caregiverName.trim().isEmpty ? 'Caregiver' : widget.caregiverName.trim(),
        email: widget.email.trim().isEmpty ? 'unknown@example.com' : widget.email.trim(),
        role: 'family',
        isAdmin: true,
        accessPin: pin,
        joinedAt: now,
        lastActive: now,
      );

      try {
        final service = SupabaseService();
        await service.createCareTeam(careTeam);
        await service.addMember(member);
      } catch (dbError) {
        debugPrint('Supabase error (non-fatal): $dbError');
      }

      await SessionManager().setSession(careTeam, member);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_bg1, _bg2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim,
          child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              // Back
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE1DCEA), borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor)),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: _mutedPurple)),
              ),
              const SizedBox(height: 28),
              // Step 3 of 3
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFE1DCEA), borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor)),
                child: Text('STEP 3 OF 3', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: const Color(0xFF7A7195)))),
              const SizedBox(height: 16),
              Text('Care address', style: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.w600, color: _deepPurple, height: 1.0)),
              const SizedBox(height: 10),
              Text('Where will care be delivered?', style: GoogleFonts.nunito(fontSize: 17, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: _mutedPurple, height: 1.4)),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: Divider(color: _borderColor, thickness: 1)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(width: 18, height: 18, child: Stack(alignment: Alignment.center, children: [
                    Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _borderColor, width: 1))),
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _borderColor, width: 1))),
                  ]))),
                Expanded(child: Divider(color: _borderColor, thickness: 1)),
              ]),
              const SizedBox(height: 28),
              // Hospice pill
              if (widget.hospiceName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: _purple.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: _purple.withOpacity(0.2), width: 1.5)),
                  child: Row(children: [
                    const Icon(Icons.local_hospital_outlined, size: 16, color: _purple),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.hospiceName, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: _purple))),
                  ]),
                ),
              const SizedBox(height: 20),
              Text('Care will be delivered at this address.', style: GoogleFonts.nunito(fontSize: 12, color: _mutedPurple, fontStyle: FontStyle.italic)),
              const SizedBox(height: 14),
              // Street
              _fieldLabel('Street Address'),
              _inputField(controller: _streetCtrl, hint: 'e.g. 1234 Elm Street', icon: Icons.home_outlined, onChanged: (_) => _deriveCounty()),
              const SizedBox(height: 12),
              // City
              _fieldLabel('City'),
              _inputField(controller: _cityCtrl, hint: 'e.g. Springfield', icon: Icons.location_city_outlined, onChanged: (_) => _deriveCounty()),
              const SizedBox(height: 12),
              // State + Zip
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _fieldLabel('State'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor, width: 1.5)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                      value: _selectedState, isExpanded: true,
                      hint: Text('State', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFFB8B0CC))),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _mutedPurple),
                      style: GoogleFonts.nunito(fontSize: 14, color: _deepPurple, fontWeight: FontWeight.w600),
                      items: _usStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.nunito(fontSize: 14)))).toList(),
                      onChanged: (v) { setState(() => _selectedState = v); _deriveCounty(); },
                    )),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _fieldLabel('Zip Code'),
                  _inputField(controller: _zipCtrl, hint: '00000', icon: Icons.pin_drop_outlined, type: TextInputType.number, maxLength: 5,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (_) => _deriveCounty()),
                ])),
              ]),
              // County
              if (_derivingCounty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _purple)),
                  const SizedBox(width: 8),
                  Text('Determining county...', style: GoogleFonts.nunito(fontSize: 11, color: _mutedPurple)),
                ]),
              ] else if (_derivedCounty != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: _purple),
                  const SizedBox(width: 6),
                  Text(_derivedCounty!, style: GoogleFonts.nunito(fontSize: 11, color: _mutedPurple, fontWeight: FontWeight.w600)),
                ]),
              ],
              const SizedBox(height: 44),
              // Go to Dashboard
              SizedBox(width: double.infinity, height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5B8E), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                  onPressed: _isLoading ? null : _goToDashboard,
                  child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Go to Dashboard', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ]),
                )),
              const SizedBox(height: 16),
              Center(child: Text('🔒  Your information stays private to your care team',
                style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF9B92B8), fontWeight: FontWeight.w500))),
              const SizedBox(height: 40),
            ]),
          ),
        ))),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: _mutedPurple, letterSpacing: 0.2)));
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon,
    TextInputType? type, int? maxLength, List<TextInputFormatter>? inputFormatters, void Function(String)? onChanged}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor, width: 1.5)),
      child: TextField(controller: controller, keyboardType: type, maxLength: maxLength, inputFormatters: inputFormatters, onChanged: onChanged,
        style: GoogleFonts.nunito(fontSize: 14, color: _deepPurple, fontWeight: FontWeight.w500),
        decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFFB8B0CC)),
          prefixIcon: Icon(icon, size: 18, color: _mutedPurple), border: InputBorder.none, counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
    );
  }
}