import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/track.dart';
import '../data/repositories/ng_repository.dart';
import 'player_provider.dart';

// ─── Tab ──────────────────────────────────────────────────────────────────────

enum NgTab { featured, browse, popular, search }

// ─── Hub State ────────────────────────────────────────────────────────────────

class HubState {
  final List<Track> tracks;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final Track? currentTrack;
  final NgTab tab;

  const HubState({
    this.tracks = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentTrack,
    this.tab = NgTab.featured,
  });

  HubState copyWith({
    List<Track>? tracks,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    Track? currentTrack,
    NgTab? tab,
    bool clearError = false,
    bool clearCurrentTrack = false,
  }) =>
      HubState(
        tracks: tracks ?? this.tracks,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : error ?? this.error,
        currentTrack:
            clearCurrentTrack ? null : currentTrack ?? this.currentTrack,
        tab: tab ?? this.tab,
      );
}

// ─── Repository Provider ──────────────────────────────────────────────────────

final ngRepositoryProvider = Provider<NgRepository>((ref) => NgRepository());

// ─── Hub Notifier ─────────────────────────────────────────────────────────────

class HubNotifier extends StateNotifier<HubState> {
  final NgRepository _repo;
  final PlayerNotifier _player;

  static const _pageSize = 24;
  int _offset = 0;
  bool _hasMore = false;
  String _query = '';
  final Map<String, String> _mp3Cache = {};

  HubNotifier(this._repo, this._player) : super(const HubState()) {
    loadFeatured();
  }

  // ─── Загрузка вкладок ─────────────────────────────────────────────────────

  Future<void> loadFeatured() {
    _offset = 0;
    _hasMore = false;
    return _loadTracks(
      tab: NgTab.featured,
      fetch: () => _repo.getFeaturedTracks(),
    );
  }

  Future<void> loadBrowse() {
    _offset = 0;
    _hasMore = true;
    return _loadTracks(
      tab: NgTab.browse,
      fetch: () => _repo.getBrowseTracks(0),
    );
  }

  Future<void> loadPopular() {
    _offset = 0;
    _hasMore = true;
    return _loadTracks(
      tab: NgTab.popular,
      fetch: () => _repo.getPopularTracks(0),
    );
  }

  Future<void> search(String query) {
    if (query.trim().isEmpty) return loadFeatured();
    _query = query;
    _offset = 0;
    _hasMore = true;
    return _loadTracks(
      tab: NgTab.search,
      fetch: () => _repo.searchTracks(query, 0),
    );
  }

  // ─── Пагинация ────────────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (state.isLoadingMore || !_hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextOffset = _offset + _pageSize;

    try {
      final newTracks = switch (state.tab) {
        NgTab.browse   => await _repo.getBrowseTracks(nextOffset),
        NgTab.popular  => await _repo.getPopularTracks(nextOffset),
        NgTab.search   => await _repo.searchTracks(_query, nextOffset),
        NgTab.featured => <Track>[],
      };

      if (newTracks.isEmpty) {
        _hasMore = false;
      } else {
        final existingIds = state.tracks.map((t) => t.id).toSet();
        final deduped = newTracks.where((t) => !existingIds.contains(t.id)).toList();
        if (deduped.isNotEmpty) {
          _offset = nextOffset;
          state = state.copyWith(tracks: [...state.tracks, ...deduped]);
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Ошибка загрузки: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // ─── Воспроизведение ──────────────────────────────────────────────────────

  Future<void> playTrack(Track track) async {
    state = state.copyWith(currentTrack: track, clearError: true);

    try {
      final url = _mp3Cache[track.id] ?? await _repo.getMp3Url(track);
      if (url == null) {
        state = state.copyWith(error: 'Не удалось найти ссылку на трек');
        return;
      }
      _mp3Cache[track.id] = url;
      await _player.play(
        url: url,
        title: track.title,
        artist: track.artist,
        artworkUri: track.aIconUrl,
      );
    } catch (e) {
      state = state.copyWith(error: 'Ошибка воспроизведения: ${e.toString()}');
    }
  }

  Future<void> playNext() async {
    final list = state.tracks;
    final idx = list.indexWhere((t) => t.id == state.currentTrack?.id);
    if (idx != -1 && idx + 1 < list.length) {
      await playTrack(list[idx + 1]);
    } else if (idx + 1 >= list.length) {
      await loadMore();
    }
  }

  Future<void> playPrev() async {
    final list = state.tracks;
    final idx = list.indexWhere((t) => t.id == state.currentTrack?.id);
    if (idx > 0) await playTrack(list[idx - 1]);
  }

  bool get hasPrev {
    final idx = state.tracks.indexWhere((t) => t.id == state.currentTrack?.id);
    return idx > 0;
  }

  bool get hasNext {
    final list = state.tracks;
    final idx = list.indexWhere((t) => t.id == state.currentTrack?.id);
    return idx != -1 && idx + 1 < list.length;
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<void> _loadTracks({
    required NgTab tab,
    required Future<List<Track>> Function() fetch,
  }) async {
    state = state.copyWith(
      isLoading: true,
      tracks: [],
      tab: tab,
      clearError: true,
    );
    try {
      final tracks = await fetch();
      state = state.copyWith(tracks: tracks);
    } catch (e) {
      state = state.copyWith(error: 'Ошибка загрузки: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final hubProvider = StateNotifierProvider<HubNotifier, HubState>((ref) {
  final repo   = ref.watch(ngRepositoryProvider);
  final player = ref.watch(playerProvider.notifier);
  return HubNotifier(repo, player);
});
