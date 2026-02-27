import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../providers/auth_provider.dart";
import "../../providers/language_provider.dart";
import "../../utils/app_theme.dart";
import "../auth/login_screen.dart";

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(children: [
            CircleAvatar(radius: 40,
              backgroundColor: Colors.white30,
              child: Text((user?.displayName ?? "U").substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Text(user?.displayName ?? "User",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.white70)),
          ])),
        const SizedBox(height: 8),
        _SettingTile(icon: Icons.language, title: "Language",
          subtitle: lang.languageCode == "en" ? "English" : lang.languageCode == "hi" ? "Hindi" : "Tamil",
          onTap: () => _showLanguageSheet(context, lang)),
        _SettingTile(icon: Icons.notifications_outlined, title: "Notifications",
          subtitle: "Manage reminders", onTap: () {}),
        _SettingTile(icon: Icons.info_outline, title: "About CarGuardian",
          subtitle: "Version 1.0.0", onTap: () {}),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Sign Out"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              minimumSize: const Size(double.infinity, 50)),
          )),
        const SizedBox(height: 32),
      ])),
    );
  }

  void _showLanguageSheet(BuildContext context, LanguageProvider lang) {
    showModalBottomSheet(context: context, builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        RadioListTile<String>(title: const Text("English"), value: "en", groupValue: lang.languageCode,
          onChanged: (v) { if (v != null) lang.setLanguage(v); Navigator.pop(context); }),
        RadioListTile<String>(title: const Text("Hindi"), value: "hi", groupValue: lang.languageCode,
          onChanged: (v) { if (v != null) lang.setLanguage(v); Navigator.pop(context); }),
        RadioListTile<String>(title: const Text("Tamil"), value: "ta", groupValue: lang.languageCode,
          onChanged: (v) { if (v != null) lang.setLanguage(v); Navigator.pop(context); }),
      ])));
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(width: 42, height: 42,
      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppTheme.primaryColor, size: 22)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: onTap,
  );
}
