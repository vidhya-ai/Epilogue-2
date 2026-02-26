import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _supabaseService = SupabaseService();
  final _uuid = const Uuid();
  List<Medication> _medications = [];
  bool _isLoading = true;

  String? _careTeamId;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      final careTeamId = SessionManager().currentCareTeam?.id;
      if (careTeamId == null) {
        debugPrint('No care team ID found in session.');
        return;
      }
      _careTeamId = careTeamId;
      final response = await _supabaseService.getMedications(careTeamId);
      setState(() {
        _medications = response;
      });
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddMedicationModal() {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    bool isPrn = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Add Medication',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      hintText: 'e.g., Morphine Sulfate',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: doseController,
                    decoration: const InputDecoration(
                      labelText: 'Dosing Instructions',
                      hintText: 'e.g., 5mg oral every 4 hours',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('PRN (As needed)'),
                    subtitle: const Text('Check if this is given for symptoms'),
                    value: isPrn,
                    onChanged: (val) => setModalState(() => isPrn = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_careTeamId == null) {
                          if (mounted) { // This mounted check is for the MedicationsScreen state
                            ScaffoldMessenger.of(context).showSnackBar( // This context is the MedicationsScreen's context
                              const SnackBar(
                                content: Text('Error: No care team selected.'),
                              ),
                            );
                          }
                          return;
                        }
                        final newMed = Medication(
                          id: _uuid.v4(),
                          careTeamId: _careTeamId,
                          name: nameController.text,
                          typicalDose: doseController.text,
                          pattern: isPrn ? 'PRN' : 'Scheduled',
                          createdAt: DateTime.now(),
                        );
                        await _supabaseService.addMedication(newMed);
                        // Pop the dialog first, using the dialog's context
                        Navigator.pop(context); // This context is the modal's context
                        // Now check if the underlying widget is still mounted before updating its state
                        if (!mounted) return;
                        _loadMedications();
                      },
                      child: const Text('Save Medication'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No medications added yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    final isPrn = med.pattern == 'PRN';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                med.name ?? 'Unknown',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isPrn)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'PRN',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            med.typicalDose ?? 'No dose specified',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
