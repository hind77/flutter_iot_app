import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_colors.dart';
import '../providers/providers.dart';

class VoiceCommandFab extends ConsumerStatefulWidget {
  const VoiceCommandFab({super.key});

  @override
  ConsumerState<VoiceCommandFab> createState() => _VoiceCommandFabState();
}

class _VoiceCommandFabState extends ConsumerState<VoiceCommandFab> {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() {});
        }
      },
      onError: (error) {
         if (mounted) setState(() {});
         debugPrint("Speech Error: $error");
      }
    );
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
    
    // Show listening bottom sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildListeningSheet(),
      ).whenComplete(() {
        _stopListening();
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    _lastWords = result.recognizedWords;
    if (mounted) setState(() {});
    
    if (result.finalResult) {
      _processCommand(_lastWords);
      // Small delay to let user see final words before closing
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
    }
  }

  void _processCommand(String command) {
    command = command.toLowerCase();
    String message = "Command not recognized";
    
    if ((command.contains("turn on") || command.contains("start") || command.contains("active")) && command.contains("fan")) {
      ref.read(actuatorProvider.notifier).toggle("kitchen_fan");
      message = "Turning on the Kitchen Fan";
    } else if ((command.contains("turn off") || command.contains("stop") || command.contains("desactive")) && command.contains("fan")) {
      ref.read(actuatorProvider.notifier).toggle("kitchen_fan");
      message = "Turning off the Kitchen Fan";
    } else if (command.contains("light")) {
      ref.read(actuatorProvider.notifier).toggle("living_room_light");
      message = "Toggling Living Room Light";
    } else if (command.contains("temperature")) {
      message = "Current temperature info is on your dashboard";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentCyan,
      ),
    );
  }

  Widget _buildListeningSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 300,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _speechToText.isListening ? 'Listening...' : 'Thinking...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.accentCyan,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 24),
          // Pulsing mic animation would go here, for now using a simple icon
          Icon(
            Icons.mic,
            size: 64,
            color: _speechToText.isListening ? AppColors.accentCyan : AppColors.systemGray,
          ),
          const SizedBox(height: 24),
          Text(
            _lastWords.isEmpty ? "Try saying 'Turn on the fan'" : _lastWords,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (!_speechToText.isListening)
            ElevatedButton(
              onPressed: () {
                _lastWords = '';
                _startListening();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan),
              child: const Text('Try Again', style: TextStyle(color: Colors.black)),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _speechToText.isNotListening ? _startListening : _stopListening,
      backgroundColor: AppColors.accentCyan,
      child: Icon(
        _speechToText.isNotListening ? Icons.mic : Icons.mic_none,
        color: AppColors.background,
      ),
    );
  }
}
