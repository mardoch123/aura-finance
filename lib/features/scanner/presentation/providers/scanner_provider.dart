import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/scanner_service.dart';
import '../../domain/transaction_draft.dart';

part 'scanner_provider.g.dart';

/// État du scanner
enum ScannerStatus {
  initial,
  initializing,
  ready,
  capturing,
  processing,
  success,
  error,
}

/// État du mode dictée vocale
enum VoiceStatus {
  idle,
  listening,
  processing,
  success,
  error,
}

/// État complet du scanner
class ScannerState {
  final ScannerStatus status;
  final VoiceStatus voiceStatus;
  final TransactionDraft? draft;
  final String? errorMessage;
  final double soundLevel;
  final String voiceTranscript;
  final bool isCameraPermissionGranted;
  final bool isMicrophonePermissionGranted;

  const ScannerState({
    this.status = ScannerStatus.initial,
    this.voiceStatus = VoiceStatus.idle,
    this.draft,
    this.errorMessage,
    this.soundLevel = 0.0,
    this.voiceTranscript = '',
    this.isCameraPermissionGranted = false,
    this.isMicrophonePermissionGranted = false,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    VoiceStatus? voiceStatus,
    TransactionDraft? draft,
    String? errorMessage,
    double? soundLevel,
    String? voiceTranscript,
    bool? isCameraPermissionGranted,
    bool? isMicrophonePermissionGranted,
    bool clearDraft = false,
    bool clearError = false,
  }) {
    return ScannerState(
      status: status ?? this.status,
      voiceStatus: voiceStatus ?? this.voiceStatus,
      draft: clearDraft ? null : (draft ?? this.draft),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      soundLevel: soundLevel ?? this.soundLevel,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      isCameraPermissionGranted: isCameraPermissionGranted ?? this.isCameraPermissionGranted,
      isMicrophonePermissionGranted: isMicrophonePermissionGranted ?? this.isMicrophonePermissionGranted,
    );
  }

  bool get isLoading => 
      status == ScannerStatus.processing || 
      status == ScannerStatus.capturing ||
      voiceStatus == VoiceStatus.processing;
      
  bool get isListening => voiceStatus == VoiceStatus.listening;
  bool get hasDraft => draft != null && draft!.isValid;
  bool get hasError => errorMessage != null || draft?.error != null;
}

/// Provider pour le scanner
@riverpod
class Scanner extends _$Scanner {
  @override
  ScannerState build() {
    return const ScannerState();
  }

  /// Initialise la caméra
  Future<void> initializeCamera() async {
    state = state.copyWith(status: ScannerStatus.initializing);
    
    final success = await ScannerService.instance.initializeCamera();
    
    if (success) {
      state = state.copyWith(
        status: ScannerStatus.ready,
        isCameraPermissionGranted: true,
      );
    } else {
      state = state.copyWith(
        status: ScannerStatus.error,
        errorMessage: 'Permission caméra refusée',
        isCameraPermissionGranted: false,
      );
    }
  }

  /// Capture une photo et la traite
  Future<void> capture() async {
    if (state.status != ScannerStatus.ready) return;
    
    state = state.copyWith(status: ScannerStatus.capturing, clearError: true);
    
    try {
      final draft = await ScannerService.instance.captureAndProcess();
      
      if (draft != null) {
        state = state.copyWith(
          status: ScannerStatus.success,
          draft: draft,
        );
      } else {
        state = state.copyWith(
          status: ScannerStatus.error,
          errorMessage: 'Aucun document détecté',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ScannerStatus.error,
        errorMessage: 'Erreur lors de la capture: $e',
      );
    }
  }

  /// Sélectionne une image depuis la galerie
  Future<void> pickFromGallery() async {
    state = state.copyWith(status: ScannerStatus.processing, clearError: true);
    
    try {
      final draft = await ScannerService.instance.pickFromGallery();
      
      if (draft != null) {
        state = state.copyWith(
          status: ScannerStatus.success,
          draft: draft,
        );
      } else {
        state = state.copyWith(status: ScannerStatus.ready);
      }
    } catch (e) {
      state = state.copyWith(
        status: ScannerStatus.error,
        errorMessage: 'Erreur lors de la sélection: $e',
      );
    }
  }

  /// Initialise la reconnaissance vocale
  Future<void> initializeVoice() async {
    final available = await ScannerService.instance.initializeVoice();
    state = state.copyWith(isMicrophonePermissionGranted: available);
  }

  /// Démarre la dictée vocale
  Future<void> startVoiceRecording() async {
    if (!state.isMicrophonePermissionGranted) {
      await initializeVoice();
    }
    
    if (!state.isMicrophonePermissionGranted) {
      state = state.copyWith(
        voiceStatus: VoiceStatus.error,
        errorMessage: 'Permission micro refusée',
      );
      return;
    }
    
    state = state.copyWith(
      voiceStatus: VoiceStatus.listening,
      voiceTranscript: '',
      clearError: true,
    );
    
    await ScannerService.instance.startListening(
      onResult: (transcript) {
        state = state.copyWith(voiceTranscript: transcript);
      },
      onSoundLevel: (level) {
        state = state.copyWith(soundLevel: level);
      },
    );
  }

  /// Arrête la dictée vocale et traite le résultat
  Future<void> stopVoiceRecording() async {
    await ScannerService.instance.stopListening();
    
    if (state.voiceTranscript.isEmpty) {
      state = state.copyWith(voiceStatus: VoiceStatus.idle);
      return;
    }
    
    state = state.copyWith(voiceStatus: VoiceStatus.processing);
    
    try {
      final draft = await ScannerService.instance.processVoiceTranscript(
        state.voiceTranscript,
      );
      
      state = state.copyWith(
        voiceStatus: VoiceStatus.success,
        draft: draft,
        status: ScannerStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        voiceStatus: VoiceStatus.error,
        errorMessage: 'Erreur lors de l\'analyse vocale: $e',
      );
    }
  }

  /// Annule la dictée vocale
  Future<void> cancelVoiceRecording() async {
    await ScannerService.instance.stopListening();
    state = state.copyWith(
      voiceStatus: VoiceStatus.idle,
      voiceTranscript: '',
    );
  }

  /// Réinitialise le brouillon
  void clearDraft() {
    state = state.copyWith(
      clearDraft: true,
      status: ScannerStatus.ready,
      voiceStatus: VoiceStatus.idle,
      voiceTranscript: '',
    );
  }

  /// Met à jour le brouillon
  void updateDraft(TransactionDraft draft) {
    state = state.copyWith(draft: draft);
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Libère les ressources
  Future<void> dispose() async {
    await ScannerService.instance.disposeCamera();
  }
}

/// Provider pour accéder au service scanner
final scannerServiceProvider = Provider<ScannerService>((ref) {
  return ScannerService.instance;
});

/// Provider pour le contrôleur de caméra
final cameraControllerProvider = Provider((ref) {
  return ScannerService.instance.cameraController;
});
