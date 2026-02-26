import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final _supabaseService = SupabaseService();
  final _session = SessionManager();
  final _uuid = const Uuid();
  late Future<List<Moment>> _momentsFuture;

  @override
  void initState() {
    super.initState();
    _momentsFuture = _loadMoments();
  }

  Future<List<Moment>> _loadMoments() async {
    final careTeamId = _session.currentCareTeam?.id;
    if (careTeamId == null) {
      throw Exception('Not logged in');
    }
    return _supabaseService.getMoments(careTeamId);
  }

  void _showAddMomentDialog() {
    final contentController = TextEditingController();

    showDialog(
      context: context, // This is _MomentsScreenState's context
      builder: (dialogContext) { // This is the AlertDialog's context
        return AlertDialog(
          title: const Text('Add a Moment'),
          content: TextField(
            controller: contentController,
            decoration: const InputDecoration(
              labelText: 'Share a memory or thought...',
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Use dialogContext here
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final member = _session.currentMember;
                final careTeamId = _session.currentCareTeam?.id;
                if (member == null || careTeamId == null) return;

                final newMoment = Moment(
                  id: _uuid.v4(),
                  careTeamId: careTeamId,
                  content: contentController.text,
                  createdAt: DateTime.now(),

                  createdByMemberId: member.id,
                  createdByMemberName: member.name,
                );
                await _supabaseService.addMoment(newMoment);
                // Pop the dialog first, using the dialog's context
                Navigator.pop(dialogContext); // Use dialogContext here
                // Now check if the underlying widget is still mounted before updating its state
                if (!mounted) return;
                setState(() {
                  _momentsFuture = _loadMoments();
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
      appBar: AppBar(title: const Text('Moments')),
      body: FutureBuilder<List<Moment>>(
        future: _momentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final moments = snapshot.data ?? [];
          if (moments.isEmpty) {
            return const Center(child: Text('No moments shared yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(moment.content ?? ''),
                      const SizedBox(height: 8),
                      Text(
                        'Shared by ${moment.createdByMemberName ?? 'Unknown'} on ${DateFormat.yMMMd().format(moment.createdAt!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMomentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
