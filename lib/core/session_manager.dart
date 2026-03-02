import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      try {
        // Restore full objects from Supabase
        final teamResp = await Supabase.instance.client
            .from('care_teams')
            .select()
            .eq('id', teamId)
            .maybeSingle();
        final memberResp = await Supabase.instance.client
            .from('members')
            .select()
            .eq('id', memberId)
            .maybeSingle();
        if (teamResp != null && memberResp != null) {
          _currentCareTeam = CareTeam.fromJson(teamResp);
          _currentMember = Member.fromJson(memberResp);
          return true;
        }
      } catch (_) {
        // If fetch fails, clear stale session
      }
      await clearSession();
      return false;
    }
    return false;
  }
}
