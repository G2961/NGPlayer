import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/track.dart';
import '../../providers/hub_provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/ng_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/ng_top_bar.dart';
import '../widgets/track_item.dart';

class HubScreen extends ConsumerStatefulWidget {
  final void Function(Track track) onTrackClick;
  final VoidCallback onMiniPlayerClick;

  const HubScreen({
    super.key,
    required this.onTrackClick,
    required this.onMiniPlayerClick,
  });

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(hubProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectTab(int i) {
    setState(() => _selectedTab = i);
    _searchController.clear();
    _focusNode.unfocus();
    final notifier = ref.read(hubProvider.notifier);
    switch (i) {
      case 0: notifier.loadFeatured();
      case 1: notifier.loadBrowse();
      case 2: notifier.loadPopular();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hub = ref.watch(hubProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: ngBgDark,
      body: Column(
        children: [
          // ── Шапка ────────────────────────────────────────────────────────
          const NgTopBar(),

          // ── Поиск ────────────────────────────────────────────────────────
          Container(
            color: ngBgDeep,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                          color: ngTextPrimary, fontSize: 14),
                      cursorColor: ngOrange,
                      decoration: InputDecoration(
                        hintText: 'Search audio...',
                        hintStyle: const TextStyle(
                            color: ngTextMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: ngTextMuted, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    color: ngTextMuted, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _selectedTab = 0);
                                  ref
                                      .read(hubProvider.notifier)
                                      .loadFeatured();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: ngBgElevated,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: ngBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: ngOrange),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: ngBorder),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (q) {
                        _focusNode.unfocus();
                        setState(() => _selectedTab = -1);
                        ref.read(hubProvider.notifier).search(q);
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      _focusNode.unfocus();
                      setState(() => _selectedTab = -1);
                      ref
                          .read(hubProvider.notifier)
                          .search(_searchController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ngOrange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Go!',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          // ── Табы ─────────────────────────────────────────────────────────
          Container(
            color: ngBgDeep,
            child: Row(
              children: List.generate(3, (i) {
                final labels = ['FEATURED', 'BROWSE', 'POPULAR'];
                final active = _selectedTab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTab(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: active ? ngOrange : Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: active ? Colors.black : ngTextMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const Divider(height: 1, color: ngBorder),

          // ── Контент ───────────────────────────────────────────────────────
          Expanded(
            child: _buildContent(hub, playerState),
          ),

          // ── Мини-плеер ────────────────────────────────────────────────────
          if (hub.currentTrack != null)
            MiniPlayer(
              track: hub.currentTrack!,
              isPlaying: playerState.isPlaying,
              onToggle: () =>
                  ref.read(playerProvider.notifier).togglePlayPause(),
              onTap: widget.onMiniPlayerClick,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(HubState hub, PlayerState playerState) {
    if (hub.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ngOrange, strokeWidth: 2),
      );
    }

    if (hub.error != null && hub.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: ngRed, size: 48),
            const SizedBox(height: 8),
            Text(hub.error!, style: const TextStyle(color: ngRed, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: hub.tracks.length + (hub.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          const Divider(height: 0.5, color: ngBorder),
      itemBuilder: (context, i) {
        if (i >= hub.tracks.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: ngOrange, strokeWidth: 2),
              ),
            ),
          );
        }
        final track = hub.tracks[i];
        final isActive = hub.currentTrack?.id == track.id;
        return TrackItem(
          track: track,
          isActive: isActive,
          isPlaying: playerState.isPlaying && isActive,
          onTap: () => widget.onTrackClick(track),
        );
      },
    );
  }
}
