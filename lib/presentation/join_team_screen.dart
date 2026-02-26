import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/supabase_service.dart';
import '../core/session_manager.dart';

class JoinTeamScreen extends StatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;

  Future<void> _joinTeam() async {
    setState(() => _isLoading = true);
    try {
      final member = await _supabaseService.loginWithPin(
        _emailController.text,
        _pinController.text,
      );

      if (member != null && member.careTeamId != null) {
        final careTeam = await _supabaseService.getCareTeam(member.careTeamId!);
        if (careTeam != null) {
          await SessionManager().setSession(careTeam, member);
          if (mounted) context.go('/dashboard');
        } else {
          throw Exception('Care team not found.');
        }
      } else {
        throw Exception('Invalid credentials or member not found.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining team: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Join Care Team'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Your Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    decoration: const InputDecoration(labelText: 'Access PIN'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _joinTeam,
                      child: const Text('Join Team'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
