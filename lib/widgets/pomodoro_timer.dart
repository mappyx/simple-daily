import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/language_provider.dart';

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  static const int _focusMinutes = 25;
  int _secondsRemaining = _focusMinutes * 60;
  bool _isRunning = false;
  Timer? _timer;

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _stopTimer();
          _showTimeUpDialog();
        }
      });
    } else {
      _stopTimer();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _secondsRemaining = _focusMinutes * 60;
    });
  }

  void _showTimeUpDialog() {
    final lang = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Time's up!"),
        content: const Text("Take a break."),
        actions: [
          TextButton(
             onPressed: () {
               Navigator.pop(context);
               _resetTimer();
             }, 
             child: Text(lang.translate('close'))
          )
        ],
      ),
    );
  }

  String get _timerString {
    final minutes = (_secondsRemaining / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Tooltip(
      message: lang.translate('pomodoro_tooltip'),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.primary, width: 0.5),
      ),
      textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isRunning ? AppColors.secondary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer, 
              size: 16, 
              color: _isRunning ? AppColors.secondary : Colors.grey
            ),
            const SizedBox(width: 8),
            Text(
              _timerString,
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: _isRunning ? lang.translate('pomodoro_pause') : lang.translate('pomodoro_play'),
              child: InkWell(
                onTap: _toggleTimer,
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: lang.translate('pomodoro_reset'),
              child: InkWell(
                onTap: _resetTimer,
                child: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
