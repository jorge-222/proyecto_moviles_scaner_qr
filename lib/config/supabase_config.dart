import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://yqhmfggeekboswnpkiyt.supabase.co';
  static const String supabaseKey =
      'sb_publishable_z4kwmTla3Asc2BlB_z3xVQ_D-3huezf';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
