import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/backend_config_service.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final TextEditingController _urlController;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    await BackendConfigService.setBaseUrl(_urlController.text);
    setState(() {
      _urlController.text = ApiService.baseUrl;
      _savedMessage = 'Saved. New requests will use this address.';
    });
  }

  Future<void> _resetUrl() async {
    await BackendConfigService.setBaseUrl('');
    setState(() {
      _urlController.text = ApiService.baseUrl;
      _savedMessage = 'Reset to default.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('About', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LegalGuide', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Simplified Legal Knowledge & Assistance',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'LegalGuide helps you look up Indian laws and legal provisions in plain '
              'language, browse offline once synced, and ask an AI assistant questions — '
              'answered either from what\'s actually stored in the app (offline) or from a '
              'general AI model when you\'re online.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withAlpha(120), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                      const SizedBox(width: 8),
                      Text('Disclaimer',
                          style: GoogleFonts.inter(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LegalGuide is an educational prototype. Information provided does not '
                    'constitute certified legal advice and may not reflect the most current '
                    'legal developments. Always consult a qualified legal professional for '
                    'advice about your specific situation.',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Legal content in this app is sourced from official statutes and cross-verified '
              'against multiple independent legal-reference sources, with the source and last '
              'verification date shown on each section.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 28),
            Text('Server Connection', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'Address the app uses for online features (AI Assistant, syncing content). '
              'Update this if your LegalGuide server\'s address changes, e.g. a new tunnel URL.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://your-tunnel-url.trycloudflare.com/api',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveUrl,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _resetUrl,
                  child: Text('Reset to default', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
              ],
            ),
            if (_savedMessage != null) ...[
              const SizedBox(height: 8),
              Text(_savedMessage!, style: GoogleFonts.inter(color: AppColors.success, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
