import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';
import '../main.dart';

class EspaceCandidat extends StatefulWidget {
  const EspaceCandidat({super.key});

  @override
  State<EspaceCandidat> createState() => _EspaceCandidatState();
}

class _EspaceCandidatState extends State<EspaceCandidat> {
  final _storage = const FlutterSecureStorage();
  List offres = [];
  List entreprises = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isDarkMode = true;
  String _selectedTab = 'OFFRES';
  String _searchTerm = "";
  String _selectedSpecialty = "Tous";

  final List<String> specialties = [
    "Tous", "Data Science", "Full Stack", "Data Analyst",
    "Comptabilité", "Marketing", "RH", "Design", "Finance", "Autre"
  ];

  @override
  void initState() {
    super.initState();
    _initialSetup();
  }

  Future<void> _initialSetup() async {
    String? savedMode = await _storage.read(key: 'isDarkMode');
    if (savedMode != null) setState(() => _isDarkMode = savedMode == 'true');

    String? token = await _storage.read(key: 'access');
    setState(() => _isLoggedIn = token != null);

    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      String? token = await _storage.read(key: 'access');
      Map<String, String> headers = token != null ? {'Authorization': 'Bearer $token'} : {};

      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/offres/'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/enterprises/'), headers: headers),
      ]);

      setState(() {
        offres = json.decode(utf8.decode(responses[0].bodyBytes));
        entreprises = json.decode(utf8.decode(responses[1].bodyBytes));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  // تم تعديل الدالة لضمان الانتقال الصحيح وتحديث الحالة عند العودة
  void _handleApply(int offreId) {
    if (_isLoggedIn) {
      Navigator.pushNamed(
        context,
        '/postuler',
        arguments: offreId
      );
    } else {
      Navigator.pushNamed(context, '/login').then((_) {
        _initialSetup(); // تحديث حالة الدخول فور العودة من صفحة Login
      });
    }
  }

  Future<void> _toggleTheme() async {
    MyApp.of(context).toggleTheme();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bgColor = _isDarkMode ? ApiConfig.kBgMain : const Color(0xFFF1F5F9);
    final cardColor = _isDarkMode ? ApiConfig.kBgCard : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: _isLoggedIn ? const AppDrawer() : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isLoggedIn
          ? Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_rounded, color: textColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : Icon(Icons.hub_outlined, color: ApiConfig.kPrimary, size: 28),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Portail de Recrutement",
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Plateforme intelligente",
                style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
          ],
        ),
        actions: [
          if (!_isLoggedIn) ...[
            IconButton(
              icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: Colors.orange, size: 20),
              onPressed: _toggleTheme,
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text("Login", style: TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ApiConfig.kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ]
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSearchBar(textColor, cardColor),
              _buildSpecialties(textColor),
              _buildTabs(textColor, cardColor),
              Expanded(
                child: _selectedTab == 'OFFRES'
                  ? _buildOffresList(textColor, cardColor)
                  : _buildEntreprisesGrid(textColor, cardColor),
              ),
            ],
          ),
    );
  }

  Widget _buildSearchBar(Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        onChanged: (v) => setState(() => _searchTerm = v),
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: "Rechercher...",
          hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSpecialties(Color textColor) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: specialties.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, i) {
          bool isSelected = _selectedSpecialty == specialties[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(specialties[i]),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedSpecialty = specialties[i]),
              selectedColor: ApiConfig.kPrimary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : textColor),
              backgroundColor: Colors.transparent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs(Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          _tabBtn("OFFRES", Icons.work, cardColor, textColor),
          const SizedBox(width: 10),
          _tabBtn("ENTREPRISES", Icons.business, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, IconData icon, Color cardColor, Color textColor) {
    bool isSelected = _selectedTab == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? ApiConfig.kPrimary : cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : textColor, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffresList(Color textColor, Color cardColor) {
    var filtered = offres.where((o) {
      bool matchesSearch = o['titre'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
      if (_selectedSpecialty == "Tous") return matchesSearch;
      return matchesSearch && o['titre'].toString().toLowerCase().contains(_selectedSpecialty.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.all(15),
      itemBuilder: (context, i) {
        var o = filtered[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: textColor.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(o['titre'], style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("🏢 ${o['enterprise_name']}", style: const TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              Text(o['description'], maxLines: 2, style: TextStyle(color: textColor.withOpacity(0.7))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // تم تعديل اللون ليكون مطابقاً للويب (أخضر عند تسجيل الدخول)
                    backgroundColor: _isLoggedIn ? const Color(0xFF16A34A) : ApiConfig.kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _handleApply(o['id']),
                  child: Text(
                    _isLoggedIn ? "Postuler maintenant" : "Connectez-vous pour postuler",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntreprisesGrid(Color textColor, Color cardColor) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
      itemCount: entreprises.length,
      itemBuilder: (context, i) {
        var e = entreprises[i];
        return Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: ApiConfig.kPrimary.withOpacity(0.1),
                child: Text(e['nom'].toString().isNotEmpty ? e['nom'][0] : "E", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Text(e['nom'] ?? "Entreprise", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  // الانتقال لصفحة الشركة مع تمرير المعرف (نفس منطق الويب)
                  Navigator.pushNamed(
                    context,
                    '/profile-entreprise',
                    arguments: {'id': e['id']}
                  );
                },
                child: const Text("Profil"),
              )
            ],
          ),
        );
      },
    );
  }
}