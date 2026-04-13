import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class MiniMusicPlayer extends StatefulWidget {
  final String musicUrl;
  final String title;
  final VoidCallback onStop;

  const MiniMusicPlayer({
    super.key,
    required this.musicUrl,
    required this.title,
    required this.onStop,
  });

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initPlayer();
  }

  void _initPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    
    _play();
  }

  Future<void> _play() async {
    final url = ApiService.getImageUrl(widget.musicUrl);
    if (url != null) {
      await _audioPlayer.play(UrlSource(url));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_note_rounded, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _duration.inMilliseconds > 0 
                        ? _position.inMilliseconds / _duration.inMilliseconds 
                        : 0,
                    backgroundColor: colors.border.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_playerState == PlayerState.playing) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.resume();
              }
            },
            icon: Icon(
              _playerState == PlayerState.playing 
                  ? Icons.pause_rounded 
                  : Icons.play_arrow_rounded,
              color: colors.text,
            ),
          ),
          IconButton(
            onPressed: widget.onStop,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}
