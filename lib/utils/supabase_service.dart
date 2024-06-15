import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static late SupabaseClient _supabaseClient;
  static Future<void> initSupabase() async {
    _supabaseClient = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
  static SupabaseClient get supabaseClient => _supabaseClient;
}