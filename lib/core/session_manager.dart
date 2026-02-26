import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  CareTeam? _currentCareTeam;
  Member? _currentMember;

  CareTeam? get currentCareTeam => _currentCareTeam;
  Member? get currentMember => _currentMember;

  Future<void> setSession(CareTeam team, Member member) async {
    _currentCareTeam = team;
    _currentMember = member;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('care_team_id', team.id);
    await prefs.setString('member_id', member.id);
  }

  Future<void> clearSession() async {
    _currentCareTeam = null;
    _currentMember = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('care_team_id');
    await prefs.remove('member_id');
  }

  Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getString('care_team_id');
    final memberId = prefs.getString('member_id');

    if (teamId != null && memberId != null) {
      // In a real app, you might want to fetch the full objects from Supabase here
      // For now, we'll just store the IDs or placeholder objects
      return true;
    }
    return false;
  }
}
