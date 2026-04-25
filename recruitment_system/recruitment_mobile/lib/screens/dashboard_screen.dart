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
          totalCompanies = data['total_entreprises'] ?? 0;
          totalUsers = data['total_users'] ?? 0;
          recentCandidatures = data['offres_analytics'] ?? [];
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
    // تحديد ما إذا كان التطبيق في الوضع المظلم حالياً
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // استخدام لون خلفية الثيم
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text("Dashboard RH",
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
                    _buildTopHeader(isDark),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(isSuperAdmin ? "Entreprises" : "Offres", activeOffers.toString(), Icons.business, [Colors.orange, Colors.orangeAccent], theme)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildStatCard("Candidatures", totalCandidatures.toString(), Icons.description, [Colors.blue, Colors.blueAccent], theme)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle("Visualisation des Data", isDark),
                    const SizedBox(height: 15),
                    _buildChartSection(theme),
                    const SizedBox(height: 30),
                    _buildSectionTitle("Dernières Activités", isDark),
                    const SizedBox(height: 15),
                    _buildRecentList(theme, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopHeader(bool isDark) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("Bonjour, $_username 👋",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
    Text(_enterprise.toUpperCase(),
        style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildSectionTitle(String title, bool isDark) => Text(title,
      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1));

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors, ThemeData theme) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: theme.cardColor, // يتغير آلياً حسب الثيم
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ]
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: colors[0]),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87)),
      Text(label, style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white54 : Colors.black45, fontSize: 11)),
    ]),
  );

  Widget _buildChartSection(ThemeData theme) => Container(
    height: 150,
    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
    child: Center(child: Text("Graphique Animé", style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white24 : Colors.black12))),
  );

  Widget _buildRecentList(ThemeData theme, bool isDark) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: recentCandidatures.length,
    itemBuilder: (context, index) {
      final item = recentCandidatures[index];
      return Card(
        color: theme.cardColor,
        elevation: isDark ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text(item['titre'] ?? "Poste",
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text("Candidats: ${item['count']}",
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          trailing: Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? Colors.white24 : Colors.black26),
        ),
      );
    },
  );
}