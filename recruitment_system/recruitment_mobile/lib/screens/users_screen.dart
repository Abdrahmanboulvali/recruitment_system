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

  // حالات الفلترة (Filters)
  String searchTerm = "";
  String roleFilter = "ALL";
  String statusFilter = "ALL";

  // في الويب تم ضبطها كـ true، سنفعل المثل هنا
  bool isSuperAdmin = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(utf8.decode(response.bodyBytes));
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggleUserStatus(Map user) async {
    final String action = user['is_active'] ? "désactiver" : "réactiver";

    // حوار تأكيد كما في الويب (confirm)
    bool confirm = await _showConfirmDialog(action, user['username']);
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
        fetchUsers(); // إعادة جلب البيانات لتحديث الواجهة
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la modification")),
      );
    }
  }

  // منطق الفلترة المتطابق مع نسخة الويب تماماً
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
    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      appBar: AppBar(
        title: const Text("Gestion Utilisateurs", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(), // شريط البحث والفلترة
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
                : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // خانة البحث
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Rechercher par nom ou email...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white24),
              filled: true,
              fillColor: ApiConfig.kBgCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => searchTerm = val),
          ),
          const SizedBox(height: 10),
          // فلاتر الاختيار (Dropdowns)
          Row(
            children: [
              Expanded(child: _buildDropdown("Rôle", roleFilter, ["ALL", "ADMIN", "CANDIDAT", "DG", "SUPER_ADMIN"], (val) => setState(() => roleFilter = val!))),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown("Statut", statusFilter, ["ALL", "ACTIVE", "INACTIVE"], (val) => setState(() => statusFilter = val!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: ApiConfig.kBgCard, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: ApiConfig.kBgCard,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (filteredUsers.isEmpty) {
      return const Center(child: Text("Aucun utilisateur trouvé", style: TextStyle(color: Colors.white24)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map user) {
    bool isActive = user['is_active'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user['email'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              _buildRoleBadge(user['role']),
            ],
          ),
          const Divider(height: 25, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isSuperAdmin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Entreprise", style: TextStyle(color: Colors.white24, fontSize: 10)),
                    Text(user['enterprise_nom'] ?? "Système", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusText(isActive),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => toggleUserStatus(user),
                    child: Text(
                      isActive ? "Désactiver" : "Réactiver",
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

  Widget _buildStatusText(bool isActive) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? Colors.green : Colors.grey)),
        const SizedBox(width: 5),
        Text(isActive ? "Actif" : "Inactif", style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<bool> _showConfirmDialog(String action, String username) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ApiConfig.kBgCard,
        title: const Text("Confirmation"),
        content: Text("Voulez-vous vraiment $action le compte de $username ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action.toUpperCase(), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;
  }
}