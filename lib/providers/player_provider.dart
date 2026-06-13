import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class PlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool trackEnded;

  const PlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.trackEnded = false,
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? trackEnded,
  }) =>
      PlayerState(
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        trackEnded: trackEnded ?? this.trackEnded,
      );
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _player = AudioPlayer();

  PlayerNotifier() : super(const PlayerState()) {
    _player.playerStateStream.listen((s) {
      state = state.copyWith(
        isPlaying: s.playing,
        trackEnded: s.processingState == ProcessingState.completed,
      );
    });
    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
  }

  Future<void> play({
    required String url,
    required String title,
    required String artist,
    String? artworkUri,
  }) async {
    state = state.copyWith(trackEnded: false);
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Duration get currentPosition => _player.position;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});
