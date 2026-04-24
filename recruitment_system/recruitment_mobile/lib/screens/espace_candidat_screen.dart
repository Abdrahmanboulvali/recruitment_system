import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';

class EspaceCandidatScreen extends StatefulWidget {
  const EspaceCandidatScreen({super.key});

  @override
  State<EspaceCandidatScreen> createState() => _EspaceCandidatScreenState();
}

class _EspaceCandidatScreenState extends State<EspaceCandidatScreen> {
  final _storage = const FlutterSecureStorage();
  List offres = [];
  List entreprises = [];
  bool isLoading = true;
  String activeTab = 'OFFRES'; // 'OFFRES' أو 'ENTREPRISES'
  String searchTerm = "";
  String selectedSpecialty = "Tous";
  bool isLoggedIn = false;

  final List<String> specialties = [
    "Tous", "Data Science", "Full Stack", "Data Analyst",
    "Comptabilité", "Marketing", "RH", "Design", "Finance", "Autre"
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetch();
  }

  Future<void> _checkAuthAndFetch() async {
    String? token = await _storage.read(key: 'access');
    setState(() => isLoggedIn = token != null);
    await _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    String? token = await _storage.read(key: 'access');
    Map<String, String> headers = token != null ? {'Authorization': 'Bearer $token'} : {};

    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/offres/'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/enterprises/'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        var data = json.decode(utf8.decode(results[0].bodyBytes));
        offres = data is List ? data : (data['results'] ?? []);
      }
      if (results[1].statusCode == 200) {
        var data = json.decode(utf8.decode(results[1].bodyBytes));
        entreprises = data is List ? data : (data['results'] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List get filteredOffres {
    // تم استخدام .where بدلاً من .filter لأنها الدالة القياسية في Dart
    return offres.where((o) {
      final title = o['titre'].toString().toLowerCase();
      final matchesSearch = title.contains(searchTerm.toLowerCase());
      if (selectedSpecialty == "Tous") return matchesSearch;
      return matchesSearch && title.contains(selectedSpecialty.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Portail", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            Text("Trouvez votre carrière idéale", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                        if (!isLoggedIn)
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
                            child: const Text("Connexion"),
                          )
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildSearchBar(),
                    const SizedBox(height: 15),
                    _buildSpecialtiesFilter(),
                  ],
                ),
              ),
            ),

            // Tabs Selector
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  color: ApiConfig.kBgMain,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _tabButton("OFFRES", Icons.work_outline),
                      const SizedBox(width: 10),
                      _tabButton("ENTREPRISES", Icons.business_outlined),
                    ],
                  ),
                ),
              ),
            ),

            // Content Grid
            isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: activeTab == 'OFFRES' ? _buildOffresGrid() : _buildEntreprisesGrid(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        onChanged: (v) => setState(() => searchTerm = v),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: "Rechercher un emploi...",
          hintStyle: TextStyle(color: Colors.white30),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSpecialtiesFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          bool isSelected = selectedSpecialty == specialties[i];
          return ChoiceChip(
            label: Text(specialties[i]),
            selected: isSelected,
            onSelected: (v) => setState(() => selectedSpecialty = specialties[i]),
            selectedColor: ApiConfig.kPrimary,
            backgroundColor: ApiConfig.kBgCard,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
          );
        },
      ),
    );
  }

  Widget _tabButton(String label, IconData icon) {
    bool isActive = activeTab == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => activeTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? ApiConfig.kPrimary : ApiConfig.kBgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffresGrid() {
    final list = filteredOffres;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final o = list[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ApiConfig.kBgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("RECRUTEMENT", style: TextStyle(color: ApiConfig.kPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                    if (o['date_expiration'] != null)
                      const Icon(Icons.access_time, color: Colors.green, size: 14),
                  ],
                ),
                const SizedBox(height: 10),
                Text(o['titre'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("🏢 ${o['enterprise_name']}", style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 13)),
                const SizedBox(height: 15),
                Text(o['description'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleApply(o['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoggedIn ? Colors.green : ApiConfig.kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isLoggedIn ? "Postuler" : "Se connecter pour postuler"),
                  ),
                )
              ],
            ),
          );
        },
        childCount: list.length, // تم التغيير إلى childCount
      ),
    );
  }

  Widget _buildEntreprisesGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final ent = entreprises[i];
          return Container(
            decoration: BoxDecoration(color: ApiConfig.kBgCard, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: ApiConfig.kBgMain,
                  child: Text(ent['nom']?[0] ?? "E", style: const TextStyle(fontSize: 24, color: ApiConfig.kPrimary)),
                ),
                const SizedBox(height: 15),
                Text(ent['nom'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextButton(onPressed: () {}, child: const Text("Voir Profil"))
              ],
            ),
          );
        },
        childCount: entreprises.length, // تم التغيير إلى childCount
      ),
    );
  }

  void _handleApply(int id) {
    if (isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonctionnalité de candidature bientôt disponible")));
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabBarDelegate({required this.child});
  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

extension ListFilter on List {
  Iterable filter(bool Function(dynamic) test) => where(test);
}