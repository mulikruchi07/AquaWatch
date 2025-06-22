import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveTankDetails({
    required double height,
    required double capacity,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('tanks').upsert({
      'user_id': userId,
      'height': height,
      'capacity': capacity,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveDeviceDetails({
    required String esp32Id,
    String? wifiSsid,
    String? wifiPassword,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('devices').insert({
      'user_id': userId,
      'esp32_id': esp32Id,
      'wifi_ssid': wifiSsid,
      'wifi_password': wifiPassword,
    });
  }

  Future<void> saveSensorReading({
    required String deviceId,
    required double tdsValue,
    required double waterLevel,
    required bool valveStatus,
  }) async {
    await _supabase.from('sensor_readings').insert({
      'device_id': deviceId,
      'tds_value': tdsValue,
      'water_level': waterLevel,
      'valve_status': valveStatus,
    });
  }

  Future<void> saveValveAction({
    required String deviceId,
    required String action,
    required String triggeredBy,
  }) async {
    await _supabase.from('valve_actions').insert({
      'device_id': deviceId,
      'action': action,
      'triggered_by': triggeredBy,
    });
  }
}