import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _storage = const FlutterSecureStorage();
  List users = [];
  bool loading = true;

  String searchTerm = "";
  String roleFilter = "ALL";
  String statusFilter = "ALL";

  bool isSuperAdmin = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            users = json.decode(utf8.decode(response.bodyBytes));
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggleUserStatus(Map user) async {
    final currentLang = Localizations.localeOf(context).languageCode;

    // إعداد نص الإجراء ديناميكياً للغة العربية والفرنسية لتمريره لحوار التأكيد
    String action;
    if (currentLang == 'ar') {
      action = user['is_active'] ? "تعطيل" : "إعادة تفعيل";
    } else {
      action = user['is_active'] ? "désactiver" : "réactiver";
    }

    bool confirm = await _showConfirmDialog(action, user['username'], currentLang);
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/users/${user['id']}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_active': !user['is_active']}),
      );

      if (response.statusCode == 200) {
        fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentLang == 'ar' ? "حدث خطأ أثناء التعديل" : "Erreur lors de la modification")
          ),
        );
      }
    }
  }

  List get filteredUsers {
    return users.where((user) {
      final matchesSearch = user['username'].toString().toLowerCase().contains(searchTerm.toLowerCase()) ||
          user['email'].toString().toLowerCase().contains(searchTerm.toLowerCase());

      final matchesRole = roleFilter == "ALL" || user['role'] == roleFilter;

      final matchesStatus = statusFilter == "ALL" ||
          (statusFilter == "ACTIVE" && user['is_active']) ||
          (statusFilter == "INACTIVE" && !user['is_active']);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          currentLang == 'ar' ? "إدارة المستخدمين" : "Gestion Utilisateurs",
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(theme, isDark, currentLang),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
                : _buildUsersList(isDark, currentLang),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme, bool isDark, String currentLang) {
    // قائمة الخيارات المترجمة للأدوار والحالات مع الحفاظ على القيم الأصلية (Keys) ثابتة لتصفية المصفوفة
    final Map<String, String> roleLabels = currentLang == 'ar'
      ? {"ALL": "كل الأدوار", "ADMIN": "مشرف", "CANDIDAT": "مترشح", "DG": "مؤسسة", "SUPER_ADMIN": "مدير عام"}
      : {"ALL": "Tous les rôles", "ADMIN": "ADMIN", "CANDIDAT": "CANDIDAT", "DG": "DG", "SUPER_ADMIN": "SUPER_ADMIN"};

    final Map<String, String> statusLabels = currentLang == 'ar'
      ? {"ALL": "كل الحالات", "ACTIVE": "نشط", "INACTIVE": "غير نشط"}
      : {"ALL": "Tous les statuts", "ACTIVE": "ACTIVE", "INACTIVE": "INACTIVE"};

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: currentLang == 'ar' ? "ابحث بالاسم أو البريد الإلكتروني..." : "Rechercher par nom ou email...",
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white24 : Colors.black38),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => searchTerm = val),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  theme,
                  isDark,
                  currentLang == 'ar' ? "الرتبة" : "Rôle",
                  roleFilter,
                  ["ALL", "ADMIN", "CANDIDAT", "DG", "SUPER_ADMIN"],
                  roleLabels,
                  (val) => setState(() => roleFilter = val!)
                )
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  theme,
                  isDark,
                  currentLang == 'ar' ? "الحالة" : "Statut",
                  statusFilter,
                  ["ALL", "ACTIVE", "INACTIVE"],
                  statusLabels,
                  (val) => setState(() => statusFilter = val!)
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(ThemeData theme, bool isDark, String label, String value, List<String> items, Map<String, String> labels, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: theme.cardColor,
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(labels[i] ?? i, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12))
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUsersList(bool isDark, String currentLang) {
    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          currentLang == 'ar' ? "لم يتم العثور على أي مستخدم" : "Aucun utilisateur trouvé",
          style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)
        )
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user, isDark, currentLang);
      },
    );
  }

  Widget _buildUserCard(Map user, bool isDark, String currentLang) {
    bool isActive = user['is_active'] ?? false;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: ApiConfig.kPrimary,
                child: Text(user['username'][0].toString().toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['username'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                    Text(user['email'], style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              _buildRoleBadge(user['role']),
            ],
          ),
          Divider(height: 25, color: isDark ? Colors.white10 : Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isSuperAdmin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLang == 'ar' ? "المؤسسة / الشركة" : "Entreprise",
                      style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 10)
                    ),
                    Text(
                      user['enterprise_nom'] ?? (currentLang == 'ar' ? "النظام" : "Système"),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusText(isActive, currentLang),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => toggleUserStatus(user),
                    child: Text(
                      isActive
                          ? (currentLang == 'ar' ? "تعطيل الحساب" : "Désactiver")
                          : (currentLang == 'ar' ? "إعادة تفعيل" : "Réactiver"),
                      style: TextStyle(
                        color: isActive ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String? role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: ApiConfig.kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(role ?? "N/A", style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusText(bool isActive, String currentLang) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? Colors.green : Colors.grey)),
        const SizedBox(width: 5),
        Text(
          isActive
              ? (currentLang == 'ar' ? "نشط" : "Actif")
              : (currentLang == 'ar' ? "غير نشط" : "Inactif"),
          style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Future<bool> _showConfirmDialog(String action, String username, String currentLang) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: Text(currentLang == 'ar' ? "تأكيد الإجراء" : "Confirmation"),
        content: Text(
          currentLang == 'ar'
              ? "هل أنت متأكد حقاً من أنك تريد $action حساب المستخدم $username؟"
              : "Voulez-vous vraiment $action le compte de $username ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              currentLang == 'ar' ? "إلغاء" : "Annuler",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)
            )
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action.toUpperCase(),
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
            )
          ),
        ],
      ),
    ) ?? false;
  }
}