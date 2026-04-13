import 'package:flutter/material.dart';

class MusicProvider with ChangeNotifier {
  String? _activeMusicUrl;
  String? _activeMusicTitle;
  bool _isPlaying = false;

  String? get activeMusicUrl => _activeMusicUrl;
  String? get activeMusicTitle => _activeMusicTitle;
  bool get isPlaying => _isPlaying;

  void playMusic(String url, String title) {
    _activeMusicUrl = url;
    _activeMusicTitle = title;
    _isPlaying = true;
    notifyListeners();
  }

  void stopMusic() {
    _activeMusicUrl = null;
    _activeMusicTitle = null;
    _isPlaying = false;
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }
}
