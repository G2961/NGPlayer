import 'providers/hub_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/player_provider.dart';
import 'theme/ng_theme.dart';
import 'ui/screens/hub_screen.dart';
import 'ui/screens/player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Статус-бар прозрачный, иконки светлые
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Инициализируем audio_service один раз при старте
  final audioHandler = await AudioService.init(
    builder: () => NgAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.g2961.ngmusic.audio',
      androidNotificationChannelName: 'NG Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Подключаем реальный handler к провайдеру
        audioHandlerProvider.overrideWithValue(audioHandler as NgAudioHandler),
      ],
      child: const NgMusicApp(),
    ),
  );
}

class NgMusicApp extends StatelessWidget {
  const NgMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NG Music',
      debugShowCheckedModeBanner: false,
      theme: ngTheme,
      home: const NgMusicRoot(),
    );
  }
}

class NgMusicRoot extends ConsumerStatefulWidget {
  const NgMusicRoot({super.key});

  @override
  ConsumerState<NgMusicRoot> createState() => _NgMusicRootState();
}

class _NgMusicRootState extends ConsumerState<NgMusicRoot> {
  bool _showPlayer = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showPlayer,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showPlayer) {
          setState(() => _showPlayer = false);
        }
      },
      child: _showPlayer
          ? PlayerScreen(onBack: () => setState(() => _showPlayer = false))
          : HubScreen(
              onTrackClick: (track) {
                ref.read(hubProvider.notifier).playTrack(track);
                setState(() => _showPlayer = true);
              },
              onMiniPlayerClick: () => setState(() => _showPlayer = true),
            ),
    );
  }
}
