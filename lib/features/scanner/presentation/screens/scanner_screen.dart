import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/animations/pulse_ring.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../domain/transaction_draft.dart';
import '../providers/scanner_provider.dart';
import '../widgets/viewfinder_overlay.dart';
import '../widgets/scan_controls.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/confirmation_modal.dart';

/// Écran de scan immersif
/// Prend tout l'écran comme une vraie caméra
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialiser la caméra au prochain frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerProvider.notifier).initializeCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(scannerProvider.notifier).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = ref.read(cameraControllerProvider);
    
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(scannerProvider.notifier).initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);
    final scannerNotifier = ref.read(scannerProvider.notifier);
    final cameraController = ref.watch(cameraControllerProvider);

    // Afficher le modal de confirmation si on a un brouillon
    if (scannerState.hasDraft && scannerState.status == ScannerStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfirmationModal(scannerState.draft!);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Caméra
          if (cameraController != null &&
              cameraController.value.isInitialized)
            CameraPreview(cameraController)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AuraColors.auraAmber,
                ),
              ),
            ),

          // Overlay du viewfinder
          ShakeAnimation(
            shake: scannerState.hasError,
            child: ViewfinderOverlay(
              isProcessing: scannerState.isLoading,
              hasError: scannerState.hasError,
            ),
          ),

          // Ligne de scan animée
          if (!scannerState.isLoading && !scannerState.hasError)
            const ScanLine(),

          // Pulse ring pendant le traitement
          if (scannerState.isLoading)
            Center(
              child: PulseRing(
                size: 200,
                color: AuraColors.auraAmber,
                child: const SizedBox.shrink(),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScannerTopBar(
              onClose: () {
                HapticService.lightTap();
                context.pop();
              },
              onImport: () {
                scannerNotifier.pickFromGallery();
              },
            ),
          ),

          // Message d'erreur
          if (scannerState.hasError)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: AuraDimensions.spaceM,
              right: AuraDimensions.spaceM,
              child: GlassCard(
                borderRadius: AuraDimensions.radiusL,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AuraColors.auraRed.withOpacity(0.3),
                    AuraColors.auraRed.withOpacity(0.1),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AuraColors.auraRed,
                    ),
                    const SizedBox(width: AuraDimensions.spaceS),
                    Expanded(
                      child: Text(
                        scannerState.errorMessage ??
                            scannerState.draft?.error ??
                            context.l10n.unknownError,
                        style: const TextStyle(
                          color: AuraColors.auraTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AuraColors.auraTextSecondary,
                        size: 20,
                      ),
                      onPressed: scannerNotifier.clearError,
                    ),
                  ],
                ),
              ),
            ),

          // Indicateur de traitement
          if (scannerState.isLoading)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: 0,
              right: 0,
              child: Center(
                child: GlassCard(
                  borderRadius: AuraDimensions.radiusXL,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuraDimensions.spaceL,
                    vertical: AuraDimensions.spaceM,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AuraColors.auraAmber,
                        ),
                      ),
                      const SizedBox(width: AuraDimensions.spaceM),
                      Text(
                        context.l10n.analysisInProgress,
                        style: TextStyle(
                          color: AuraColors.auraTextPrimary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Widget de dictée vocale
          VoiceRecorder(
            isListening: scannerState.isListening,
            transcript: scannerState.voiceTranscript,
            soundLevel: scannerState.soundLevel,
            onStart: () {},
            onStop: scannerNotifier.stopVoiceRecording,
            onCancel: scannerNotifier.cancelVoiceRecording,
          ),

          // Contrôles du bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ScanControls(
              onVoicePressed: () {
                if (scannerState.isListening) {
                  scannerNotifier.stopVoiceRecording();
                } else {
                  scannerNotifier.startVoiceRecording();
                }
              },
              onCapturePressed: scannerNotifier.capture,
              onLastReceiptPressed: () {
                // TODO: Afficher les transactions récentes
                HapticService.lightTap();
              },
              isProcessing: scannerState.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationModal(TransactionDraft draft) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => ConfirmationModal(
        draft: draft,
        onConfirm: () {
          Navigator.of(context).pop();
          _saveTransaction(draft);
        },
        onEdit: () {
          Navigator.of(context).pop();
          _editTransaction(draft);
        },
        onCancel: () {
          Navigator.of(context).pop();
          ref.read(scannerProvider.notifier).clearDraft();
        },
      ),
    );
  }

  void _saveTransaction(TransactionDraft draft) {
    // TODO: Sauvegarder la transaction dans Supabase
    HapticService.success();
    
    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.transactionAdded),
        backgroundColor: AuraColors.auraGreen,
      ),
    );
    
    // Réinitialiser le scanner
    ref.read(scannerProvider.notifier).clearDraft();
  }

  void _editTransaction(TransactionDraft draft) {
    // TODO: Naviguer vers l'écran d'édition
    // context.push('/transactions/edit', extra: draft);
  }
}
