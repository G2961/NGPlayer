import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/track.dart';
import '../../theme/ng_theme.dart';

class MiniPlayer extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: ngBorder),
        InkWell(
          onTap: onTap,
          child: Container(
            color: ngBgDeep,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: track.iconUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 40, height: 40, color: ngBgElevated),
                    errorWidget: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: ngBgElevated,
                      child: const Icon(Icons.music_note,
                          color: ngTextMuted, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          color: ngOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: const TextStyle(
                            color: ngTextMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: ngOrange,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
