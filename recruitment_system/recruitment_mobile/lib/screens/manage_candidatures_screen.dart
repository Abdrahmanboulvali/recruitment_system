import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_config.dart';

class ManageCandidaturesScreen extends StatefulWidget {
  const ManageCandidaturesScreen({super.key});

  @override
  State<ManageCandidaturesScreen> createState() => _ManageCandidaturesScreenState();
}

class _ManageCandidaturesScreenState extends State<ManageCandidaturesScreen> {
  final _storage = const FlutterSecureStorage();
  List candidatures = [];
  Map<int, dynamic> offresData = {};
  Map<int, String> candidatsMap = {};
  bool loading = true;

  // متغيرات الفلترة والبحث
  String searchTerm = "";
  double minScore = 0.0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String cleanComment(String? text) {
    if (text == null || text.isEmpty) return "Aucune analyse disponible pour le moment.";
    return text.replaceAll(RegExp(r'O\*NET', caseSensitive: false), "Système")
               .replaceAll(RegExp(r'Matching', caseSensitive: false), "Analyse");
  }

  String getFullCvUrl(String? cvPath) {
    if (cvPath == null) return "";
    if (cvPath.startsWith('http')) return cvPath;
    return "${ApiConfig.baseUrl}$cvPath";
  }

  Future<void> fetchData() async {
    try {
      String? token = await _storage.read(key: 'access');
      var headers = {'Authorization': 'Bearer $token'};

      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/offres/'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidats/'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidatures/'), headers: headers),
      ]);

      if (results.every((res) => res.statusCode == 200)) {
        var offresJson = json.decode(utf8.decode(results[0].bodyBytes));
        offresData = {for (var o in offresJson) o['id']: o};

        var candidatsJson = json.decode(utf8.decode(results[1].bodyBytes));
        candidatsMap = {for (var c in candidatsJson) c['id']: "${c['nom']} ${c['prenom']}"};

        setState(() {
          candidatures = json.decode(utf8.decode(results[2].bodyBytes));
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> handleUpdateStatus(int id, String newStatus) async {
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/candidatures/$id/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'statut': newStatus}),
      );

      if (response.statusCode == 200) {
        fetchData();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  // منطق الفلترة المتقدم المتطابق مع الويب
  List get filteredCandidatures {
    return candidatures.where((can) {
      final name = (candidatsMap[can['candidat']] ?? "").toLowerCase();
      final job = (offresData[can['offre']]?['titre'] ?? "").toLowerCase();
      final scoreStr = can['score'].toString();
      final search = searchTerm.toLowerCase();

      final matchesSearch = name.contains(search) ||
                           job.contains(search) ||
                           scoreStr.contains(search);

      final matchesScore = (can['score'] as num) >= minScore;

      return matchesSearch && matchesScore;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // تقسيم البيانات حسب الحالة للعرض المنظم
    final pending = filteredCandidatures.where((c) => c['statut'].toString().toLowerCase().contains('attente')).toList();
    final accepted = filteredCandidatures.where((c) => c['statut'].toString().toLowerCase().contains('accepté')).toList();
    final rejected = filteredCandidatures.where((c) => c['statut'].toString().toLowerCase().contains('refusé')).toList();

    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      appBar: AppBar(
        title: const Text("Gestion Candidatures", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchAndFilterBox(), // خانة البحث الذكية
            _buildSection("Candidatures En Attente", pending, Colors.orange),
            _buildSection("Candidatures Acceptées", accepted, Colors.green),
            _buildSection("Candidatures Refusées", rejected, Colors.red),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // تصميم خانة البحث والفلترة كما في الويب
  Widget _buildSearchAndFilterBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("RECHERCHE GLOBALE (Nom, Poste, Score)",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Rechercher partout...",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            ),
            onChanged: (val) => setState(() => searchTerm = val),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SCORE MINIMUM:", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              Text("${minScore.toInt()}%", style: const TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: minScore,
            min: 0,
            max: 100,
            activeColor: ApiConfig.kPrimary,
            inactiveColor: Colors.white10,
            onChanged: (val) => setState(() => minScore = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text("$title (${data.length})",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        ...data.map((can) => _buildCard(can)).toList(),
      ],
    );
  }

  Widget _buildCard(Map can) {
    String name = candidatsMap[can['candidat']] ?? "Inconnu";
    String job = offresData[can['offre']]?['titre'] ?? "Poste Inconnu";
    double score = (can['score'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(job, style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("En attente", style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    color: score > 50 ? Colors.orange : Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text("${score.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => _showDetailsModal(can),
              child: const Text("Visualiser l'analyse"),
            ),
          )
        ],
      ),
    );
  }

  void _showDetailsModal(Map can) {
    String name = candidatsMap[can['candidat']] ?? "";
    String job = offresData[can['offre']]?['titre'] ?? "";
    String cvUrl = getFullCvUrl(can['cv_file']);
    double score = (can['score'] as num).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151921),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(25),
          child: ListView(
            controller: controller,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(job, style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 25),
              const Text("Taux de correspondance", style: TextStyle(color: Colors.grey)),
              Text("${score.toInt()}%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ApiConfig.kPrimary)),
              const Divider(height: 40, color: Colors.white10),

              const Text("Analyse IA du profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text(cleanComment(can['commentaire_ia']),
                style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15)),

              const SizedBox(height: 30),
              // زر فتح الـ CV
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white10),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () async {
                  final url = Uri.parse(cvUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                label: const Text("Voir le CV original", style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(height: 40),
              if (can['statut'].toString().toLowerCase().contains('attente'))
                Row(
                  children: [
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => handleUpdateStatus(can['id'], 'Accepté'),
                      child: const Text("Accepter", style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => handleUpdateStatus(can['id'], 'Refusé'),
                      child: const Text("Refuser", style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                  ],
                )
              else
                _buildStatusBanner(can['statut']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    bool isAcc = status.toLowerCase().contains('accepté');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAcc ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        border: Border.all(color: isAcc ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isAcc ? Icons.check_circle : Icons.cancel, color: isAcc ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 10),
          Text(isAcc ? "Candidature Acceptée" : "Candidature Refusée",
              style: TextStyle(color: isAcc ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}