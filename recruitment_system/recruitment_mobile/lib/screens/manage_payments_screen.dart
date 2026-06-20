import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_config.dart';

class ManagePaymentsScreen extends StatefulWidget {
  const ManagePaymentsScreen({super.key});

  @override
  State<ManagePaymentsScreen> createState() => _ManagePaymentsScreenState();
}

class _ManagePaymentsScreenState extends State<ManagePaymentsScreen> {
  final _storage = const FlutterSecureStorage();
  List subscriptions = [];
  List accounts = [];
  List plans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // نظام الفتح الذكي للتطبيقات البنكية (لا يتغير، لضمان وصول الأدمن للتطبيقات)
  Future<void> _launchBankApp(String techName, String currentLang) async {
    final Map<String, Map<String, String>> bankConfig = {
      'bankily': {'scheme': 'bankily://', 'package': 'com.bim.bankily'},
      'masrvi': {'scheme': 'masrvi://', 'package': 'com.mauripost.masrvi'},
      'sedad': {'scheme': 'sedad://', 'package': 'com.bms.sedad'},
    };

    final String key = techName.toLowerCase();
    if (!bankConfig.containsKey(key)) {
      String msg = currentLang == 'ar'
          ? "هذا الحساب لا يدعم الفتح التلقائي"
          : "Ce compte ne supporte pas l'ouverture automatique";
      _showSnackBar(msg);
      return;
    }

    final String package = bankConfig[key]!['package']!;
    final String intentUri = "intent:#Intent;package=$package;end";

    try {
      bool launched = await launchUrl(Uri.parse(intentUri), mode: LaunchMode.externalApplication);
      if (!launched) {
        String msg = currentLang == 'ar' ? "التطبيق غير مثبت على جهازك" : "Application non installée";
        _showSnackBar(msg);
      }
    } catch (e) {
      String msg = currentLang == 'ar' ? "خطأ أثناء فتح التطبيق" : "Erreur d'ouverture";
      _showSnackBar(msg);
    }
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final config = {'Authorization': 'Bearer $token'};

      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/subscriptions/pending/'), headers: config),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/payment-methods/'), headers: config),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/subscription-plans/'), headers: config),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].statusCode == 200) subscriptions = json.decode(utf8.decode(results[0].bodyBytes));
          if (results[1].statusCode == 200) accounts = json.decode(utf8.decode(results[1].bodyBytes));
          if (results[2].statusCode == 200) plans = json.decode(utf8.decode(results[2].bodyBytes));
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  // تفعيل أو رفض الاشتراك (يدوياً من قبل الأدمن)
  Future<void> handleVerify(int id, String status, String currentLang) async {
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/subscriptions/verify/$id/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        String msg = currentLang == 'ar'
            ? "تم تحديث الحالة: ${status == 'ACTIVE' ? 'تفعيل' : 'رفض'}"
            : "Statut mis à jour: $status";
        _showSnackBar(msg);
        fetchData();
      }
    } catch (e) {
      String msg = currentLang == 'ar' ? "حدث خطأ أثناء التأكيد" : "Erreur de validation";
      _showSnackBar(msg);
    }
  }

  Future<void> handleDelete(String endpoint, int id, String currentLang) async {
    String confirmMsg = currentLang == 'ar' ? "هل تريد حذف هذا العنصر؟" : "Supprimer cet élément ?";
    bool confirm = await _showConfirmDialog(confirmMsg, currentLang);
    if (!confirm) return;
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/$endpoint/$id/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        String msg = currentLang == 'ar' ? "تم الحذف" : "Supprimé";
        _showSnackBar(msg);
        fetchData();
      }
    } catch (e) {
      String msg = currentLang == 'ar' ? "حدث خطأ أثناء الحذف" : "Erreur lors de la suppression";
      _showSnackBar(msg);
    }
  }

  // --- واجهة إضافة حساب استقبال جديد (مهمة جداً للـ B-Pay) ---
  void _showAddAccountDialog(String currentLang) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final holderController = TextEditingController(text: "Admin");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: Text(currentLang == 'ar' ? "حساب استقبال جديد" : "Nouveau Compte de Réception"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, currentLang == 'ar' ? "الاسم (مثال: Bankily)" : "Nom (ex: Bankily)", isDark),
              const SizedBox(height: 10),
              _buildTextField(numberController, currentLang == 'ar' ? "كود التاجر / رقم الحساب" : "Code Commerçant / Numéro", isDark, isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(holderController, currentLang == 'ar' ? "اسم صاحب الحساب" : "Titulaire", isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(currentLang == 'ar' ? "إلغاء" : "Annuler")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
            onPressed: () async {
              String nameInput = nameController.text.trim().toLowerCase();
              String techName = 'other';
              // تحديد الاسم التقني لربطه بنظام B-Pay في الـ Backend
              if (nameInput.contains('bankily')) techName = 'bankily';
              else if (nameInput.contains('masrvi')) techName = 'masrvi';
              else if (nameInput.contains('sedad')) techName = 'sedad';

              await _submitNewItem('payment-methods/', {
                'provider_name': nameController.text.trim(),
                'account_number': numberController.text.trim(),
                'technical_name': techName,
                'account_holder': holderController.text.trim(),
                'is_active': true,
              }, currentLang);
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(currentLang == 'ar' ? "حفظ" : "Enregistrer", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPlanDialog(String currentLang) {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final offersController = TextEditingController();
    final durationController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: Text(currentLang == 'ar' ? "باقة اشتراك جديدة" : "Nouveau Plan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(titleController, currentLang == 'ar' ? "العنوان" : "Titre", isDark),
            const SizedBox(height: 10),
            _buildTextField(priceController, currentLang == 'ar' ? "السعر (أوقية)" : "Prix (MRU)", isDark, isNumber: true),
            const SizedBox(height: 10),
            _buildTextField(offersController, currentLang == 'ar' ? "عدد العروض المتاحة" : "Nombre d'offres", isDark, isNumber: true),
            const SizedBox(height: 10),
            _buildTextField(durationController, currentLang == 'ar' ? "المدة (بالأشهر)" : "Durée (Mois)", isDark, isNumber: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(currentLang == 'ar' ? "إغلاق" : "Fermer")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await _submitNewItem('subscription-plans/', {
                'title': titleController.text.trim(),
                'price': priceController.text.trim(),
                'offres_count': offersController.text.trim(),
                'duration_months': durationController.text.trim(),
              }, currentLang);
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(currentLang == 'ar' ? "إضافة" : "Créer", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNewItem(String endpoint, Map<String, dynamic> data, String currentLang) async {
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/$endpoint'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) {
        String msg = currentLang == 'ar' ? "تمت الإضافة بنجاح!" : "Ajouté !";
        _showSnackBar(msg);
        fetchData();
      }
    } catch (e) {
      String msg = currentLang == 'ar' ? "حدث خطأ ما" : "Erreur";
      _showSnackBar(msg);
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isDark, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLang == 'ar' ? "إدارة المالية" : "Gestion Finance"),
        actions: [
          IconButton(icon: const Icon(Icons.add_card, color: ApiConfig.kPrimary), onPressed: () => _showAddAccountDialog(currentLang)),
          IconButton(icon: const Icon(Icons.playlist_add, color: Colors.orange), onPressed: () => _showAddPlanDialog(currentLang)),
        ],
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader(Icons.account_balance, currentLang == 'ar' ? "حسابات الاستقبال" : "Comptes Réception", isDark),
                _buildAccountsList(theme, isDark, currentLang),
                const SizedBox(height: 20),
                _buildSectionHeader(Icons.list_alt, currentLang == 'ar' ? "باقات الاشتراك" : "Plans d'Abonnement", isDark),
                _buildPlansList(theme, isDark, currentLang),
                const SizedBox(height: 20),
                _buildSectionHeader(Icons.pending, currentLang == 'ar' ? "الطلبات قيد الانتظار" : "Demandes en attente", isDark),
                _buildVerificationList(theme, isDark, currentLang),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [Icon(icon, color: ApiConfig.kPrimary), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildAccountsList(ThemeData theme, bool isDark, String currentLang) {
    return Column(children: accounts.map((acc) => Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance),
        title: Text(acc['provider_name']),
        subtitle: Text(acc['account_number']),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => handleDelete("payment-methods", acc['id'], currentLang)),
        onTap: () => _launchBankApp(acc['technical_name'], currentLang),
      ))).toList());
  }

  Widget _buildPlansList(ThemeData theme, bool isDark, String currentLang) {
    return Column(children: plans.map((plan) => Card(
      child: ListTile(
        title: Text(plan['title']),
        subtitle: Text("${plan['price']} ${currentLang == 'ar' ? 'أوقية' : 'MRU'}"),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => handleDelete("subscription-plans", plan['id'], currentLang)),
      ))).toList());
  }

  Widget _buildVerificationList(ThemeData theme, bool isDark, String currentLang) {
    if (subscriptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(currentLang == 'ar' ? "لا توجد طلبات معلقة" : "Aucune demande"),
      );
    }
    return Column(children: subscriptions.map((sub) => Card(
      child: Column(children: [
        ListTile(
          title: Text(sub['enterprise_name'] ?? (currentLang == 'ar' ? "منشأة" : "Entreprise")),
          subtitle: Text(
            currentLang == 'ar'
                ? "الباقة: ${sub['plan_title']} - الرمز: ${sub['transaction_ref']}"
                : "Plan: ${sub['plan_title']} - Réf: ${sub['transaction_ref']}"
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: () => handleVerify(sub['id'], 'REJECTED', currentLang),
            child: Text(currentLang == 'ar' ? "رفض" : "Rejeter", style: const TextStyle(color: Colors.red))
          ),
          ElevatedButton(
            onPressed: () => handleVerify(sub['id'], 'ACTIVE', currentLang),
            child: Text(currentLang == 'ar' ? "تفعيل" : "Valider")
          ),
        ])
      ]))).toList());
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _showConfirmDialog(String msg, String currentLang) async {
    return await showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E232D) : Colors.white,
      title: Text(currentLang == 'ar' ? "تأكيد" : "Confirmation"),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(currentLang == 'ar' ? "لا" : "Non")
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(currentLang == 'ar' ? "نعم" : "Oui")
        ),
      ]
    )) ?? false;
  }
}