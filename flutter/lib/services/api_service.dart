import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_record_model.dart';
import '../utils/constants.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Get current Firebase ID token
  static Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return await user.getIdToken() ?? '';
  }

  static Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ── Damage Analysis ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> analyzeDamage({
    required File imageFile,
    required String vehicleId,
    required String language,
  }) async {
    final opts = await _authOptions();
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'damage.jpg',
      ),
      'vehicle_id': vehicleId,
      'language': language,
    });
    final response = await _dio.post(
      AppConstants.analyzeEndpoint,
      data: formData,
      options: opts.copyWith(
        headers: {
          ...(opts.headers ?? {}),
          'Content-Type': 'multipart/form-data'
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Voice Assistant ──────────────────────────────────────────────────────
  static Future<String> askAssistant({
    required String question,
    String? vehicleId,
    required String language,
  }) async {
    final opts = await _authOptions();
    final response = await _dio.post(
      AppConstants.assistantEndpoint,
      data: {
        'question': question,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        'language': language,
      },
      options: opts,
    );
    return (response.data as Map<String, dynamic>)['answer'] as String;
  }

  // ── Fleet Summary ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFleetSummary() async {
    final opts = await _authOptions();
    final response = await _dio.get(AppConstants.fleetSummary, options: opts);
    return response.data as Map<String, dynamic>;
  }

  // ── Service Record ───────────────────────────────────────────────────────
  static Future<String> addServiceRecord(
      ServiceRecord record, String vehicleId) async {
    final opts = await _authOptions();
    final response = await _dio.post(
      '${AppConstants.serviceEndpoint}/$vehicleId/service',
      data: record.toMap(),
      options: opts,
    );
    return (response.data as Map<String, dynamic>)['record_id'] as String;
  }
}
