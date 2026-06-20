import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../api_config.dart';

class ManageOffresScreen extends StatefulWidget {
  const ManageOffresScreen({super.key});

  @override
  State<ManageOffresScreen> createState() => _ManageOffresScreenState();
}

class _ManageOffresScreenState extends State<ManageOffresScreen> {
  final _storage = const FlutterSecureStorage();
  List offres = [];
  bool isLoading = true;
  bool showForm = false;
  bool isEditing = false;
  int? currentId;

  Map<String, dynamic>? subscription;

  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _expController = TextEditingController(text: '0');
  final _skillsController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    await _fetchOffres();
    await _checkSubscription();
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchOffres() async {
    final token = await _storage.read(key: 'access');
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/offres/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => offres = json.decode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint("Error fetching offres: $e");
    }
  }

  Future<void> _checkSubscription() async {
    final token = await _storage.read(key: 'access');
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/my-subscription/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => subscription = json.decode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint("Error checking subscription: $e");
    }
  }

  void _resetForm() {
    _titreController.clear();
    _descController.clear();
    _expController.text = '0';
    _skillsController.clear();
    _selectedDate = null;
    setState(() {
      showForm = false;
      isEditing = false;
      currentId = null;
    });
  }

  void _handleEditClick(Map offre) {
    _titreController.text = offre['titre'];
    _descController.text = offre['description'];
    _expController.text = offre['experience_min'].toString();
    _skillsController.text = offre['competences_requises'] ?? '';
    if (offre['date_expiration'] != null) {
      _selectedDate = DateTime.parse(offre['date_expiration']);
    }
    setState(() {
      isEditing = true;
      currentId = offre['id'];
      showForm = true;
    });
  }

  Future<void> _handleSubmit(String currentLang) async {
    if (_selectedDate == null) {
      String dateMsg = currentLang == 'ar'
          ? "يرجى اختيار تاريخ انتهاء الصلاحية"
          : "Veuillez choisir une date d'expiration";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dateMsg)));
      return;
    }

    final token = await _storage.read(key: 'access');
    final data = {
      "titre": _titreController.text,
      "description": _descController.text,
      "experience_min": int.tryParse(_expController.text) ?? 0,
      "competences_requises": _skillsController.text,
      "date_expiration": _selectedDate!.toIso8601String(),
    };

    try {
      final url = isEditing
          ? '${ApiConfig.baseUrl}/api/offres/$currentId/'
          : '${ApiConfig.baseUrl}/api/offres/';

      final response = await (isEditing
          ? http.put(Uri.parse(url), headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}, body: jsonEncode(data))
          : http.post(Uri.parse(url), headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}, body: jsonEncode(data)));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        _initData();
        if (mounted) {
          String successMsg = isEditing
              ? (currentLang == 'ar' ? "تم التعديل بنجاح!" : "Modifiée !")
              : (currentLang == 'ar' ? "تم النشر بنجاح!" : "Publiée !");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
        }
      } else {
        final err = json.decode(response.body);
        if (mounted) {
          String errMsg = err['error'] ?? (currentLang == 'ar' ? "حدث خطأ ما" : "Erreur");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
        }
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    // صياغة نص حالة الاشتراك المترجم ديناميكياً
    String subStatusText = "";
    if (subscription != null && subscription!['status'] == 'ACTIVE') {
      String packTitle = subscription!['plan_details']['title'];
      int currentUsage = subscription!['plan_details']['current_usage'];
      int totalOffers = subscription!['plan_details']['offres_count'];

      subStatusText = currentLang == 'ar'
          ? "✅ باقة نشطة: $packTitle ($currentUsage/$totalOffers)"
          : "✅ Pack Actif: $packTitle ($currentUsage/$totalOffers)";
    } else {
      int currentUsage = subscription?['plan_details']?['current_usage'] ?? 0;
      subStatusText = currentLang == 'ar'
          ? "🟠 الوضع المجاني ($currentUsage/3)"
          : "🟠 Mode Gratuit ($currentUsage/3)";
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLang == 'ar' ? "إدارة العروض" : (currentLang == 'en' ? "Manage Offers" : "Gestion des Offres"),
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
            ),
            Text(
              subStatusText,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (showForm) _resetForm();
              else {
                final usage = subscription?['plan_details']?['current_usage'] ?? 0;
                final limit = subscription?['plan_details']?['offres_count'] ?? 3;
                if (usage >= limit) {
                  _showLimitDialog(currentLang);
                } else {
                  setState(() => showForm = true);
                }
              }
            },
            icon: Icon(showForm ? Icons.close : Icons.add_circle, color: showForm ? Colors.red : ApiConfig.kPrimary),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (showForm) _buildGlassForm(theme, isDark, currentLang),
                  const SizedBox(height: 20),
                  ...offres.map((o) => _buildOffreCard(o, theme, isDark, currentLang)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGlassForm(ThemeData theme, bool isDark, String currentLang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing
                ? (currentLang == 'ar' ? "📝 تعديل العرض" : "📝 Modifier")
                : (currentLang == 'ar' ? "📌 عرض جديد" : "📌 Nouvelle offre"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
          ),
          const SizedBox(height: 15),
          _buildInput(_titreController, currentLang == 'ar' ? "المسمى الوظيفي" : (currentLang == 'en' ? "Job Title" : "Titre du poste"), isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  _expController,
                  currentLang == 'ar' ? "الخبرة الأدنى" : (currentLang == 'en' ? "Min Exp" : "Exp min"),
                  isDark,
                  isNumber: true
                )
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      _selectedDate == null
                          ? (currentLang == 'ar' ? "تاريخ الانتهاء" : "Date Exp.")
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInput(_skillsController, currentLang == 'ar' ? "المهارات (مثال: SQL, Java)" : "Compétences (ex: SQL, Java)", isDark),
          const SizedBox(height: 10),
          _buildInput(_descController, currentLang == 'ar' ? "الوصف الوظيفي" : "Description", isDark, maxLines: 3),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _handleSubmit(currentLang),
              style: ElevatedButton.styleFrom(
                backgroundColor: ApiConfig.kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(
                isEditing
                    ? (currentLang == 'ar' ? "حفظ التغييرات" : "Enregistrer")
                    : (currentLang == 'ar' ? "نشر العرض" : "Publier")
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOffreCard(Map o, ThemeData theme, bool isDark, String currentLang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(o['titre'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87))),
              Row(
                children: [
                  IconButton(onPressed: () => _handleEditClick(o), icon: const Icon(Icons.edit, color: Colors.blue, size: 20)),
                  IconButton(onPressed: () => _showDeleteDialog(o['id'], currentLang), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                ],
              )
            ],
          ),
          Text(o['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            children: (o['competences_requises']?.toString().split(',') ?? []).map((s) => Chip(
              label: Text(s.trim(), style: const TextStyle(fontSize: 10, color: ApiConfig.kPrimary)),
              backgroundColor: ApiConfig.kPrimary.withOpacity(0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            )).toList(),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentLang == 'ar' ? "⏳ الخبرة: ${o['experience_min']} سنوات" : "⏳ Exp: ${o['experience_min']} ans",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)
              ),
              Text(
                "${currentLang == 'ar' ? '⌛ ينتهي في: ' : '⌛ Expire: '}${o['date_expiration'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(o['date_expiration'])) : 'N/A'}",
                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, bool isDark, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }

  void _showLimitDialog(String currentLang) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E232D) : Colors.white,
        title: Text(currentLang == 'ar' ? "⚠️ تم الوصول للحد الأقصى" : "⚠️ Limite atteinte"),
        content: Text(currentLang == 'ar' ? "يرجى تفعيل إحدى الباقات لتتمكن من نشر المزيد من العروض." : "Veuillez activer un pack pour publier plus d'offres."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(currentLang == 'ar' ? "موافق" : "OK")
          )
        ],
      )
    );
  }

  void _showDeleteDialog(int id, String currentLang) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E232D) : Colors.white,
        title: Text(currentLang == 'ar' ? "حذف العرض؟" : "Supprimer ?"),
        content: Text(currentLang == 'ar' ? "هل أنت متأكد من أنك تريد حذف هذا العرض نهائياً؟" : "Voulez-vous vraiment supprimer cette offre ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(currentLang == 'ar' ? "إلغاء" : "Annuler", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54))
          ),
          TextButton(
            onPressed: () async {
              final token = await _storage.read(key: 'access');
              await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/offres/$id/'), headers: {"Authorization": "Bearer $token"});
              if (mounted) Navigator.pop(c);
              _initData();
            },
            child: Text(currentLang == 'ar' ? "حذف" : "Supprimer", style: const TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
}