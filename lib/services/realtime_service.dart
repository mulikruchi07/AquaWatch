import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;

  void initialize(String deviceId) {
    _channel = _supabase.channel('sensor_updates');
    
    // Corrected realtime subscription using the new API
    _channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sensor_readings',
      callback: (payload) {
        if (payload.newRecord['device_id'] == deviceId) {
          // Handle new sensor reading
          final reading = payload.newRecord;
          // Update your app state with the new reading
          print('New sensor reading: $reading');
        }
      },
    ).subscribe();
  }

  void dispose() {
    _channel.unsubscribe();
  }
}