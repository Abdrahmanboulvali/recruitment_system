import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_config.dart';
import '../main.dart'; // لاستيراد AppDrawer

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String _username = '';
  String _enterprise = '';

  int totalCandidatures = 0;
  int activeOffers = 0;
  int totalCompanies = 0;
  int totalUsers = 0;
  List<dynamic> recentCandidatures = [];

  int fortementCount = 0;
  int pertinenteCount = 0;
  int faiblementCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    String? user = await _storage.read(key: 'username');
    String? ent = await _storage.read(key: 'enterprise_name');
    setState(() {
      _username = user ?? 'Utilisateur';
      _enterprise = ent ?? 'Entreprise';
    });
    await _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final String fullUrl = '${ApiConfig.baseUrl}/api/stats/';

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          activeOffers = data['total_offres'] ?? 0;
          totalCandidatures = data['total_candidatures'] ?? 0;
          totalCompanies = data['total_enterprises'] ?? data['total_entreprises'] ?? 0;
          totalUsers = data['total_users'] ?? 0;
          recentCandidatures = data['offres_analytics'] ?? [];

          if (data['distribution'] != null) {
            fortementCount = data['distribution']['Fortement'] ?? 0;
            pertinenteCount = data['distribution']['Pertinente'] ?? 0;
            faiblementCount = data['distribution']['Faiblement'] ?? 0;
          }


          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuperAdmin = totalCompanies > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          currentLang == 'ar' ? "لوحة التحكم" : (currentLang == 'en' ? "HR Dashboard" : "Dashboard RH"),
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(isDark, currentLang),
                    const SizedBox(height: 30),

                    if (isSuperAdmin) ...[
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(currentLang == 'ar' ? "الشركات" : (currentLang == 'en' ? "Enterprises" : "Entreprises"), totalCompanies.toString(), Icons.business, [Colors.orange, Colors.orangeAccent], theme)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildStatCard(currentLang == 'ar' ? "المستخدمين" : (currentLang == 'en' ? "Users" : "Utilisateurs"), totalUsers.toString(), Icons.people, [Colors.purple, Colors.purpleAccent], theme)),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(currentLang == 'ar' ? "الوظائف" : (currentLang == 'en' ? "Offers" : "Offres"), activeOffers.toString(), Icons.work, [Colors.orange, Colors.orangeAccent], theme)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildStatCard(currentLang == 'ar' ? "الترشيحات" : (currentLang == 'en' ? "Applications" : "Candidatures"), totalCandidatures.toString(), Icons.description, [Colors.blue, Colors.blueAccent], theme)),
                      ],
                    ),

                    const SizedBox(height: 30),
                    _buildSectionTitle(currentLang == 'ar' ? "عرض البيانات البيانية" : (currentLang == 'en' ? "Data Visualization" : "Visualisation des Data"), isDark),
                    const SizedBox(height: 15),
                    _buildChartSection(theme, currentLang),

                    const SizedBox(height: 30),
                    _buildSectionTitle(currentLang == 'ar' ? "أحدث الأنشطة والسكور" : (currentLang == 'en' ? "Activities & AI Scores" : "Activités et Scores IA"), isDark),
                    const SizedBox(height: 15),
                    _buildRecentList(theme, isDark, currentLang),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopHeader(bool isDark, String currentLang) {
    String greeting = "Bonjour, $_username 👋";
    if (currentLang == 'ar') greeting = "مرحباً، $_username 👋";
    else if (currentLang == 'en') greeting = "Hello, $_username 👋";

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(greeting, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      Text(_enterprise.toUpperCase(), style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSectionTitle(String title, bool isDark) => Text(title,
      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1));

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors, ThemeData theme) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [if (theme.brightness == Brightness.light) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: colors[0]),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87)),
      Text(label, style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white54 : Colors.black45, fontSize: 11)),
    ]),
  );

  Widget _buildChartSection(ThemeData theme, String currentLang) {
    int total = fortementCount + pertinenteCount + faiblementCount;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          SizedBox(height: 160, child: total == 0 ? Center(child: Text(currentLang == 'ar' ? "لا توجد بيانات تحليلية متاحة" : "No analysis data", style: TextStyle(color: isDark ? Colors.white30 : Colors.black38))) : PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 35, startDegreeOffset: -90, sections: [
            if (fortementCount > 0) PieChartSectionData(color: Colors.green, value: fortementCount.toDouble(), title: '${((fortementCount / total) * 100).toStringAsFixed(0)}%', radius: 40, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            if (pertinenteCount > 0) PieChartSectionData(color: Colors.orange, value: pertinenteCount.toDouble(), title: '${((pertinenteCount / total) * 100).toStringAsFixed(0)}%', radius: 40, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            if (faiblementCount > 0) PieChartSectionData(color: Colors.redAccent, value: faiblementCount.toDouble(), title: '${((faiblementCount / total) * 100).toStringAsFixed(0)}%', radius: 40, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ]))),
          if (total > 0) ...[
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildLegendItem(Colors.green, currentLang == 'ar' ? "قوية" : "Strongly", isDark),
              _buildLegendItem(Colors.orange, currentLang == 'ar' ? "ملائمة" : "Relevant", isDark),
              _buildLegendItem(Colors.redAccent, currentLang == 'ar' ? "ضعيفة" : "Weakly", isDark),
            ]),
          ]
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500)),
    ]);
  }

  // --- تحديث عرض القائمة ليشمل سكور الذكاء الاصطناعي ---
  Widget _buildRecentList(ThemeData theme, bool isDark, String currentLang) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: recentCandidatures.length,
    itemBuilder: (context, index) {
      final item = recentCandidatures[index];
      double score = (item['avg_score'] ?? 0.0).toDouble();
      Color scoreColor = score >= 75 ? Colors.green : (score >= 40 ? Colors.orange : Colors.redAccent);

      return Card(
        color: theme.cardColor,
        elevation: isDark ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['titre'] ?? "Poste", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("${score.toStringAsFixed(1)}%", style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "${currentLang == 'ar' ? 'عدد المترشحين' : 'Candidates'}: ${item['count']}",
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
        ),
      );
    },
  );
}