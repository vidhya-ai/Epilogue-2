import 'package:flutter/material.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

class CarePlanScreen extends StatefulWidget {
  const CarePlanScreen({super.key});

  @override
  State<CarePlanScreen> createState() => _CarePlanScreenState();
}

class _CarePlanScreenState extends State<CarePlanScreen> {
  final _supabaseService = SupabaseService();
  final _session = SessionManager();
  final _formKey = GlobalKey<FormState>();
  late Future<CarePlan?> _carePlanFuture;

  final _medicationsSummaryController = TextEditingController();
  final _positioningTurningController = TextEditingController();
  final _transfersController = TextEditingController();
  final _mobilityController = TextEditingController();
  final _personalCareController = TextEditingController();
  final _otherInstructionsController = TextEditingController();
  final _hospiceInstructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carePlanFuture = _loadCarePlan();
  }

  Future<CarePlan?> _loadCarePlan() async {
    final careTeamId = _session.currentCareTeam?.id;
    if (careTeamId == null) {
      throw Exception('Not logged in');
    }
    final plan = await _supabaseService.getCarePlan(careTeamId);
    if (plan != null) {
      _medicationsSummaryController.text = plan.medicationsSummary ?? '';
      _positioningTurningController.text = plan.positioningTurning ?? '';
      _transfersController.text = plan.transfers ?? '';
      _mobilityController.text = plan.mobility ?? '';
      _personalCareController.text = plan.personalCare ?? '';
      _otherInstructionsController.text = plan.otherInstructions ?? '';
      _hospiceInstructionsController.text = plan.hospiceInstructions ?? '';
    }
    return plan;
  }

  Future<void> _saveCarePlan() async {
    if (_formKey.currentState!.validate()) {
      final careTeamId = _session.currentCareTeam?.id;
      final memberId = _session.currentMember?.id;
      if (careTeamId == null || memberId == null) return;

      final plan = CarePlan(
        careTeamId: careTeamId,
        medicationsSummary: _medicationsSummaryController.text,
        positioningTurning: _positioningTurningController.text,
        transfers: _transfersController.text,
        mobility: _mobilityController.text,
        personalCare: _personalCareController.text,
        otherInstructions: _otherInstructionsController.text,
        hospiceInstructions: _hospiceInstructionsController.text,
        updatedAt: DateTime.now(),
        updatedByMemberId: memberId,
      );
      await _supabaseService.updateCarePlan(plan);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Care Plan Saved')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${SessionManager().currentCareTeam?.patientFirstName ?? 'Patient'}'s Care Plan",
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveCarePlan),
        ],
      ),
      body: FutureBuilder<CarePlan?>(
        future: _carePlanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTextField(
                    _medicationsSummaryController,
                    'Medications Summary',
                  ),
                  _buildTextField(
                    _positioningTurningController,
                    'Positioning / Turning',
                  ),
                  _buildTextField(_transfersController, 'Transfers'),
                  _buildTextField(_mobilityController, 'Mobility'),
                  _buildTextField(_personalCareController, 'Personal Care'),
                  _buildTextField(
                    _otherInstructionsController,
                    'Other Instructions',
                  ),
                  _buildTextField(
                    _hospiceInstructionsController,
                    'Hospice Instructions',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
    );
  }
}
