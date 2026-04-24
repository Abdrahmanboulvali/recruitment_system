import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/offre.dart';
import '../api_config.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async => await _storage.read(key: 'access');

  // --- دالة تسجيل الدخول ---
  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/token/"),
        body: {"username": username, "password": password},
      );
      if (response.statusCode == 200) {
        String token = json.decode(response.body)['access'];
        await _storage.write(key: 'access', value: token);
        return token;
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  // --- دالة جلب العروض ---
  Future<List<Offre>> getOffres({String? category}) async {
    String url = "${ApiConfig.baseUrl}/offres/";
    if (category != null && category != "Tous") {
      url += "?category=$category";
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Offre.fromJson(item)).toList();
      }
    } catch (e) {
      print("Erreur Offres: $e");
    }
    return [];
  }

  // --- دالة الإحصائيات (معدلة لطباعة البيانات للتأكد) ---
  Future<Map<String, dynamic>> getCompanyStats() async {
    String? token = await getToken();
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/stats/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      print("Stats Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        // هذه الطباعة ضرورية جداً لك الآن لنعرف لماذا تظهر أصفار
        print("DEBUG STATS DATA: $data");
        return data;
      } else {
        print("Stats Error Body: ${response.body}");
      }
    } catch (e) {
      print("Stats Error: $e");
    }
    return {};
  }

  // --- دالة التقديم (postuler) ---
  Future<bool> postuler(int offreId, Uint8List fileBytes, String fileName, String token) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("${ApiConfig.baseUrl}/candidatures/"));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['offre'] = offreId.toString();

      request.files.add(http.MultipartFile.fromBytes(
        'cv',
        fileBytes,
        filename: fileName
      ));

      var response = await request.send();
      print("Postuler Status: ${response.statusCode}");
      return response.statusCode == 201;
    } catch (e) {
      print("Postuler Error: $e");
      return false;
    }
  }
}