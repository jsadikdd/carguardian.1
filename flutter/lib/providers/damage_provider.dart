import 'dart:io';
import 'package:flutter/material.dart';
import '../models/damage_report_model.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';

enum AnalysisStatus { idle, uploading, analyzing, done, error }

class DamageProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  AnalysisStatus _status = AnalysisStatus.idle;
  DamageReport?  _latestReport;
  String?        _error;
  String         _assistantAnswer = '';
  bool           _assistantLoading = false;

  AnalysisStatus get status           => _status;
  DamageReport?  get latestReport     => _latestReport;
  String?        get error            => _error;
  String         get assistantAnswer  => _assistantAnswer;
  bool           get assistantLoading => _assistantLoading;

  Stream<List<DamageReport>> streamReports(String vehicleId) =>
      _firestoreService.streamDamageReports(vehicleId);

  Future<void> analyzeImage({
    required File imageFile,
    required String vehicleId,
    required String language,
  }) async {
    _status = AnalysisStatus.uploading;
    _error  = null;
    notifyListeners();

    try {
      _status = AnalysisStatus.analyzing;
      notifyListeners();

      final result = await ApiService.analyzeDamage(
        imageFile: imageFile,
        vehicleId: vehicleId,
        language: language,
      );

      _latestReport = DamageReport.fromMap({
        'report_id': result['report_id'] ?? '',
        'vehicle_id': vehicleId,
        'image_url': result['image_url'] ?? '',
        'analysis': result['analysis'] ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
      _status = AnalysisStatus.done;
    } catch (e) {
      _error  = e.toString();
      _status = AnalysisStatus.error;
    }
    notifyListeners();
  }

  Future<void> askAssistant({
    required String question,
    String? vehicleId,
    required String language,
  }) async {
    _assistantLoading  = true;
    _assistantAnswer   = '';
    notifyListeners();
    try {
      _assistantAnswer = await ApiService.askAssistant(
        question: question,
        vehicleId: vehicleId,
        language: language,
      );
    } catch (e) {
      _assistantAnswer = 'Sorry, I could not process your request.';
    } finally {
      _assistantLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _status       = AnalysisStatus.idle;
    _latestReport = null;
    _error        = null;
    notifyListeners();
  }
}
