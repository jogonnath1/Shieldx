import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://thucigugoxevxwrqpxjm.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodWNpZ3Vnb3hldnh3cnFweGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4Mzg4MDAsImV4cCI6MjA5MjQxNDgwMH0.iMtMpwXaIeh3c6YVGfWIZJZSum5pYrC7RxT-FeXngUY',
  );

  print('Fetching complaints...');
  try {
    final res = await client.from('complaints').select().limit(5);
    print('Complaints count: ${res.length}');
    if (res.isNotEmpty) {
      print('Keys of first complaint: ${res[0].keys.toList()}');
      print('First complaint user_id: ${res[0]['user_id']}');
      print('First complaint user_email: ${res[0]['user_email']}');
      print('First complaint user_name: ${res[0]['user_name']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
