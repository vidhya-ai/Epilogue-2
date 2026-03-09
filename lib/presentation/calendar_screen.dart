import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/session_manager.dart';
import '../core/supabase_service.dart';
import '../domain/models.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _supabaseService = SupabaseService();
  final _session = SessionManager();
  final _uuid = const Uuid();
  late Future<List<CalendarEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  Future<List<CalendarEvent>> _loadEvents() async {
    final careTeamId = _session.currentCareTeam?.id;
    if (careTeamId == null) {
      throw Exception('Not logged in');
    }
    return _supabaseService.getCalendarEvents(careTeamId);
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context, // This is _CalendarScreenState's context
      builder: (dialogContext) {
        // This is the AlertDialog's context
        return AlertDialog(
          title: const Text('Add Calendar Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: dialogContext, // Use dialogContext here
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                    dateController.text = DateFormat.yMMMd().format(pickedDate);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext), // Use dialogContext here
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final member = _session.currentMember;
                final careTeamId = _session.currentCareTeam?.id;
                if (member == null ||
                    careTeamId == null ||
                    selectedDate == null) {
                  return;
                }

                final newEvent = CalendarEvent(
                  id: _uuid.v4(),
                  careTeamId: careTeamId,
                  title: titleController.text,
                  date: selectedDate!.toIso8601String(),
                  createdAt: DateTime.now(),
                  createdByMemberId: member.id,
                );
                await _supabaseService.addCalendarEvent(newEvent);
                Navigator.pop(dialogContext); // Use dialogContext here
                if (!mounted) return;
                setState(() {
                  _eventsFuture = _loadEvents();
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF74659A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "${SessionManager().currentCareTeam?.patientFirstName ?? 'Patient'}'s Calendar",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74659A), Color(0xFFDFDBE5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<CalendarEvent>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return const Center(child: Text('No events scheduled.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final eventDate = DateTime.parse(event.date!);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(eventDate.day.toString()),
                    ),
                    title: Text(event.title ?? ''),
                    subtitle: Text(DateFormat.yMMMd().format(eventDate)),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
