import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';

class MesCandidaturesScreen extends StatefulWidget {
  const MesCandidaturesScreen({super.key});

  @override
  State<MesCandidaturesScreen> createState() => _MesCandidaturesScreenState();
}

class _MesCandidaturesScreenState extends State<MesCandidaturesScreen> {
  final _storage = const FlutterSecureStorage();
  List candidatures = [];
  Map<int, String> offresMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyData();
  }

  Future<void> _fetchMyData() async {
    try {
      String? token = await _storage.read(key: 'access');
      var headers = {'Authorization': 'Bearer $token'};

      // 1. جلب العروض لبناء الخريطة (Map) مثل الويب
      final offresRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/offres/'), headers: headers);
      if (offresRes.statusCode == 200) {
        List data = json.decode(utf8.decode(offresRes.bodyBytes));
        for (var o in data) {
          offresMap[o['id']] = o['titre'];
        }
      }

      // 2. جلب معلومات المستخدم والبروفايل للتصفية
      final userRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-info/'), headers: headers);
      final candidatesRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidats/'), headers: headers);

      if (userRes.statusCode == 200 && candidatesRes.statusCode == 200) {
        var userData = json.decode(utf8.decode(userRes.bodyBytes));
        List candidates = json.decode(utf8.decode(candidatesRes.bodyBytes));

        var myProfile = candidates.firstWhere(
          (c) => c['user'] == userData['id'],
          orElse: () => null,
        );

        if (myProfile != null) {
          // 3. جلب الترشيحات وتصفيتها
          final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidatures/'), headers: headers);
          List allCans = json.decode(utf8.decode(res.bodyBytes));

          setState(() {
            candidatures = allCans.where((can) => can['candidat'] == myProfile['id']).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAnnuler(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment annuler cette candidature ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        String? token = await _storage.read(key: 'access');
        final res = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/candidatures/$id/'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (res.statusCode == 204 || res.statusCode == 200) {
          _fetchMyData();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de l'annulation")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF10B981)),
              const SizedBox(height: 20),
              Text("Analyse de vos candidatures en cours...",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mes Candidatures"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header المماثل للويب
            Container(
              padding: const EdgeInsets.only(left: 15),
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF10B981), width: 5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mes Candidatures", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor)),
                  Text("Suivez l'état d'avancement de vos demandes d'emploi",
                      style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            if (candidatures.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Text("Vous n'avez postulé à aucune offre pour le moment.",
                      textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.5))),
                ),
              )
            else
              ...candidatures.map((can) => _buildCandidatureCard(can, textColor, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatureCard(var can, Color textColor, bool isDark) {
    String status = (can['statut'] ?? 'En attente').toString();
    String title = offresMap[can['offre']] ?? "Offre #${can['offre']}";

    // منطق الألوان مطابق للويب تماماً
    Color statusBg;
    Color statusText;
    if (status.toLowerCase().contains('accept')) {
      statusBg = const Color(0xFF10B981).withOpacity(0.15);
      statusText = const Color(0xFF10B981);
    } else if (status.toLowerCase().contains('refus')) {
      statusBg = const Color(0xFFEF4444).withOpacity(0.15);
      statusText = const Color(0xFFEF4444);
    } else {
      statusBg = const Color(0xFFF59E0B).withOpacity(0.15);
      statusText = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ApiConfig.kBgCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                child: Text(status, style: TextStyle(color: statusText, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Postulé le: ${can['date_postulation'].toString().split('T')[0]}",
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
          ),
          const Divider(height: 30, thickness: 0.5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _handleAnnuler(can['id']),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Annuler", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }
}