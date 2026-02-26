import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../core/haptics/haptic_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/ai_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../domain/transaction_draft.dart';

/// Service de scan pour Aura Finance
/// Gère la caméra, la compression d'images, l'upload et l'analyse IA
class ScannerService {
  ScannerService._();
  
  static final ScannerService _instance = ScannerService._();
  static ScannerService get instance => _instance;
  
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();
  final _speechToText = SpeechToText();
  
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isListening = false;
  
  // ═══════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════
  
  /// Initialise la caméra
  Future<bool> initializeCamera() async {
    try {
      // Vérifier la permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return false;
      }
      
      // Obtenir les caméras disponibles
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;
      
      // Sélectionner la caméra arrière
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      // Créer le contrôleur
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Camera initialization error: $e');
      return false;
    }
  }
  
  /// Libère les ressources de la caméra
  Future<void> disposeCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
  }
  
  /// Vérifie si la caméra est initialisée
  bool get isInitialized => _isInitialized;
  
  /// Contrôleur de caméra
  CameraController? get cameraController => _cameraController;
  
  // ═══════════════════════════════════════════════════════════
  // CAPTURE & TRAITEMENT
  // ═══════════════════════════════════════════════════════════
  
  /// Capture une photo et la traite
  Future<TransactionDraft?> captureAndProcess() async {
    if (!_isInitialized || _cameraController == null) {
      throw Exception('Camera not initialized');
    }
    
    try {
      // Feedback haptique
      HapticService.scanStarted();
      
      // Capture
      final XFile photo = await _cameraController!.takePicture();
      
      // Traiter l'image
      return await _processImageFile(photo.path);
    } catch (e) {
      HapticService.scanFailed();
      throw Exception('Capture failed: $e');
    }
  }
  
  /// Sélectionne une image depuis la galerie
  Future<TransactionDraft?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      
      if (image == null) return null;
      
      HapticService.lightTap();
      return await _processImageFile(image.path);
    } catch (e) {
      HapticService.error();
      throw Exception('Gallery pick failed: $e');
    }
  }
  
  /// Traite un fichier image
  Future<TransactionDraft> _processImageFile(String path) async {
    // Lire le fichier
    final bytes = await File(path).readAsBytes();
    return await processImageBytes(bytes);
  }
  
  /// Traite des bytes d'image (compression + upload + analyse)
  Future<TransactionDraft> processImageBytes(Uint8List bytes) async {
    try {
      // 1. Compression
      final compressedBytes = await _compressImage(bytes);
      
      // 2. Upload vers Supabase Storage
      final imageUrl = await _uploadImage(compressedBytes);
      
      // 3. Analyse IA
      final result = await AIService.instance.scanReceipt(compressedBytes);
      
      // 4. Retourner le brouillon
      return TransactionDraft(
        amount: result.amount,
        merchant: result.merchant,
        category: result.category ?? 'other',
        description: result.description,
        date: result.date ?? DateTime.now(),
        currency: 'EUR',
        confidence: result.confidence,
        scanImageUrl: imageUrl,
        source: 'scan',
      );
    } catch (e) {
      HapticService.error();
      return TransactionDraft(
        amount: 0,
        error: 'Analyse échouée: $e',
        source: 'scan',
      );
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // COMPRESSION
  // ═══════════════════════════════════════════════════════════
  
  /// Compresse une image à max 800x800px, qualité 85%
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      // En cas d'erreur, retourner l'original
      return bytes;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // UPLOAD
  // ═══════════════════════════════════════════════════════════
  
  /// Upload une image vers Supabase Storage
  Future<String> _uploadImage(Uint8List bytes) async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final fileName = '${_uuid.v4()}.jpg';
    final path = '$userId/$fileName';
    
    await SupabaseService.instance.storage
        .from(ApiEndpoints.storageReceipts)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
    
    // Obtenir l'URL publique
    final url = SupabaseService.instance.storage
        .from(ApiEndpoints.storageReceipts)
        .getPublicUrl(path);
    
    return url;
  }
  
  // ═══════════════════════════════════════════════════════════
  // DICTÉE VOCALE
  // ═══════════════════════════════════════════════════════════
  
  /// Initialise la reconnaissance vocale
  Future<bool> initializeVoice() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }
    
    return await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
  }
  
  /// Vérifie si la reconnaissance vocale est disponible
  Future<bool> get isVoiceAvailable => _speechToText.initialize();
  
  /// Démarre l'écoute
  Future<void> startListening({
    required Function(String) onResult,
    required Function(double) onSoundLevel,
  }) async {
    if (_isListening) return;
    
    _isListening = true;
    HapticService.lightTap();
    
    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
      },
      onSoundLevelChange: onSoundLevel,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }
  
  /// Arrête l'écoute
  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }
  
  /// Vérifie si l'écoute est active
  bool get isListening => _isListening;
  
  /// Traite une transcription vocale
  Future<TransactionDraft> processVoiceTranscript(String transcript) async {
    try {
      HapticService.mediumTap();
      
      final result = await AIService.instance.processVoice(transcript);
      
      return TransactionDraft(
        amount: result.amount,
        merchant: result.merchant,
        category: result.category ?? 'other',
        description: result.description ?? transcript,
        date: DateTime.now(),
        currency: 'EUR',
        confidence: result.confidence,
        source: 'voice',
      );
    } catch (e) {
      HapticService.error();
      return TransactionDraft(
        amount: 0,
        error: 'Analyse vocale échouée: $e',
        source: 'voice',
      );
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════
  
  /// Supprime une image du storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Extraire le chemin relatif (userId/filename.jpg)
      if (pathSegments.length >= 2) {
        final path = pathSegments.sublist(pathSegments.length - 2).join('/');
        await SupabaseService.instance.storage
            .from(ApiEndpoints.storageReceipts)
            .remove([path]);
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
