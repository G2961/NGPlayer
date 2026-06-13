import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class NgRepository {
  static const _base = 'https://www.newgrounds.com';
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Mobile Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  };

  // ─── Публичные методы ─────────────────────────────────────────────────────

  Future<List<Track>> getFeaturedTracks() =>
      _parseTracks('$_base/audio/featured');

  Future<List<Track>> getBrowseTracks(int offset) =>
      _parseTracks('$_base/audio/browse?offset=$offset&inner=1');

  Future<List<Track>> getPopularTracks(int offset) =>
      _parseTracks('$_base/audio/popular?offset=$offset&inner=1');

  Future<List<Track>> searchTracks(String query, int offset) {
    final q = Uri.encodeComponent(query.trim());
    final page = offset ~/ 24 + 1;
    final url = page == 1
        ? '$_base/search/conduct/audio?terms=$q'
        : '$_base/search/conduct/audio?terms=$q&page=$page';
    return _parseTracks(url);
  }

  /// Получаем URL mp3: сначала og:audio, потом buildAudioUrl
  Future<String?> getMp3Url(Track track) async {
    try {
      final doc = await _connect('$_base/audio/listen/${track.id}');
      final ogAudio = doc
          .querySelector('meta[property="og:audio"]')
          ?.attributes['content'];
      if (ogAudio != null && ogAudio.isNotEmpty) return ogAudio;
    } catch (_) {}
    return _buildAudioUrl(track);
  }

  /// Строим mp3 URL из audio.ngfiles.com через og:url → slug
  Future<String?> _buildAudioUrl(Track track) async {
    try {
      final numId = int.tryParse(track.id);
      if (numId == null) return null;
      final folder = (numId ~/ 1000) * 1000;

      final doc = await _connect('$_base/audio/listen/${track.id}');
      final ogUrl =
          doc.querySelector('meta[property="og:url"]')?.attributes['content'] ??
              '';
      // og:url вида https://www.newgrounds.com/audio/listen/1570039/rewind
      final parts = ogUrl.trimRight().split('/');
      final slug =
          (parts.last.isNotEmpty && parts.last != track.id)
              ? parts.last
              : _slugify(track.title);

      return 'https://audio.ngfiles.com/$folder/${track.id}_$slug.mp3';
    } catch (_) {
      return null;
    }
  }

  // ─── Парсинг ──────────────────────────────────────────────────────────────

  Future<List<Track>> _parseTracks(String url) async {
    try {
      final doc = await _connect(url);
      return _parseItems(doc);
    } catch (e) {
      return [];
    }
  }

  List<Track> _parseItems(Document doc) {
    final items = doc.querySelectorAll('li[data-hub-id]');

    return items
        .map((li) {
          final id = li.attributes['data-hub-id'] ?? '';
          if (id.isEmpty) return null;

          final playEl = li.querySelector('[data-audio-duration]') ??
              li.querySelector('[data-hub-id]');

          final title = (li.querySelector('h4.item-title') ??
                      li.querySelector('h4') ??
                      li.querySelector('.title'))
                  ?.text
                  .trim() ??
              '';
          if (title.isEmpty) return null;

          final artist = (li.querySelector('strong') ??
                      li.querySelector('.item-details-main strong') ??
                      li.querySelector('.detail-author'))
                  ?.text
                  .trim() ??
              '';

          final genreEl = li.querySelector('.detail-description') ??
              li.querySelector('.genre') ??
              li.querySelector('.item-details-secondary');
          final genre = genreEl?.text.trim() ?? '';

          final durationStr = playEl?.attributes['data-audio-duration'] ??
              li.attributes['data-audio-duration'] ??
              '0';
          final duration = int.tryParse(durationStr) ?? 0;

          final audioTypeStr = playEl?.attributes['data-audio-type'] ??
              li.attributes['data-audio-type'] ??
              '3';
          final audioType = int.tryParse(audioTypeStr) ?? 3;

          // Иконка из aicon CDN
          final numId = int.tryParse(id);
          final iconUrl = numId != null
              ? 'https://aicon.ngfiles.com/${numId ~/ 1000}/${id}_raw.png'
              : li.querySelector('img')?.attributes['src'] ?? '';

          return Track(
            id: id,
            title: title,
            artist: artist,
            genre: genre,
            iconUrl: iconUrl,
            duration: duration,
            audioType: audioType,
          );
        })
        .whereType<Track>()
        .toList();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<Document> _connect(String url) async {
    final response =
        await http.get(Uri.parse(url), headers: _headers).timeout(
      const Duration(seconds: 20),
    );
    return html_parser.parse(response.body);
  }

  String _slugify(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s\-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
