import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/services/camera_service.dart';

/// Client Service to communicate Flutter app with NodeJS Express Gemini Backend
class BackendApiService {
  static final BackendApiService instance = BackendApiService._init();

  // Android Emulator uses 10.0.2.2 to access host machine localhost
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000/api/v1';

  String _baseUrl = _defaultBaseUrl;

  BackendApiService._init();

  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl;
  }

  /// Check NodeJS backend status & Gemini configuration
  Future<bool> checkBackendHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'OK';
      }
    } catch (e) {
      debugPrint('BackendApiService: Health check failed ($e)');
    }
    return false;
  }

  /// Send image to NodeJS backend (/api/v1/waste/analyze) for Gemini AI Vision analysis
  Future<AiWasteScanResult> analyzeWasteImageWithBackend({
    File? imageFile,
    String? categoryFilter,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/waste/analyze');
      final request = http.MultipartRequest('POST', uri);

      if (categoryFilter != null) {
        request.fields['categoryFilter'] = categoryFilter;
      }

      if (imageFile != null && await imageFile.exists()) {
        final multipartFile = await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 15),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          return _mapJsonToAiWasteScanResult(data, imageFile);
        }
      }
    } catch (e) {
      debugPrint('BackendApiService: Error calling NodeJS backend ($e)');
    }

    // Fallback to local AI calculation if backend is unreachable or offline
    return CameraService.instance.analyzeWasteImage(
      imageFile: imageFile,
      categoryFilter: categoryFilter,
    );
  }

  /// Ask question to Gemini AI Chatbot via NodeJS backend (/api/v1/ai/chat)
  Future<String> chatWithAiAssistant(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data']['reply'] ?? 'Terima kasih atas pertanyaan Anda.';
        }
      }
    } catch (e) {
      debugPrint('BackendApiService: Chat AI error ($e)');
    }
    return 'Maaf, backend AI sedang offline. Mohon pastikan server NodeJS berjalan di localhost:3000.';
  }

  /// Helper to convert API JSON into Flutter AiWasteScanResult
  AiWasteScanResult _mapJsonToAiWasteScanResult(
    Map<String, dynamic> data,
    File? imageFile,
  ) {
    return AiWasteScanResult(
      wasteItem: _mapJsonToWasteItem(data),
      confidenceScore: (data['confidenceScore'] ?? 0.95).toDouble(),
      estimatedWeightKg: (data['estimatedWeightKg'] ?? 2.5).toDouble(),
      estimatedReward: (data['estimatedReward'] ?? 25000.0).toDouble(),
      estimatedEcoPoints: (data['ecoPoints'] ?? 50).toInt(),
      materialDetected: data['materialDetected'] ?? 'Sampah Daur Ulang',
      recyclingAdvice: data['recyclingAdvice'] ?? 'Siap didaur ulang.',
      tags: List<String>.from(data['tags'] ?? ['#Recyclable']),
      capturedFile: imageFile,
      scannedAt: DateTime.now(),
    );
  }

  WasteItemModel _mapJsonToWasteItem(Map<String, dynamic> data) {
    final name = data['itemName'] ?? 'Sampah Daur Ulang';
    final type = data['category'] ?? 'Non-Organik';
    final isOrganic = type.toString().toLowerCase() == 'organik';

    return WasteItemModel(
      name: name,
      type: type,
      sampleItem: data['materialDetected'] ?? name,
      ratePerKg: (data['ratePerKg'] ?? 10000.0).toDouble(),
      ecoPoints: (data['ecoPoints'] ?? 20).toInt(),
      iconName: isOrganic ? 'compost' : 'bottle',
      imageUrl: isOrganic
          ? 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&q=80&w=600'
          : 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80&w=600',
      description: data['recyclingAdvice'] ?? '',
      handlingTip: data['handlingTip'] ?? '',
    );
  }
}
