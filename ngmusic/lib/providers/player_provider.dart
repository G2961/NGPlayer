import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// ─── State ────────────────────────────────────────────────────────────────────

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

// ─── AudioHandler (audio_service) ────────────────────────────────────────────

class NgAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  NgAudioHandler() {
    // Пробрасываем состояние плеера в MediaItem / PlaybackState
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((s) {
      _broadcastState(_player.playbackEvent);
      if (s.processingState == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  AudioPlayer get player => _player;

  Future<void> playUrl({
    required String url,
    required String title,
    required String artist,
    String? artworkUri,
  }) async {
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist,
      artUri: artworkUri != null ? Uri.parse(artworkUri) : null,
    );
    mediaItem.add(item);
    await _player.setUrl(url);
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final isPlaying = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  @override
  Future<void> onTaskRemoved() => stop();

  void dispose() {
    _player.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final audioHandlerProvider = Provider<NgAudioHandler>((ref) {
  throw UnimplementedError('Init via ProviderScope override in main.dart');
});

class PlayerNotifier extends StateNotifier<PlayerState> {
  final NgAudioHandler _handler;

  PlayerNotifier(this._handler) : super(const PlayerState()) {
    _handler.player.playerStateStream.listen((s) {
      state = state.copyWith(
        isPlaying: s.playing,
        trackEnded: s.processingState == ProcessingState.completed,
      );
    });
    _handler.player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _handler.player.durationStream.listen((dur) {
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
    await _handler.playUrl(
      url: url,
      title: title,
      artist: artist,
      artworkUri: artworkUri,
    );
  }

  Future<void> togglePlayPause() async {
    if (_handler.player.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seekTo(Duration position) => _handler.seek(position);

  Duration get currentPosition => _handler.player.position;
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(handler);
});
