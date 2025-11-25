// lib/pages/survey/storage/survey_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_models.dart';

class SurveyStorage {
  static const String _keySurveyData = "surveyData";
  static const String _keyIsCompleted = "isSurveyCompleted";

  static Future<void> saveSurvey(SurveyData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySurveyData, jsonEncode(data.toJson()));
  }

  static Future<SurveyData?> loadSurvey() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySurveyData);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw);
      return SurveyData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setSurveyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsCompleted, true);
  }

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsCompleted) ?? false;
  }

  static Future<void> resetSurvey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySurveyData);
    await prefs.remove(_keyIsCompleted);
  }
}
