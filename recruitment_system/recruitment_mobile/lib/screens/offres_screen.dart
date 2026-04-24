import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/offre.dart';
import '../api_config.dart';
import 'details_screen.dart';
import 'login_screen.dart';

class OffresScreen extends StatefulWidget {
  @override
  _OffresScreenState createState() => _OffresScreenState();
}

class _OffresScreenState extends State<OffresScreen> {
  final ApiService apiService = ApiService();
  String _selectedCategory = "Tous";
  final List<String> _categories = ["Tous", "Data Science", "Full Stack", "Comptabilité"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(
              child: FutureBuilder<List<Offre>>(
                future: apiService.getOffres(category: _selectedCategory),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    itemBuilder: (context, index) => _buildJobCard(list[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // زر العودة الخلفي
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Text("Recrutement",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())),
                child: const Text("Connexion", style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () {}, // اربطه بصفحة التسجيل
                style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
                child: const Text("S'inscrire"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildJobCard(Offre offre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offre.titre, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(offre.enterprise, style: const TextStyle(color: ApiConfig.kPrimary)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            children: offre.competences.split(',').map((s) => _buildChip(s.trim())).toList(),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(offre: offre))),
              child: const Text("Détails & Postuler"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.white54),
          hintText: "Rechercher...",
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: ApiConfig.kPrimary,
              backgroundColor: ApiConfig.kBgCard,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white54),
            ),
          );
        },
      ),
    );
  }
}