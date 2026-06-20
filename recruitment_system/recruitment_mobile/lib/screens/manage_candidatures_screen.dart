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

  String searchTerm = "";
  double minScore = 0.0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String cleanComment(String? text, String currentLang) {
    if (text == null || text.isEmpty) {
      return currentLang == 'ar'
          ? "لا يوجد تحليل متاح حالياً."
          : (currentLang == 'en' ? "No analysis available at the moment." : "Aucune analyse disponible pour le moment.");
    }
    return text.replaceAll(RegExp(r'O\*NET', caseSensitive: false), currentLang == 'ar' ? "النظام" : (currentLang == 'en' ? "System" : "Système"))
               .replaceAll(RegExp(r'Matching', caseSensitive: false), currentLang == 'ar' ? "التحليل" : (currentLang == 'en' ? "Analysis" : "Analyse"));
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

        if (mounted) {
          setState(() {
            candidatures = json.decode(utf8.decode(results[2].bodyBytes));
            loading = false;
          });
        }
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

  // دالة مساعدة لترجمة حالات الترشح المباشرة من قاعدة البيانات
  String translateStatus(String status, String currentLang) {
    String lower = status.toLowerCase();
    if (lower.contains('attente')) {
      return currentLang == 'ar' ? "قيد الانتظار" : (currentLang == 'en' ? "Pending" : "En attente");
    } else if (lower.contains('accepté') || lower.contains('accepte')) {
      return currentLang == 'ar' ? "مقبول" : (currentLang == 'en' ? "Accepted" : "Accepté");
    } else if (lower.contains('refusé') || lower.contains('refuse')) {
      return currentLang == 'ar' ? "مرفوض" : (currentLang == 'en' ? "Rejected" : "Refusé");
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    if (loading) return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary)));

    final pending = filteredCandidatures.where((c) => c['statut'].toString().toLowerCase().contains('attente')).toList();
    final accepted = filteredCandidatures.where((c) => c['statut'].toString().toLowerCase().contains('accepté')).toList();
    final rejected = filteredCandidatures.where((c) => c['statut'].toString().toLowerCase().contains('refusé')).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          currentLang == 'ar' ? "إدارة الترشيحات" : (currentLang == 'en' ? "Manage Applications" : "Gestion Candidatures"),
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchAndFilterBox(theme, isDark, currentLang),
            _buildSection(currentLang == 'ar' ? "الترشيحات قيد الانتظار" : (currentLang == 'en' ? "Pending Applications" : "Candidatures En Attente"), pending, Colors.orange, isDark, currentLang),
            _buildSection(currentLang == 'ar' ? "الترشيحات المقبولة" : (currentLang == 'en' ? "Accepted Applications" : "Candidatures Acceptées"), accepted, Colors.green, isDark, currentLang),
            _buildSection(currentLang == 'ar' ? "الترشيحات المرفوضة" : (currentLang == 'en' ? "Rejected Applications" : "Candidatures Refusées"), rejected, Colors.red, isDark, currentLang),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBox(ThemeData theme, bool isDark, String currentLang) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentLang == 'ar' ? "بحث شامل (الاسم، الوظيفة، النتيجة)" : (currentLang == 'en' ? "GLOBAL SEARCH (Name, Job, Score)" : "RECHERCHE GLOBALE (Nom, Poste, Score)"),
            style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: currentLang == 'ar' ? "ابحث في كل مكان..." : (currentLang == 'en' ? "Search everywhere..." : "Rechercher partout..."),
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black38),
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            ),
            onChanged: (val) => setState(() => searchTerm = val),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentLang == 'ar' ? "الحد الأدنى للمطابقة:" : (currentLang == 'en' ? "MINIMUM SCORE:" : "SCORE MINIMUM:"),
                style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)
              ),
              Text("${minScore.toInt()}%", style: const TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: minScore,
            min: 0,
            max: 100,
            activeColor: ApiConfig.kPrimary,
            inactiveColor: isDark ? Colors.white10 : Colors.black12,
            onChanged: (val) => setState(() => minScore = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List data, Color color, bool isDark, String currentLang) {
    if (data.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text("$title (${data.length})",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        ...data.map((can) => _buildCard(can, isDark, currentLang)).toList(),
      ],
    );
  }

  Widget _buildCard(Map can, bool isDark, String currentLang) {
    String name = candidatsMap[can['candidat']] ?? (currentLang == 'ar' ? "مجهول" : "Inconnu");
    String job = offresData[can['offre']]?['titre'] ?? (currentLang == 'ar' ? "وظيفة غير معروفة" : "Poste Inconnu");
    double score = (can['score'] as num).toDouble();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 2),
                    Text(job, style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: can['statut'].toString().toLowerCase().contains('attente')
                    ? Colors.orange.withOpacity(0.1)
                    : (can['statut'].toString().toLowerCase().contains('accepté') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(
                  translateStatus(can['statut'], currentLang),
                  style: TextStyle(
                    color: can['statut'].toString().toLowerCase().contains('attente')
                      ? Colors.orange
                      : (can['statut'].toString().toLowerCase().contains('accepté') ? Colors.green : Colors.red),
                    fontSize: 11, fontWeight: FontWeight.bold),
                ),
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
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    color: score > 50 ? Colors.orange : Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text("${score.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                foregroundColor: isDark ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => _showDetailsModal(can, currentLang),
              child: Text(currentLang == 'ar' ? "عرض التحليل" : (currentLang == 'en' ? "View analysis" : "Visualiser l'analyse")),
            ),
          )
        ],
      ),
    );
  }

  void _showDetailsModal(Map can, String currentLang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String name = candidatsMap[can['candidat']] ?? "";
    String job = offresData[can['offre']]?['titre'] ?? "";
    String cvUrl = getFullCvUrl(can['cv_file']);
    double score = (can['score'] as num).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF151921) : Colors.white,
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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              Text(job, style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 25),
              Text(currentLang == 'ar' ? "نسبة المطابقة" : (currentLang == 'en' ? "Match rate" : "Taux de correspondance"), style: const TextStyle(color: Colors.grey)),
              Text("${score.toInt()}%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ApiConfig.kPrimary)),
              Divider(height: 40, color: isDark ? Colors.white10 : Colors.black12),

              Text(
                currentLang == 'ar' ? "تحليل الذكاء الاصطناعي للملف الشخصي" : (currentLang == 'en' ? "AI Analysis of Profile" : "Analyse IA du profil"),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)
              ),
              const SizedBox(height: 12),
              Text(cleanComment(can['commentaire_ia'], currentLang),
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.6, fontSize: 15)),

              const SizedBox(height: 30),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
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
                label: Text(
                  currentLang == 'ar' ? "عرض السيرة الذاتية الأصلية" : (currentLang == 'en' ? "View original CV" : "Voir le CV original"),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87)
                ),
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
                      child: Text(currentLang == 'ar' ? "قبول" : (currentLang == 'en' ? "Accept" : "Accepter"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => handleUpdateStatus(can['id'], 'Refusé'),
                      child: Text(currentLang == 'ar' ? "رفض" : (currentLang == 'en' ? "Reject" : "Refuser"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    )),
                  ],
                )
              else
                _buildStatusBanner(can['statut'], isDark, currentLang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status, bool isDark, String currentLang) {
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
          Text(
            isAcc
                ? (currentLang == 'ar' ? "تم قبول الترشيح" : (currentLang == 'en' ? "Application Accepted" : "Candidature Acceptée"))
                : (currentLang == 'ar' ? "تم رفض الترشيح" : (currentLang == 'en' ? "Application Rejected" : "Candidature Refusée")),
            style: TextStyle(color: isAcc ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}