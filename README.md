# NG Music — Flutter

Android-клиент для Newgrounds Audio Portal. Порт с Kotlin/Compose на Flutter + Riverpod.

## Структура

```
lib/
  main.dart                        # точка входа, инициализация audio_service
  theme/ng_theme.dart              # цвета и ThemeData
  data/
    models/track.dart              # модель трека (immutable)
    repositories/ng_repository.dart # HTTP + HTML-парсинг (аналог Jsoup → html)
  providers/
    hub_provider.dart              # треки, пагинация, поиск, mp3-кэш
    player_provider.dart           # аудио-плеер (just_audio + audio_service)
  ui/
    screens/
      hub_screen.dart              # список треков
      player_screen.dart           # полноэкранный плеер
    widgets/
      track_item.dart
      mini_player.dart
      ng_top_bar.dart
```

## Зависимости

| Пакет | Зачем |
|---|---|
| `flutter_riverpod` | стейт-менеджмент |
| `just_audio` | воспроизведение mp3 |
| `audio_service` | фоновое воспроизведение + уведомление |
| `http` | HTTP-запросы |
| `html` | парсинг HTML (аналог Jsoup) |
| `cached_network_image` | загрузка обложек |
| `url_launcher` | открыть страницу трека / скачать |

## Запуск

```bash
flutter pub get
flutter run
```

## Что исправлено по сравнению с оригиналом

1. **Race condition в loadMore** — offset инкрементируется только после успешной загрузки, добавлена дедупликация по id.
2. **Mutable Track.mp3Url** — убран `var`, mp3-кэш хранится в `HubNotifier`.
3. **TODO «открыть в браузере»** — реализовано через `url_launcher`.
