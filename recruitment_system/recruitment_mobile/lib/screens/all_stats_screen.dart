import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_config.dart';
import '../main.dart'; // استيراد AppDrawer من الملف الرئيسي

class AllStatsScreen extends StatefulWidget {
  const AllStatsScreen({super.key});

  @override
  State<AllStatsScreen> createState() => _AllStatsScreenState();
}

class _AllStatsScreenState extends State<AllStatsScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  String role = "USER";

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => isLoading = true);
    String? token = await _storage.read(key: 'access');
    String? userRole = await _storage.read(key: 'role');

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/stats/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          stats = json.decode(utf8.decode(res.bodyBytes));
          role = (userRole ?? "USER").toUpperCase().trim();
        });
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuperAdmin = role == 'SUPER_ADMIN';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text("Analytiques Système",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(isDark),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildListDelegate([
                        _statCard("Entreprises", stats['total_enterprises'] ?? 0, Icons.business, [Colors.indigo, Colors.blue], theme, isDark),
                        _statCard("Utilisateurs", stats['total_users'] ?? 0, Icons.people, [Colors.teal, Colors.green], theme, isDark),
                        _statCard("Offres", stats['total_offres'] ?? stats['total_offers'] ?? 0, Icons.work, [Colors.orange, Colors.amber], theme, isDark),
                        _statCard("Candidats", stats['total_candidatures'] ?? stats['total_candidates'] ?? 0, Icons.person_search, [Colors.pink, Colors.pinkAccent], theme, isDark),
                      ]),
                    ),
                  ),

                  if (isSuperAdmin)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ACTIONS ADMINISTRATIVES",
                              style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            _buildQuickActionButton(Icons.admin_panel_settings, "Gérer les Entreprises", "Validation et contrôle", () => Navigator.pushNamed(context, '/manage-enterprises'), theme, isDark),
                            _buildQuickActionButton(Icons.payments_rounded, "Flux de Paiements", "Suivi des abonnements", () => Navigator.pushNamed(context, '/manage-payments'), theme, isDark),
                          ],
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildChartSection(theme, isDark),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String title, String sub, VoidCallback onTap, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: ApiConfig.kPrimary.withOpacity(0.1),
          child: Icon(icon, color: ApiConfig.kPrimary, size: 20),
        ),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        trailing: Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white24 : Colors.black26, size: 14),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: ApiConfig.kPrimary, size: 30),
                const SizedBox(width: 10),
                Text(role == 'SUPER_ADMIN' ? "Direction Générale" : "System Analytics",
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const Text("PERFORMANCE INSIGHT SYSTEM",
                style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, dynamic count, IconData icon, List<Color> colors, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors[0].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: colors[0], size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count.toString(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline, color: ApiConfig.kPrimary),
              const SizedBox(width: 10),
              Text("Répartition de la Pertinence", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 5,
                centerSpaceRadius: 50,
                sections: _buildPieSections(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final dist = stats['distribution'] ?? {'Fortement': 0, 'Pertinente': 0, 'Faiblement': 0};
    return [
      PieChartSectionData(value: (dist['Fortement'] ?? 0).toDouble(), color: Colors.greenAccent, radius: 20, showTitle: false),
      PieChartSectionData(value: (dist['Pertinente'] ?? 0).toDouble(), color: Colors.orangeAccent, radius: 20, showTitle: false),
      PieChartSectionData(value: (dist['Faiblement'] ?? 0).toDouble(), color: Colors.redAccent, radius: 20, showTitle: false),
    ];
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem("Fort", Colors.greenAccent),
        _legendItem("Moyen", Colors.orangeAccent),
        _legendItem("Faible", Colors.redAccent),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}