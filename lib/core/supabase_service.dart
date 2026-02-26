import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Care Teams
  Future<CareTeam?> getCareTeam(String id) async {
    final response = await _client
        .from('care_teams')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return CareTeam.fromJson(response);
  }

  Future<void> createCareTeam(CareTeam team) async {
    await _client.from('care_teams').insert(team.toJson());
  }

  // Members
  Future<List<Member>> getMembers(String careTeamId) async {
    final response = await _client
        .from('members')
        .select()
        .eq('care_team_id', careTeamId);
    return (response as List).map((m) => Member.fromJson(m)).toList();
  }

  Future<void> addMember(Member member) async {
    await _client.from('members').insert(member.toJson());
  }

  // Medications
  Future<List<Medication>> getMedications(String careTeamId) async {
    final response = await _client
        .from('medications')
        .select()
        .eq('care_team_id', careTeamId);
    return (response as List).map((m) => Medication.fromJson(m)).toList();
  }

  Future<void> addMedication(Medication medication) async {
    await _client.from('medications').insert(medication.toJson());
  }

  // Dose Logs
  Future<List<DoseLog>> getDoseLogs(String careTeamId) async {
    final response = await _client
        .from('dose_logs')
        .select()
        .eq('care_team_id', careTeamId)
        .order('dose_time', ascending: false);
    return (response as List).map((d) => DoseLog.fromJson(d)).toList();
  }

  Future<void> logDose(DoseLog log) async {
    await _client.from('dose_logs').insert(log.toJson());
  }

  // Symptom Events
  Future<List<SymptomEvent>> getSymptomEvents(String careTeamId) async {
    final response = await _client
        .from('symptom_events')
        .select()
        .eq('care_team_id', careTeamId)
        .order('event_time', ascending: false);
    return (response as List).map((s) => SymptomEvent.fromJson(s)).toList();
  }

  Future<void> logSymptomEvent(SymptomEvent event) async {
    await _client.from('symptom_events').insert(event.toJson());
  }

  // Care Plans
  Future<CarePlan?> getCarePlan(String careTeamId) async {
    final response = await _client
        .from('care_plans')
        .select()
        .eq('care_team_id', careTeamId)
        .maybeSingle();
    if (response == null) return null;
    return CarePlan.fromJson(response);
  }

  Future<void> updateCarePlan(CarePlan plan) async {
    await _client.from('care_plans').upsert(plan.toJson());
  }

  // Observations
  Future<List<Observation>> getObservations(String careTeamId) async {
    final response = await _client
        .from('observations')
        .select()
        .eq('care_team_id', careTeamId)
        .order('created_at', ascending: false);
    return (response as List).map((o) => Observation.fromJson(o)).toList();
  }

  Future<void> addObservation(Observation observation) async {
    await _client.from('observations').insert(observation.toJson());
  }

  // Moments
  Future<List<Moment>> getMoments(String careTeamId) async {
    final response = await _client
        .from('moments')
        .select()
        .eq('care_team_id', careTeamId)
        .order('created_at', ascending: false);
    return (response as List).map((m) => Moment.fromJson(m)).toList();
  }

  Future<void> addMoment(Moment moment) async {
    await _client.from('moments').insert(moment.toJson());
  }

  // Calendar Events
  Future<List<CalendarEvent>> getCalendarEvents(String careTeamId) async {
    final response = await _client
        .from('calendar_events')
        .select()
        .eq('care_team_id', careTeamId)
        .order('date', ascending: true);
    return (response as List).map((e) => CalendarEvent.fromJson(e)).toList();
  }

  Future<void> addCalendarEvent(CalendarEvent event) async {
    await _client.from('calendar_events').insert(event.toJson());
  }

  // Nurse Contacts
  Future<void> logNurseContact(NurseContact contact) async {
    await _client.from('nurse_contacts').insert(contact.toJson());
  }

  // Check-ins
  Future<void> addCheckIn(CheckIn checkIn) async {
    await _client.from('check_ins').insert(checkIn.toJson());
  }

  // Shift Notes
  Future<void> addShiftNote(ShiftNote note) async {
    await _client.from('shift_notes').insert(note.toJson());
  }

  // Auth (Simple PIN-based login for now as per schema)
  Future<Member?> loginWithPin(String email, String pin) async {
    final response = await _client
        .from('members')
        .select()
        .eq('email', email)
        .eq('access_pin', pin)
        .maybeSingle();
    if (response == null) return null;
    return Member.fromJson(response);
  }
}
