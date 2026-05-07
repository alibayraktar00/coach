import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:developer' as dev;
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';
import '../../core/utils/nlp_parser.dart';
import '../../core/utils/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

class VoiceInputOverlay extends ConsumerStatefulWidget {
  final Function(String title, DateTime dateTime) onResult;

  const VoiceInputOverlay({super.key, required this.onResult});

  @override
  ConsumerState<VoiceInputOverlay> createState() => _VoiceInputOverlayState();
}

class _VoiceInputOverlayState extends ConsumerState<VoiceInputOverlay> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _text = ''; // Will be initialized in build if empty, or just kept empty
    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => dev.log('onStatus: $val'),
      onError: (val) => dev.log('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      final currentLocale = ref.read(localeProvider);
      final localeId = currentLocale.languageCode == 'tr' ? 'tr_TR' : 'en_US';
      
      _speech.listen(
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
          if (val.hasConfidenceRating && val.confidence > 0) {
            _confidence = val.confidence;
          }
        }),
        localeId: localeId,
      );
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    
    if (_text.isNotEmpty && _text != 'Dinliyorum...') {
      final result = NLPParser.parse(_text);
      widget.onResult(result['title'], result['dateTime']);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.mic, 
                      size: 48, 
                      color: _isListening ? AntigravityTheme.secondary : AntigravityTheme.primary,
                    ),
                    if (_isListening) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.confidence((_confidence * 100).toStringAsFixed(0)),
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      _text.isEmpty ? l10n.listening : _text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _stopListening,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AntigravityTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.done, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
