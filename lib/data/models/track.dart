class Track {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String iconUrl;
  final int duration; // секунды
  final int audioType;
  final String? mp3Url;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.iconUrl,
    required this.duration,
    required this.audioType,
    this.mp3Url,
  });

  /// https://aicon.ngfiles.com/{id/1000}/{id}_raw.png
  String get aIconUrl {
    final numId = int.tryParse(id);
    if (numId == null) return iconUrl;
    final folder = numId ~/ 1000;
    return 'https://aicon.ngfiles.com/$folder/${id}_raw.png';
  }

  /// https://audio.ngfiles.com/{floor(id/1000)*1000}/{id}_  — папка кратна 1000
  String get audioBaseUrl {
    final numId = int.tryParse(id);
    if (numId == null) return '';
    final folder = (numId ~/ 1000) * 1000;
    return 'https://audio.ngfiles.com/$folder/';
  }

  Track copyWith({String? mp3Url}) => Track(
        id: id,
        title: title,
        artist: artist,
        genre: genre,
        iconUrl: iconUrl,
        duration: duration,
        audioType: audioType,
        mp3Url: mp3Url ?? this.mp3Url,
      );

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
