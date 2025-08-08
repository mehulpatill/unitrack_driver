import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDriverService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAllDrivers() async {
    final response = await _supabase
        .from('drivers')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, int>> fetchDriverStats() async {
    final response = await _supabase.from('drivers').select();
    final drivers = List<Map<String, dynamic>>.from(response);

    final total = drivers.length;

    return {
      'total': total,
    };
  }

  Future<void> updateDriverStatus(String driverId, String status) async {
    await _supabase
        .from('drivers')
        .update({'status': status})
        .eq('id', driverId);
  }

  Future<void> deleteDriver(String driverId) async {
    await _supabase.from('drivers').delete().eq('id', driverId);
  }
}
