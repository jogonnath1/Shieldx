import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BangladeshTimeNotifier extends StateNotifier<DateTime> {
  Timer? _timer;
  BangladeshTimeNotifier() : super(DateTime.now()) {
    _startTimer();
  }
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final bangladeshTimeProvider =
    StateNotifierProvider<BangladeshTimeNotifier, DateTime>((ref) {
  return BangladeshTimeNotifier();
});
