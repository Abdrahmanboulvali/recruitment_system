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
    setState(() => _isLoading = true);
    try {
      String? token = await _storage.read(key: 'access');
      // الرابط الصحيح (api/stats/)
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
          // تصحيح المسميات لتطابق السيرفر
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

    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      appBar: AppBar(
        backgroundColor: ApiConfig.kBgMain,
        elevation: 0,
        title: const Text("Dashboard RH", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawer(), // إضافة القائمة الجانبية هنا
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
                    _buildTopHeader(),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(isSuperAdmin ? "Entreprises" : "Offres", activeOffers.toString(), Icons.business, [Colors.orange, Colors.orangeAccent])),
                        const SizedBox(width: 15),
                        Expanded(child: _buildStatCard("Candidatures", totalCandidatures.toString(), Icons.description, [Colors.blue, Colors.blueAccent])),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle("Visualisation des Data"),
                    const SizedBox(height: 15),
                    _buildChartSection(),
                    const SizedBox(height: 30),
                    _buildSectionTitle("Dernières Activités"),
                    const SizedBox(height: 15),
                    _buildRecentList(),
                  ],
                ),
              ),
            ),
    );
  }

  // ... (بقية دوام المكونات UI كما هي في كودك السابق)
  Widget _buildTopHeader() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("Bonjour, $_username 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    Text(_enterprise.toUpperCase(), style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1));

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: ApiConfig.kBgCard, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: colors[0]),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]),
  );

  Widget _buildChartSection() => Container(
    height: 150,
    decoration: BoxDecoration(color: ApiConfig.kBgCard, borderRadius: BorderRadius.circular(20)),
    child: const Center(child: Text("Graphique Animé", style: TextStyle(color: Colors.white24))),
  );

  Widget _buildRecentList() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: recentCandidatures.length,
    itemBuilder: (context, index) {
      final item = recentCandidatures[index];
      return Card(
        color: ApiConfig.kBgCard,
        child: ListTile(
          title: Text(item['titre'] ?? "Poste", style: const TextStyle(fontSize: 14)),
          subtitle: Text("Candidats: ${item['count']}", style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 12),
        ),
      );
    },
  );
}