class AppConstants {
  AppConstants._();
  static const String supabaseUrl = 'https://thucigugoxevxwrqpxjm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodWNpZ3Vnb3hldnh3cnFweGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4Mzg4MDAsImV4cCI6MjA5MjQxNDgwMH0.iMtMpwXaIeh3c6YVGfWIZJZSum5pYrC7RxT-FeXngUY';
  static const String profilesTable = 'profiles';
  static const String complaintsTable = 'complaints';
  static const String officersTable = 'officers';
  static const String statusHistoryTable = 'status_history';
  static const String messagesTable = 'messages';
  static const String notificationsTable = 'notifications';
  static const String evidenceBucket = 'evidence';
  static const String avatarBucket = 'avatars';
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  static const List<String> complaintStatuses = [
    'submitted',
    'in_progress',
    'under_investigation',
    'resolved',
    'closed',
    'rejected',
  ];
  static const List<String> crimeCategories = [
    'Theft',
    'Robbery',
    'Assault',
    'Fraud',
    'Cybercrime',
    'Drug Offense',
    'Murder',
    'Kidnapping',
    'Sexual Harassment',
    'Domestic Violence',
    'Vandalism',
    'Corruption',
    'Traffic Violation',
    'Other',
  ];
  static String statusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'in_progress':
        return 'In Progress';
      case 'under_investigation':
        return 'Under Investigation';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
