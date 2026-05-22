import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://thucigugoxevxwrqpxjm.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodWNpZ3Vnb3hldnh3cnFweGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4Mzg4MDAsImV4cCI6MjA5MjQxNDgwMH0.iMtMpwXaIeh3c6YVGfWIZJZSum5pYrC7RxT-FeXngUY',
  );

  print('Fetching profiles...');
  try {
    final res = await client.from('profiles').select();
    print('Profiles count: ${res.length}');
    for (var row in res) {
      print('ID: ${row['id']}');
      print('Name: ${row['name']}');
      print('Phone: ${row['phone']}');
      print('NID: ${row['nid']}');
      print('Profession: ${row['profession']}');
      print('Present Address: ${row['present_address']}');
      print('Permanent Address: ${row['permanent_address']}');
      print('-----------------------------------------');
    }
  } catch (e) {
    print('Error: $e');
  }
}
