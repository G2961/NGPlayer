import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/track.dart';
import '../../theme/ng_theme.dart';

class TrackItem extends StatelessWidget {
  final Track track;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;

  const TrackItem({
    super.key,
    required this.track,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isActive ? ngBgElevated : ngBgCard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Обложка
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: track.iconUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: ngBgElevated),
                      errorWidget: (_, __, ___) => Container(
                        color: ngBgElevated,
                        child: const Icon(Icons.music_note,
                            color: ngTextMuted, size: 24),
                      ),
                    ),
                  ),
                  if (isActive)
                    ClipOval(
                      child: Container(
                        width: 52,
                        height: 52,
                        color: Colors.black54,
                        child: Icon(
                          isPlaying ? Icons.volume_up : Icons.pause,
                          color: ngOrange,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Метаданные
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: ngOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      color: ngTextPrimary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (track.genre.isNotEmpty)
                    Text(
                      track.genre,
                      style: const TextStyle(
                        color: ngTextMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Длительность
            Text(
              _formatDuration(track.duration),
              style: const TextStyle(
                color: ngTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
