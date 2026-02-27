import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    (user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0]
                            : user?.email?[0] ?? 'U')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'CarGuardian User',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _SectionLabel('Language'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _LanguageTile(
                    lang: 'en',
                    label: 'English',
                    flag: '🇺🇸',
                    currentLocale: locale.locale.languageCode,
                    onTap: () => locale.setLocale('en')),
                const Divider(height: 1),
                _LanguageTile(
                    lang: 'hi',
                    label: 'हिंदी',
                    flag: '🇮🇳',
                    currentLocale: locale.locale.languageCode,
                    onTap: () => locale.setLocale('hi')),
                const Divider(height: 1),
                _LanguageTile(
                    lang: 'ta',
                    label: 'தமிழ்',
                    flag: '🇮🇳',
                    currentLocale: locale.locale.languageCode,
                    onTap: () => locale.setLocale('ta')),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _SectionLabel('About'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.shield_outlined,
                  title: 'CarGuardian',
                  subtitle: 'Version 1.0.0',
                ),
                const Divider(height: 1),
                _SettingTile(
                  icon: Icons.psychology,
                  title: 'AI Engine',
                  subtitle: 'GPT-4 Vision',
                ),
                const Divider(height: 1),
                _SettingTile(
                  icon: Icons.cloud_outlined,
                  title: 'Backend',
                  subtitle: 'Flask + Firebase',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String lang;
  final String label;
  final String flag;
  final String currentLocale;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.lang,
    required this.label,
    required this.flag,
    required this.currentLocale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentLocale == lang;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label,
          style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.normal)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
