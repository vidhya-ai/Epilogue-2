import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const configuredUrl = String.fromEnvironment('SUPABASE_URL');
  const configuredAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  const configuredKey = String.fromEnvironment('SUPABASE_KEY');

  final supabaseUrl = configuredUrl.isNotEmpty
      ? configuredUrl
      : _defaultLocalSupabaseUrl();
  final supabaseAnonKey = configuredAnonKey.isNotEmpty
      ? configuredAnonKey
      : (configuredKey.isNotEmpty
            ? configuredKey
            : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const EpilogueApp());
}

String _defaultLocalSupabaseUrl() {
  if (kIsWeb) return 'http://localhost:54321';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:54321';
  }
  return 'http://127.0.0.1:54321';
}

class EpilogueApp extends StatelessWidget {
  const EpilogueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Epilogue',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
