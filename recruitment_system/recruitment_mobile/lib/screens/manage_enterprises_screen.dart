import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_config.dart';

class ManageEnterprisesScreen extends StatefulWidget {
  const ManageEnterprisesScreen({super.key});

  @override
  State<ManageEnterprisesScreen> createState() => _ManageEnterprisesScreenState();
}

class _ManageEnterprisesScreenState extends State<ManageEnterprisesScreen> {
  final _storage = const FlutterSecureStorage();
  List enterprises = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchEnterprises();
  }

  Future<void> fetchEnterprises() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/enterprises/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            enterprises = json.decode(utf8.decode(response.bodyBytes));
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching enterprises: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> handleApprove(int? userId, String currentLang) async {
    if (userId == null) return;

    String confirmMsg = currentLang == 'ar'
        ? "هل توافق على تفعيل هذه المنشأة؟"
        : (currentLang == 'en' ? "Approve this entity?" : "Approuver cette entité ?");

    bool confirm = await _showConfirmDialog(confirmMsg, currentLang);
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/activate/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        String successMsg = currentLang == 'ar' ? "تم تفعيل المنشأة بنجاح!" : "Entité activée !";
        _showSnackBar(successMsg);
        fetchEnterprises();
      }
    } catch (e) {
      String errorMsg = currentLang == 'ar' ? "حدث خطأ أثناء التفعيل" : "Erreur lors de l'activation";
      _showSnackBar(errorMsg);
    }
  }

  Future<void> handleDeactivate(int? userId, String currentLang) async {
    if (userId == null) return;

    String confirmMsg = currentLang == 'ar'
        ? "هل تريد إلغاء تفعيل هذه المنشأة؟"
        : (currentLang == 'en' ? "Deactivate this entity?" : "Désactiver cette entité ?");

    bool confirm = await _showConfirmDialog(confirmMsg, currentLang);
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/deactivate/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        String successMsg = currentLang == 'ar' ? "تم إلغاء تفعيل المنشأة!" : "Entité désactivée !";
        _showSnackBar(successMsg);
        fetchEnterprises();
      }
    } catch (e) {
      String errorMsg = currentLang == 'ar' ? "حدث خطأ أثناء إلغاء التفعيل" : "Erreur lors de la désactivation";
      _showSnackBar(errorMsg);
    }
  }

  Future<void> handleDelete(int enterpriseId, String currentLang) async {
    String confirmMsg = currentLang == 'ar'
        ? "هل أنت متأكد تماماً من حذف هذه الشركة نهائياً؟"
        : (currentLang == 'en' ? "Are you sure you want to permanently delete this company?" : "Voulez-vous vraiment supprimer définitivement cette entreprise ?");

    bool confirm = await _showConfirmDialog(confirmMsg, currentLang);
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/enterprises/$enterpriseId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        String successMsg = currentLang == 'ar' ? "تم حذف الشركة بنجاح!" : "Entreprise supprimée !";
        _showSnackBar(successMsg);
        fetchEnterprises();
      }
    } catch (e) {
      String errorMsg = currentLang == 'ar' ? "حدث خطأ أثناء الحذف" : "Erreur lors de la suppression";
      _showSnackBar(errorMsg);
    }
  }

  Future<void> openPreview(String? fileUrl, String currentLang) async {
    if (fileUrl == null) return;
    final fullUrl = fileUrl.startsWith('http') ? fileUrl : "${ApiConfig.baseUrl}$fileUrl";
    final uri = Uri.parse(fullUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      String errorMsg = currentLang == 'ar' ? "تعذر فتح المستند" : "Impossible d'ouvrir le document";
      _showSnackBar(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          currentLang == 'ar' ? "إدارة المنشآت" : (currentLang == 'en' ? "Manage Enterprises" : "Gestion des Entités"),
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : _buildEnterprisesGrid(theme, isDark, currentLang),
    );
  }

  Widget _buildEnterprisesGrid(ThemeData theme, bool isDark, String currentLang) {
    if (enterprises.isEmpty) {
      return Center(
        child: Text(
          currentLang == 'ar' ? "لم يتم العثور على أي شركة" : (currentLang == 'en' ? "No company found" : "Aucune entreprise trouvée"),
          style: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enterprises.length,
      itemBuilder: (context, index) {
        final ent = enterprises[index];
        bool isApproved = ent['is_approved'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isApproved ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("🏢", style: TextStyle(fontSize: 30)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isApproved
                          ? (currentLang == 'ar' ? "● نشط" : "● ACTIVE")
                          : (currentLang == 'ar' ? "● قيد الانتظار" : "● EN ATTENTE"),
                      style: TextStyle(
                        color: isApproved ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                ent['name'] ?? (currentLang == 'ar' ? "اسم غير محدد" : "Nom non défini"),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                ent['description'] ?? (currentLang == 'ar' ? "لا يوجد وصف" : 'Aucune description'),
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ApiConfig.kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ApiConfig.kPrimary.withOpacity(0.2)),
                ),
                child: Text(
                  currentLang == 'ar'
                      ? "👤 المدير: ${ent['dg_name'] ?? 'لم يتم التعيين'}"
                      : "👤 Manager: ${ent['dg_name'] ?? 'Non assigné'}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              if (ent['verification_document'] != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => openPreview(ent['verification_document'], currentLang),
                    icon: const Icon(Icons.search, color: Colors.amber, size: 18),
                    label: Text(
                      currentLang == 'ar' ? "عرض المستند" : "Voir le document",
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Text(
                  currentLang == 'ar' ? "⚠️ مستند التحقق مفقود" : "⚠️ Document manquant",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),

              const SizedBox(height: 20),

              if (isApproved)
                _buildActionButton(
                  currentLang == 'ar' ? "إلغاء تفعيل المنشأة" : "Désactiver l'entité",
                  Colors.orange,
                  () => handleDeactivate(ent['owner_id'], currentLang),
                )
              else
                _buildActionButton(
                  currentLang == 'ar' ? "الموافقة على المنشأة" : "Approuver l'entité",
                  Colors.green,
                  () => handleApprove(ent['owner_id'], currentLang),
                ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: () => handleDelete(ent['id'], currentLang),
                child: Text(
                  currentLang == 'ar' ? "حذف الشركة نهائياً" : "Supprimer l'entreprise",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message, String currentLang) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: Text(currentLang == 'ar' ? "تأكيد" : "Confirmation"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              currentLang == 'ar' ? "إلغاء" : "Annuler",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              currentLang == 'ar' ? "تأكيد" : "Confirmer",
              style: const TextStyle(color: ApiConfig.kPrimary),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}