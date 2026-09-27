import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../services/locale_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';

/// Shows a rich bottom sheet for voice input (Speech to Text)
/// Returns recognized text if accepted, or null if cancelled.
Future<String?> showVoiceSearchModal({
  required BuildContext context,
  String? hintText,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => VoiceSearchModal(hintText: hintText),
  );
}

class VoiceSearchModal extends StatefulWidget {
  final String? hintText;

  const VoiceSearchModal({super.key, this.hintText});

  @override
  State<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends State<VoiceSearchModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  String _spokenText = '';
  String _selectedLocale = 'auto';
  bool _isListening = false;
  String _statusMessage = '';
  double _soundLevel = 0.0;

  final List<Map<String, String>> _availableLanguages = const [
    {'name': '🌐 Auto', 'code': 'auto'},
    {'name': 'తెలుగు (Telugu)', 'code': 'te_IN'},
    {'name': 'हिन्दी (Hindi)', 'code': 'hi_IN'},
    {'name': 'English', 'code': 'en_IN'},
    {'name': 'தமிழ் (Tamil)', 'code': 'ta_IN'},
    {'name': 'ಕನ್ನಡ (Kannada)', 'code': 'kn_IN'},
    {'name': 'മലയാളം (Malayalam)', 'code': 'ml_IN'},
    {'name': 'मराठी (Marathi)', 'code': 'mr_IN'},
    {'name': 'বাংলা (Bengali)', 'code': 'bn_IN'},
    {'name': 'ગુજરાતી (Gujarati)', 'code': 'gu_IN'},
    {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'code': 'pa_IN'},
    {'name': 'اردو (Urdu)', 'code': 'ur_IN'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.28).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Initial locale
    final appLang = LocaleService.language.value;
    if (appLang == 'te') {
      _selectedLocale = 'te_IN';
    } else if (appLang == 'hi') {
      _selectedLocale = 'hi_IN';
    } else {
      _selectedLocale = 'auto';
    }

    _startListeningFlow();
  }

  @override
  void dispose() {
    _animController.dispose();
    SpeechService.stopListening();
    super.dispose();
  }

  String _getListeningPrompt() {
    if (_selectedLocale.startsWith('te')) {
      return 'వింటున్నారు... ఇప్పుడు మాట్లాడండి';
    } else if (_selectedLocale.startsWith('hi')) {
      return 'सुन रहे हैं... कृपया बोलिए';
    } else if (_selectedLocale.startsWith('ta')) {
      return 'கேட்கிறது... இப்போது பேசுங்கள்';
    } else if (_selectedLocale.startsWith('kn')) {
      return 'ಆಲಿಸುತ್ತಿದೆ... ಮಾತನಾಡಿ';
    }
    return 'Listening... Speak now';
  }

  String _getTapToStartPrompt() {
    if (_selectedLocale.startsWith('te')) {
      return 'మాట్లాడటానికి మైక్ నొక్కండి';
    } else if (_selectedLocale.startsWith('hi')) {
      return 'बोलने के लिए माइक दबाएं';
    } else if (_selectedLocale.startsWith('ta')) {
      return 'பேச மைக்-ஐ அழுத்தவும்';
    } else if (_selectedLocale.startsWith('kn')) {
      return 'ಮಾತನಾಡಲು ಮೈಕ್ ಒತ್ತಿರಿ';
    }
    return 'Tap mic to speak';
  }

  Future<void> _startListeningFlow() async {
    setState(() {
      _statusMessage = _getListeningPrompt();
      _isListening = true;
      _soundLevel = 0.0;
    });

    final success = await SpeechService.startListening(
      localeId: _selectedLocale,
      onSoundLevel: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = (level / 10).clamp(0.0, 1.0);
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _soundLevel = 0.0;
          if (error.contains('timeout') || error.contains('no_match')) {
            _statusMessage = _spokenText.isNotEmpty ? tr('Done') : _getTapToStartPrompt();
          } else if (error.contains('network')) {
            _statusMessage = tr('Check internet or tap mic to try again');
          } else {
            _statusMessage = _getTapToStartPrompt();
          }
        });
      },
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _spokenText = text;
          if (isFinal && text.trim().isNotEmpty) {
            _isListening = false;
            _statusMessage = tr('Done');
          }
        });
      },
    );

    if (!mounted) return;
    if (!success) {
      setState(() {
        _isListening = false;
        _statusMessage = tr('Could not start microphone. Check permissions.');
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await SpeechService.stopListening();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
        _statusMessage = _spokenText.trim().isNotEmpty ? tr('Done') : _getTapToStartPrompt();
      });
    } else {
      await _startListeningFlow();
    }
  }

  void _onLanguageSelected(String locale) {
    if (_selectedLocale == locale) return;
    setState(() {
      _selectedLocale = locale;
    });
    SpeechService.stopListening().then((_) {
      _startListeningFlow();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    tr('Voice Search'),
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal scrollable language selection chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availableLanguages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final lang = _availableLanguages[index];
                return _buildLangChip(lang['name']!, lang['code']!);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Animated Mic Circle with sound level ripples
          Center(
            child: GestureDetector(
              onTap: _toggleListening,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening) ...[
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final waveScale = _pulseAnimation.value + (_soundLevel * 0.4);
                        return Container(
                          width: 84 * waveScale,
                          height: 84 * waveScale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.22),
                          ),
                        );
                      },
                    ),
                  ],
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [AppColors.accent, const Color(0xFF6366F1)]
                            : [AppColors.surface, AppColors.border],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppColors.accent : Colors.black).withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.white : AppColors.textPrimary,
                      size: 38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status prompt text
          Text(
            _statusMessage.isNotEmpty
                ? _statusMessage
                : (_isListening ? _getListeningPrompt() : _getTapToStartPrompt()),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _isListening ? AppColors.accent : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),

          // Recognized Text Display Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(minHeight: 64, maxHeight: 110),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _spokenText.isNotEmpty ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                _spokenText.isEmpty
                    ? (widget.hintText ?? tr('Say anything in any language...'))
                    : _spokenText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _spokenText.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: _spokenText.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    tr('Cancel'),
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _spokenText.trim().isNotEmpty
                      ? () {
                          SpeechService.stopListening();
                          Navigator.pop(context, _spokenText.trim());
                        }
                      : null,
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  label: Text(
                    tr('Use Text'),
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String locale) {
    final isSelected = _selectedLocale == locale;
    return GestureDetector(
      onTap: () => _onLanguageSelected(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
