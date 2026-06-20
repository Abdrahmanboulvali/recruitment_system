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
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      String? token = await _storage.read(key: 'access');
      String? userRole = await _storage.read(key: 'role');

      String cleanRole = (userRole ?? "USER").toUpperCase().trim();

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/stats/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            stats = json.decode(utf8.decode(res.bodyBytes));
            role = cleanRole;
          });
        }
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuperAdmin = role == 'SUPER_ADMIN';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLang = Localizations.localeOf(context).languageCode;

    // استخراج القيم مع تأمين كافة المسميات المحتملة القادمة من الباكيند (تبادلياً)
    dynamic enterprisesCount = stats['total_enterprises'] ?? stats['total_enterprise'] ?? 0;
    dynamic usersCount = stats['total_users'] ?? stats['total_user'] ?? 0;
    dynamic offresCount = stats['total_offres'] ?? stats['total_offers'] ?? stats['total_jobs'] ?? 0;
    dynamic candidatsCount = stats['total_candidatures'] ?? stats['total_candidates'] ?? stats['total_candidat'] ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          currentLang == 'ar' ? "إحصائيات النظام" : (currentLang == 'en' ? "System Analytics" : "Analytiques Système"),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(isDark, currentLang),
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
                        _statCard(currentLang == 'ar' ? "الشركات" : (currentLang == 'en' ? "Enterprises" : "Entreprises"), enterprisesCount, Icons.business, [Colors.indigo, Colors.blue], theme, isDark),
                        _statCard(currentLang == 'ar' ? "المستخدمين" : (currentLang == 'en' ? "Users" : "Utilisateurs"), usersCount, Icons.people, [Colors.teal, Colors.green], theme, isDark),
                        _statCard(currentLang == 'ar' ? "الوظائف" : (currentLang == 'en' ? "Offers" : "Offres"), offresCount, Icons.work, [Colors.orange, Colors.amber], theme, isDark),
                        _statCard(currentLang == 'ar' ? "المترشحين" : (currentLang == 'en' ? "Candidates" : "Candidats"), candidatsCount, Icons.person_search, [Colors.pink, Colors.pinkAccent], theme, isDark),
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
                            Text(
                              currentLang == 'ar' ? "الإجراءات الإدارية" : "ACTIONS ADMINISTRATIVES",
                              style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15),
                            _buildQuickActionButton(
                              Icons.admin_panel_settings,
                              currentLang == 'ar' ? "إدارة الشركات" : (currentLang == 'en' ? "Manage Enterprises" : "Gérer les Entreprises"),
                              currentLang == 'ar' ? "التحقق والرقابة" : (currentLang == 'en' ? "Validation and control" : "Validation et contrôle"),
                              () => Navigator.pushNamed(context, '/manage-enterprises'),
                              theme,
                              isDark
                            ),
                            _buildQuickActionButton(
                              Icons.payments_rounded,
                              currentLang == 'ar' ? "حركة المدفوعات" : (currentLang == 'en' ? "Payment Flux" : "Flux de Paiements"),
                              currentLang == 'ar' ? "متابعة الاشتراكات" : (currentLang == 'en' ? "Subscription tracking" : "Suivi des abonnements"),
                              () => Navigator.pushNamed(context, '/manage-payments'),
                              theme,
                              isDark
                            ),
                          ],
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildChartSection(theme, isDark, currentLang),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildFinancialLineChart(theme, isDark, currentLang),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildDomainBarChart(theme, isDark, currentLang),
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

  Widget _buildHeader(bool isDark, String currentLang) {
    String roleText = "System Analytics";
    if (role == 'SUPER_ADMIN') {
      roleText = currentLang == 'ar' ? "الإدارة العامة" : (currentLang == 'en' ? "General Management" : "Direction Générale");
    } else {
      roleText = currentLang == 'ar' ? "تحليلات النظام" : (currentLang == 'en' ? "System Analytics" : "System Analytics");
    }

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
                Text(roleText, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget _buildChartSection(ThemeData theme, bool isDark, String currentLang) {
    final dist = stats['distribution'] ?? {'Fortement': 0, 'Pertinente': 0, 'Faiblement': 0};
    int total = (dist['Fortement'] ?? 0) + (dist['Pertinente'] ?? 0) + (dist['Faiblement'] ?? 0);

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
              Text(
                currentLang == 'ar' ? "توزيع مدى الملاءمة" : (currentLang == 'en' ? "Relevance Distribution" : "Répartition de la Pertinence"),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: total == 0
                ? Center(child: Text(currentLang == 'ar' ? "لا توجد بيانات متاحة" : "Aucune donnée disponible", style: TextStyle(color: isDark ? Colors.white30 : Colors.black38)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 45,
                      startDegreeOffset: -90,
                      sections: _buildPieSections(dist, total),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          _buildLegend(currentLang),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, dynamic> dist, int total) {
    int fort = dist['Fortement'] ?? 0;
    int moy = dist['Pertinente'] ?? 0;
    int faib = dist['Faiblement'] ?? 0;

    return [
      if (fort > 0)
        PieChartSectionData(
          value: fort.toDouble(),
          color: Colors.teal,
          radius: 35,
          title: '${((fort / total) * 100).toStringAsFixed(0)}%',
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (moy > 0)
        PieChartSectionData(
          value: moy.toDouble(),
          color: Colors.orange,
          radius: 35,
          title: '${((moy / total) * 100).toStringAsFixed(0)}%',
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (faib > 0)
        PieChartSectionData(
          value: faib.toDouble(),
          color: Colors.redAccent,
          radius: 35,
          title: '${((faib / total) * 100).toStringAsFixed(0)}%',
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ];
  }

  Widget _buildLegend(String currentLang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem(currentLang == 'ar' ? "قوية" : (currentLang == 'en' ? "Strongly" : "Fortement"), Colors.teal),
        _legendItem(currentLang == 'ar' ? "ملائمة" : (currentLang == 'en' ? "Relevant" : "Pertinente"), Colors.orange),
        _legendItem(currentLang == 'ar' ? "ضعيفة" : (currentLang == 'en' ? "Weakly" : "Faiblement"), Colors.redAccent),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFinancialLineChart(ThemeData theme, bool isDark, String currentLang) {
    List<dynamic> monthlyFlux = stats['financial_flux'] ?? [3000.0, 4500.0, 4000.0, 7000.0, 6500.0, 9000.0];

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stacked_line_chart, color: Colors.teal),
              const SizedBox(width: 10),
              Text(
                currentLang == 'ar' ? "التدفق المالي للاشتراكات (أوقية)" : (currentLang == 'en' ? "Financial Flux of Subscriptions (MRU)" : "Flux Financier des Abonnements (MRU)"),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        List<String> monthsAr = ['جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان'];
                        List<String> monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        List<String> monthsFr = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];

                        List<String> selectedMonths = currentLang == 'ar' ? monthsAr : (currentLang == 'en' ? monthsEn : monthsFr);

                        if (value.toInt() >= 0 && value.toInt() < selectedMonths.length) {
                          return Text(selectedMonths[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(monthlyFlux.length, (index) {
                      double val = double.tryParse(monthlyFlux[index].toString()) ?? 0.0;
                      return FlSpot(index.toDouble(), val);
                    }),
                    isCurved: true,
                    color: Colors.tealAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.tealAccent.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainBarChart(ThemeData theme, bool isDark, String currentLang) {
    // جلب البيانات التبادلية لقطاعات العمل سواء من المقتاح المخصص أو من مصفوفة تحليلات الوظائف الأصلية بالسيرفر
    final sectors = stats['sectors_activities'] ?? stats['offres_analytics'] ?? {'Tech': 0, 'Santé': 0, 'Finance': 0, 'Droit': 0};

    double techVal = double.tryParse((sectors['Tech'] ?? sectors['tech'] ?? 0).toString()) ?? 0.0;
    double santeVal = double.tryParse((sectors['Santé'] ?? sectors['sante'] ?? sectors['Health'] ?? 0).toString()) ?? 0.0;
    double financeVal = double.tryParse((sectors['Finance'] ?? sectors['finance'] ?? 0).toString()) ?? 0.0;
    double droitVal = double.tryParse((sectors['Droit'] ?? sectors['droit'] ?? sectors['Law'] ?? 0).toString()) ?? 0.0;

    double maxBarValue = [techVal, santeVal, financeVal, droitVal].reduce((a, b) => a > b ? a : b);
    if (maxBarValue < 10) maxBarValue = 10;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.orange),
              const SizedBox(width: 10),
              Text(
                currentLang == 'ar' ? "أنشطة قطاعات العمل" : (currentLang == 'en' ? "Sectors Activities" : "Activités des Secteurs d'Emploi"),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxBarValue + 2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0: return Text(currentLang == 'ar' ? 'تكنولوجيا' : 'Tech', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                          case 1: return Text(currentLang == 'ar' ? 'صحة' : 'Santé', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                          case 2: return Text(currentLang == 'ar' ? 'مالية' : 'Finance', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                          case 3: return Text(currentLang == 'ar' ? 'قانون' : 'Droit', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                          default: return const Text('');
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: techVal, color: Colors.blueAccent, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: santeVal, color: Colors.teal, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: financeVal, color: Colors.amber, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: droitVal, color: Colors.purpleAccent, width: 16, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}