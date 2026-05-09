# ShieldX 🛡️

![ShieldX Banner](assets/images/banner.png)

**ShieldX** is a sophisticated **Crime Report Portal Management** platform built with Flutter. It empowers citizens to report incidents, locate emergency services, and provides authorities with a robust system to manage and track reports securely and efficiently.

## ✨ Features

- **🛡️ Secure Reporting**: Submit and track complaints with real-time status updates.
- **🕵️ Anonymous Mode**: Report incidents without revealing your identity for sensitive cases.
- **📍 Smart Mapping**: Locate the nearest police stations and emergency services using live GPS and the Overpass API.
- **💬 Real-time Chat**: Direct, encrypted communication between citizens and police officers.
- **📊 Admin Dashboard**: Data-driven insights and complaint management for authorities.
- **🔔 Instant Notifications**: Stay updated on the progress of your reports and new messages.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Backend-as-a-Service**: [Supabase](https://supabase.com/) (Auth, Database, Storage, Edge Functions)
- **Maps**: Google Maps Flutter & OSM (Overpass API)
- **Architecture**: Clean Architecture with Provider/Service patterns

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK
- A Supabase account and project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jogonnath1/Shieldx.git
   cd Shieldx
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase:**
   Create a `lib/core/constants/secrets.dart` (ensure this is in your `.gitignore`) and add your Supabase credentials:
   ```dart
   class SupabaseSecrets {
     static const String url = 'YOUR_SUPABASE_URL';
     static const String anonKey = 'YOUR_ANON_KEY';
   }
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙌 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---
Developed with ❤️ by [Jogonnath](https://github.com/jogonnath1)
