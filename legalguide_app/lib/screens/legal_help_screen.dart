import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/legal_help_contacts.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_badge.dart';

IconData _iconForContact(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('women')) return Icons.volunteer_activism_rounded;
  if (lower.contains('child')) return Icons.child_care_rounded;
  if (lower.contains('cyber')) return Icons.security_rounded;
  if (lower.contains('consumer')) return Icons.shopping_cart_rounded;
  if (lower.contains('legal aid') || lower.contains('nalsa')) return Icons.balance_rounded;
  if (lower.contains('police')) return Icons.local_police_rounded;
  return Icons.support_agent_rounded;
}

class LegalHelpScreen extends StatelessWidget {
  const LegalHelpScreen({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await canLaunchUrl(uri) && await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for $number')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling is not supported on this device — dial $number manually.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Legal Help', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: legalHelpContacts.length,
        itemBuilder: (context, index) {
          final contact = legalHelpContacts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                IconBadge(icon: _iconForContact(contact.name), color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.description,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _call(context, contact.number),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.call_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          contact.number,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
