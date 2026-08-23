import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/backend_config_service.dart';

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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text('About', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Color(0xFF6366F1), size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LegalGuide', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Simplified Legal Knowledge & Assistance',
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
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
              style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(120), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 22),
                      const SizedBox(width: 8),
                      Text('Disclaimer',
                          style: GoogleFonts.inter(color: Colors.amberAccent, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LegalGuide is an educational prototype. Information provided does not '
                    'constitute certified legal advice and may not reflect the most current '
                    'legal developments. Always consult a qualified legal professional for '
                    'advice about your specific situation.',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Legal content in this app is sourced from official statutes and cross-verified '
              'against multiple independent legal-reference sources, with the source and last '
              'verification date shown on each section.',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 28),
            Text('Server Connection', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'Address the app uses for online features (AI Assistant, syncing content). '
              'Update this if your LegalGuide server\'s address changes, e.g. a new tunnel URL.',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://your-tunnel-url.trycloudflare.com/api',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveUrl,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _resetUrl,
                  child: Text('Reset to default', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
                ),
              ],
            ),
            if (_savedMessage != null) ...[
              const SizedBox(height: 8),
              Text(_savedMessage!, style: GoogleFonts.inter(color: const Color(0xFF6EE7B7), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
