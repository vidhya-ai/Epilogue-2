import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/session_manager.dart';
import '../domain/models.dart';

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

class _HospiceSetupScreenState extends State<HospiceSetupScreen> {
  String? selectedHospice;
  final nurseController = TextEditingController();

  Future<void> _continueToDashboard() async {
    final now = DateTime.now();
    final teamId = 'team_${now.microsecondsSinceEpoch}';
    final memberId = 'member_${now.microsecondsSinceEpoch}';

    final careTeam = CareTeam(
      id: teamId,
      patientFirstName: widget.patientName.trim().isEmpty
          ? null
          : widget.patientName.trim().split(' ').first,
      hospiceOrgId: selectedHospice,
      nurseLineNumber: nurseController.text.trim().isEmpty
          ? null
          : nurseController.text.trim(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB7AFCA), Color(0xFFF8F6FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Back
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: Color(0xFF4B3F66),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Choose your hospice provider",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B3F66),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Select the organization providing care to auto-populate contact information.",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B3F66),
                  ),
                ),

                const SizedBox(height: 30),

                /// Dropdown
                const Text(
                  "Hospice Organization",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B3F66),
                  ),
                ),

                const SizedBox(height: 12),

                _dropdown(),

                const SizedBox(height: 24),

                /// Nurse line
                const Text(
                  "Nurse Line Number *",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B3F66),
                  ),
                ),

                const SizedBox(height: 12),

                _nurseField(),

                const SizedBox(height: 40),

                /// Continue → Dashboard
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E7CB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () async {
                      await _continueToDashboard();
                    },
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 20,
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
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedHospice,
          hint: const Text("Search for a hospice..."),
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: "valley",
              child: Text("Valley Care Hospice Center"),
            ),
            DropdownMenuItem(
              value: "serenity",
              child: Text("Serenity Pathways Palliative"),
            ),
            DropdownMenuItem(
              value: "grace",
              child: Text("Graceful Transitions Hospice"),
            ),
            DropdownMenuItem(
              value: "north",
              child: Text("North Star Comfort Care"),
            ),
          ],
          onChanged: (v) => setState(() => selectedHospice = v),
        ),
      ),
    );
  }

  Widget _nurseField() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: TextField(
        controller: nurseController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          hintText: "Input Nurse Line Number",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
