import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/hub_provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/ng_theme.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const PlayerScreen({super.key, required this.onBack});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Duration _position = Duration.zero;
  bool _isSeeking = false;
  bool _downloadDone = false;
  Timer? _ticker;
  String? _lastTrackId;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_isSeeking && mounted) {
        final isPlaying = ref.read(playerProvider).isPlaying;
        if (isPlaying) {
          setState(() {
            _position = ref.read(playerProvider.notifier).currentPosition;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hub = ref.watch(hubProvider);
    final playerState = ref.watch(playerProvider);
    final track = hub.currentTrack;

    // Сброс позиции при смене трека
    if (track?.id != _lastTrackId) {
      _lastTrackId = track?.id;
      _position = Duration.zero;
      _downloadDone = false;
    }

    final hasPrev = ref.read(hubProvider.notifier).hasPrev;
    final hasNext = ref.read(hubProvider.notifier).hasNext;
    final isLoading = hub.isLoading;
    final duration = playerState.duration;

    return Scaffold(
      backgroundColor: ngBgDark,
      body: Column(
        children: [
          // ── Топбар ────────────────────────────────────────────────────────
          Container(
            color: ngBgDeep,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 4,
              left: 4,
              right: 4,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back,
                      color: ngTextPrimary),
                ),
                const Expanded(
                  child: Text(
                    'Now Playing',
                    style: TextStyle(
                      color: ngTextPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: track != null
                      ? () {
                          // Скачивание через браузер / внешний обработчик
                          // (Flutter аналог DownloadManager — url_launcher)
                          final mp3 = _getMp3Url(hub);
                          if (mp3 != null) {
                            launchUrl(Uri.parse(mp3),
                                mode: LaunchMode.externalApplication);
                            setState(() => _downloadDone = true);
                          }
                        }
                      : null,
                  icon: Icon(
                    _downloadDone
                        ? Icons.download_done
                        : Icons.download,
                    color: _downloadDone
                        ? ngGreen
                        : track != null
                            ? ngOrange
                            : ngTextDim,
                  ),
                ),
              ],
            ),
          ),

          // ── Контент ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Обложка ─────────────────────────────────────────────
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: track != null
                              ? CachedNetworkImage(
                                  imageUrl: track.iconUrl,
                                  width: 240,
                                  height: 240,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: ngBgElevated),
                                  errorWidget: (_, __, ___) => Container(
                                    color: ngBgElevated,
                                    child: const Icon(Icons.music_note,
                                        color: ngTextMuted, size: 60),
                                  ),
                                )
                              : Container(
                                  width: 240,
                                  height: 240,
                                  color: ngBgElevated,
                                ),
                        ),
                        // «Отверстие диска»
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: ngBgDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Мета ────────────────────────────────────────────────
                  Text(
                    track?.title ?? '—',
                    style: const TextStyle(
                      color: ngOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    track?.artist ?? '—',
                    style: const TextStyle(
                        color: ngTextPrimary, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  if (track != null && track.genre.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      track.genre,
                      style: const TextStyle(
                          color: ngTextMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Прогресс ────────────────────────────────────────────
                  if (duration > Duration.zero) ...[
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: ngOrange,
                        activeTrackColor: ngOrange,
                        inactiveTrackColor: ngBorder,
                        overlayColor: ngOrange.withAlpha(30),
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _position.inMilliseconds
                            .toDouble()
                            .clamp(0, duration.inMilliseconds.toDouble()),
                        max: duration.inMilliseconds.toDouble(),
                        onChangeStart: (_) =>
                            setState(() => _isSeeking = true),
                        onChanged: (v) => setState(() =>
                            _position =
                                Duration(milliseconds: v.toInt())),
                        onChangeEnd: (v) {
                          ref.read(playerProvider.notifier).seekTo(
                              Duration(milliseconds: v.toInt()));
                          setState(() => _isSeeking = false);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(_position),
                            style: const TextStyle(
                                color: ngTextMuted, fontSize: 12)),
                        Text(_fmt(duration),
                            style: const TextStyle(
                                color: ngTextMuted, fontSize: 12)),
                      ],
                    ),
                  ] else if (isLoading) ...[
                    LinearProgressIndicator(
                      backgroundColor: ngBorder,
                      color: ngOrange,
                      minHeight: 2,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Контролы ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Назад
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: IconButton(
                          onPressed: hasPrev
                              ? () => ref
                                  .read(hubProvider.notifier)
                                  .playPrev()
                              : null,
                          icon: Icon(
                            Icons.skip_previous,
                            size: 36,
                            color: hasPrev ? ngTextPrimary : ngTextDim,
                          ),
                        ),
                      ),

                      // Play / Pause
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => ref
                                .read(playerProvider.notifier)
                                .togglePlayPause(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: ngOrange,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: isLoading
                              ? const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Icon(
                                  playerState.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 42,
                                ),
                        ),
                      ),

                      // Вперёд
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: IconButton(
                          onPressed: hasNext
                              ? () => ref
                                  .read(hubProvider.notifier)
                                  .playNext()
                              : null,
                          icon: Icon(
                            Icons.skip_next,
                            size: 36,
                            color: hasNext ? ngTextPrimary : ngTextDim,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ссылка на NG
                  if (track != null)
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(
                            'https://www.newgrounds.com/audio/listen/${track.id}'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        'newgrounds.com/audio/listen/${track.id}',
                        style: const TextStyle(
                            color: ngTextDim, fontSize: 11),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getMp3Url(HubState hub) {
    // mp3Url хранится в кэше провайдера; отдаём через currentTrack.mp3Url
    // если он уже был resolved (иначе кнопка недоступна)
    return hub.currentTrack?.mp3Url;
  }
}
