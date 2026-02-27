import 'package:audioplayers/audioplayers.dart';

/// Service de sound design subtil pour l'expérience premium
/// Avec fallback automatique vers des sons en ligne
class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  
  // Volumes subtils
  static const double _subtleVolume = 0.3;
  static const double _mediumVolume = 0.5;
  static const double _notificationVolume = 0.4;

  // URLs de fallback pour les sons en ligne
  static const Map<String, String> _onlineSoundUrls = {
    'tap': 'https://www.soundjay.com/buttons/sounds/button-09.mp3',
    'success': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3',
    'error': 'https://www.soundjay.com/misc/sounds/bell-ringing-01.mp3',
    'notification': 'https://www.soundjay.com/misc/sounds/bell-ringing-04.mp3',
    'felix_happy': 'https://www.soundjay.com/misc/sounds/bell-ringing-03.mp3',
    'felix_sad': 'https://www.soundjay.com/misc/sounds/bell-ringing-01.mp3',
    'felix_curious': 'https://www.soundjay.com/misc/sounds/bell-ringing-02.mp3',
    'scan_start': 'https://www.soundjay.com/misc/sounds/camera-shutter-click-01.mp3',
    'scan_success': 'https://www.soundjay.com/misc/sounds/magic-spell-01.mp3',
    'scan_error': 'https://www.soundjay.com/misc/sounds/bell-ringing-01.mp3',
    'streak': 'https://www.soundjay.com/misc/sounds/trophy-01.mp3',
    'achievement': 'https://www.soundjay.com/misc/sounds/trophy-02.mp3',
    'page_transition': 'https://www.soundjay.com/misc/sounds/woosh-01.mp3',
    'menu_open': 'https://www.soundjay.com/misc/sounds/woosh-02.mp3',
  };

  /// Sons de l'interface
  static Future<void> buttonTap() async {
    await _playSoundWithFallback('sounds/tap.mp3', 'tap', volume: _subtleVolume);
  }

  static Future<void> success() async {
    await _playSoundWithFallback('sounds/success.mp3', 'success', volume: _mediumVolume);
  }

  static Future<void> error() async {
    await _playSoundWithFallback('sounds/error.mp3', 'error', volume: _subtleVolume);
  }

  static Future<void> notification() async {
    await _playSoundWithFallback('sounds/notification.mp3', 'notification', volume: _notificationVolume);
  }

  /// Sons de Felix
  static Future<void> felixHappy() async {
    await _playSoundWithFallback('sounds/felix_happy.mp3', 'felix_happy', volume: _subtleVolume);
  }

  static Future<void> felixSad() async {
    await _playSoundWithFallback('sounds/felix_sad.mp3', 'felix_sad', volume: _subtleVolume);
  }

  static Future<void> felixCurious() async {
    await _playSoundWithFallback('sounds/felix_curious.mp3', 'felix_curious', volume: _subtleVolume);
  }

  /// Sons de scan
  static Future<void> scanStart() async {
    await _playSoundWithFallback('sounds/scan_start.mp3', 'scan_start', volume: _subtleVolume);
  }

  static Future<void> scanSuccess() async {
    await _playSoundWithFallback('sounds/scan_success.mp3', 'scan_success', volume: _mediumVolume);
  }

  static Future<void> scanError() async {
    await _playSoundWithFallback('sounds/scan_error.mp3', 'scan_error', volume: _subtleVolume);
  }

  /// Sons de récompense
  static Future<void> streak() async {
    await _playSoundWithFallback('sounds/streak.mp3', 'streak', volume: _mediumVolume);
  }

  static Future<void> achievement() async {
    await _playSoundWithFallback('sounds/achievement.mp3', 'achievement', volume: _mediumVolume);
  }

  /// Sons de navigation
  static Future<void> pageTransition() async {
    await _playSoundWithFallback('sounds/page_transition.mp3', 'page_transition', volume: 0.2);
  }

  static Future<void> menuOpen() async {
    await _playSoundWithFallback('sounds/menu_open.mp3', 'menu_open', volume: _subtleVolume);
  }

  /// Méthode principale avec fallback automatique
  static Future<void> _playSoundWithFallback(
    String localPath, 
    String onlineKey, 
    {double volume = 1.0}
  ) async {
    try {
      // Essayer le son local d'abord
      await _player.play(AssetSource(localPath));
      await _player.setVolume(volume);
    } catch (localError) {
      // Si le son local échoue, essayer le son en ligne
      try {
        final onlineUrl = _onlineSoundUrls[onlineKey];
        if (onlineUrl != null) {
          await _player.play(UrlSource(onlineUrl));
          await _player.setVolume(volume);
        }
      } catch (onlineError) {
        // Silencieux en cas d'erreur - ne pas casser l'expérience
        // print('Sound fallback failed: $onlineError');
      }
    }
  }

  /// Méthode privée pour jouer un son (ancienne méthode)
  static Future<void> _playSound(String path, {double volume = 1.0}) async {
    try {
      await _player.play(AssetSource(path));
      await _player.setVolume(volume);
    } catch (e) {
      // Silencieux en cas d'erreur - ne pas casser l'expérience
      // print('Sound error: $e');
    }
  }

  /// Arrêter tous les sons
  static Future<void> stopAll() async {
    await _player.stop();
  }

  /// Libérer les ressources
  static Future<void> dispose() async {
    await _player.dispose();
  }
}