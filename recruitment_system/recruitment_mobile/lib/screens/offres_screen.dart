import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/offre.dart';
import '../api_config.dart';
import 'details_screen.dart';
import 'login_screen.dart';

class OffresScreen extends StatefulWidget {
  const OffresScreen({super.key});

  @override
  _OffresScreenState createState() => _OffresScreenState();
}

class _OffresScreenState extends State<OffresScreen> {
  final ApiService apiService = ApiService();
  String _selectedCategory = "Tous";

  // قائمة التصنيفات الأساسية
  final List<String> _categories = ["Tous", "Data Science", "Full Stack", "Comptabilité"];

  // خريطة لترجمة أسماء التصنيفات ديناميكياً لتظهر للمستخدم باللغة المحددة دون تغيير قيمتها البرمجية المرسلة للـ API
  final Map<String, Map<String, String>> _translatedCategories = {
    "Tous": {"ar": "الكل", "fr": "Tous", "en": "All"},
    "Data Science": {"ar": "علوم البيانات", "fr": "Data Science", "en": "Data Science"},
    "Full Stack": {"ar": "تطوير متكامل", "fr": "Full Stack", "en": "Full Stack"},
    "Comptabilité": {"ar": "المحاسبة", "fr": "Comptabilité", "en": "Accounting"},
  };

  @override
  Widget build(BuildContext context) {
    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(currentLang),
            _buildSearchBar(currentLang),
            _buildCategoryChips(currentLang),
            Expanded(
              child: FutureBuilder<List<Offre>>(
                future: apiService.getOffres(category: _selectedCategory),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary));
                  final list = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    itemBuilder: (context, index) => _buildJobCard(list[index], currentLang),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String currentLang) {
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
              Text(
                currentLang == 'ar' ? "التوظيف" : "Recrutement",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())),
                child: Text(
                  currentLang == 'ar' ? "دخول" : "Connexion",
                  style: const TextStyle(color: Colors.white70)
                ),
              ),
              ElevatedButton(
                onPressed: () {}, // اربطه بصفحة التسجيل
                style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
                child: Text(currentLang == 'ar' ? "تسجيل" : "S'inscrire"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildJobCard(Offre offre, String currentLang) {
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
            runSpacing: 4,
            children: offre.competences.split(',').map((s) => _buildChip(s.trim())).toList(),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(offre: offre))),
              child: Text(currentLang == 'ar' ? "التفاصيل والترشح" : "Détails & Postuler"),
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

  Widget _buildSearchBar(String currentLang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.white54),
          hintText: currentLang == 'ar' ? "بحث..." : "Rechercher...",
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(String currentLang) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          // جلب الاسم المترجم للتصنيف بناءً على لغة الجهاز الحالية
          final displayedText = _translatedCategories[cat]?[currentLang] ?? cat;

          return Padding(
            padding: const EdgeInsets.only(right: 10, left: 10),
            child: ChoiceChip(
              label: Text(displayedText),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: ApiConfig.kPrimary,
              backgroundColor: ApiConfig.kBgCard,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }
}