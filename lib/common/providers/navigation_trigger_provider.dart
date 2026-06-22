import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationTriggerNotifier extends StateNotifier<Map<String, int>> {
  NavigationTriggerNotifier()
      : super({
          '/home': 0,
          '/admin/dashboard': 0,
        });
  void trigger(String path) {
    if (state.containsKey(path)) {
      state = {
        ...state,
        path: state[path]! + 1,
      };
    }
  }
}

final navigationTriggerProvider =
    StateNotifierProvider<NavigationTriggerNotifier, Map<String, int>>((ref) {
  return NavigationTriggerNotifier();
});
