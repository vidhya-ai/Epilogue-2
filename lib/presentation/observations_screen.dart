import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

class ObservationsScreen extends StatefulWidget {
  const ObservationsScreen({super.key});

  @override
  State<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends State<ObservationsScreen> {
  final _supabaseService = SupabaseService();
  final _session = SessionManager();
  final _uuid = const Uuid();
  late Future<List<Observation>> _observationsFuture;

  @override
  void initState() {
    super.initState();
    _observationsFuture = _loadObservations();
  }

  Future<List<Observation>> _loadObservations() async {
    final careTeamId = _session.currentCareTeam?.id;
    if (careTeamId == null) {
      throw Exception('Not logged in');
    }
    return _supabaseService.getObservations(careTeamId);
  }

  void _showAddObservationDialog() {
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) { // Explicitly name dialogContext
        return AlertDialog(
          title: const Text('Add Observation'),
          content: TextField(
            controller: contentController,
            decoration: const InputDecoration(
              labelText: 'What did you notice?',
            ),
            maxLines: 3,
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

                final newObservation = Observation(
                  id: _uuid.v4(),
                  careTeamId: careTeamId,
                  content: contentController.text,
                  createdAt: DateTime.now(),
                  createdByMemberId: member.id,
                  createdByMemberName: member.name,
                );
                await _supabaseService.addObservation(newObservation);
                // Pop the dialog first, using the dialog's context
                Navigator.pop(dialogContext); // Use dialogContext here
                // Now check if the underlying widget is still mounted before updating its state
                if (!mounted) return;
                setState(() {
                  _observationsFuture = _loadObservations();
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
      appBar: AppBar(title: const Text('Observations')),
      body: FutureBuilder<List<Observation>>(
        future: _observationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final observations = snapshot.data ?? [];
          if (observations.isEmpty) {
            return const Center(child: Text('No observations yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: observations.length,
            itemBuilder: (context, index) {
              final observation = observations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(observation.content ?? ''),
                  subtitle: Text(
                    'by ${observation.createdByMemberName ?? 'Unknown'} on ${DateFormat.yMMMd().format(observation.createdAt!)}',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddObservationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
