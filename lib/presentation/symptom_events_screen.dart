import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

class SymptomEventsScreen extends StatefulWidget {
  const SymptomEventsScreen({super.key});

  @override
  State<SymptomEventsScreen> createState() => _SymptomEventsScreenState();
}

class _SymptomEventsScreenState extends State<SymptomEventsScreen> {
  final _supabaseService = SupabaseService();
  final _session = SessionManager();
  final _uuid = const Uuid();
  late Future<List<SymptomEvent>> _symptomsFuture;

  @override
  void initState() {
    super.initState();
    _symptomsFuture = _loadSymptoms();
  }

  Future<List<SymptomEvent>> _loadSymptoms() async {
    final careTeamId = _session.currentCareTeam?.id;
    if (careTeamId == null) {
      throw Exception('Not logged in');
    }
    return _supabaseService.getSymptomEvents(careTeamId);
  }

  void _showAddSymptomDialog() {
    final whatHappenedController = TextEditingController();
    String severity = 'Mild';
    List<String> symptoms = [];

    showDialog(
      context: context,
      builder: (dialogContext) { // Explicitly name dialogContext
        return AlertDialog(
          title: const Text('Log Symptom Event'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: whatHappenedController,
                      decoration: const InputDecoration(
                        labelText: 'What happened?',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: severity,
                      decoration: const InputDecoration(labelText: 'Severity'),
                      items: ['Mild', 'Moderate', 'Severe']
                          .map(
                            (label) => DropdownMenuItem(
                              value: label,
                              child: Text(label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            severity = value;
                          });
                        }
                      },
                    ),
                    // In a real app, this would be a multi-select chip group
                    const SizedBox(height: 16),
                    const Text('Symptoms'),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Use dialogContext
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final member = _session.currentMember;
                final careTeamId = _session.currentCareTeam?.id;
                if (member == null || careTeamId == null) return;

                final newSymptomEvent = SymptomEvent(
                  id: _uuid.v4(),
                  careTeamId: careTeamId,
                  whatHappened: whatHappenedController.text,
                  severity: severity,
                  symptoms: symptoms,
                  eventTime: DateTime.now(),
                  createdByMemberId: member.id,
                  createdByMemberName: member.name,
                );
                await _supabaseService.logSymptomEvent(newSymptomEvent);
                // Pop the dialog first, using the dialog's context
                Navigator.pop(dialogContext); // Use dialogContext here
                // Now check if the underlying widget is still mounted before updating its state
                if (!mounted) return;
                setState(() {
                  _symptomsFuture = _loadSymptoms();
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Events')),
      body: FutureBuilder<List<SymptomEvent>>(
        future: _symptomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No symptom events logged yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(event.whatHappened ?? 'No description'),
                  subtitle: Text(
                    'Severity: ${event.severity ?? 'N/A'}\n'
                    'Logged by ${event.createdByMemberName ?? 'Unknown'} on ${DateFormat.yMMMd().format(event.eventTime!)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSymptomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
