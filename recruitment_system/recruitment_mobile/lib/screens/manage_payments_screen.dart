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
      debugPrint("Error fetching finance data: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> handleVerify(int id, String status) async {
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/subscriptions/verify/$id/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Statut mis à jour : $status");
        fetchData();
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la validation");
    }
  }

  Future<void> handleDelete(String endpoint, int id) async {
    bool confirm = await _showConfirmDialog("Supprimer cet élément ?");
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/$endpoint/$id/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        fetchData();
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la suppression");
    }
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: Text("Nouveau Compte", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, "Nom de la Banque", isDark),
            const SizedBox(height: 10),
            _buildTextField(numberController, "Numéro de Compte", isDark, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Annuler", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              await _submitNewItem('payment-methods/', {
                'provider_name': nameController.text,
                'account_number': numberController.text,
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showAddPlanDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final offersController = TextEditingController();
    final durationController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: Text("Créer un Plan", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, "Titre", isDark),
              const SizedBox(height: 10),
              _buildTextField(priceController, "Prix (MRU)", isDark, isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(offersController, "Nombre d'offres", isDark, isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(durationController, "Durée (Mois)", isDark, isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Fermer", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              await _submitNewItem('subscription-plans/', {
                'title': titleController.text,
                'price': priceController.text,
                'offres_count': offersController.text,
                'duration_months': durationController.text,
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Activer"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNewItem(String endpoint, Map<String, dynamic> data) async {
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar("Ajouté avec succès");
        fetchData();
      } else {
        _showSnackBar("Erreur lors de l'ajout");
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion");
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isDark, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 14),
        filled: true,
        fillColor: isDark ? Colors.black12 : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Administration Financière", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card, color: ApiConfig.kPrimary),
            onPressed: () => _showAddAccountDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.orange),
            onPressed: () => _showAddPlanDialog(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : RefreshIndicator(
              onRefresh: fetchData,
              color: ApiConfig.kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(Icons.credit_card, "Comptes de Réception", isDark),
                  _buildAccountsList(theme, isDark),
                  const SizedBox(height: 25),
                  _buildSectionHeader(Icons.layers, "Packs d'Abonnement", isDark),
                  _buildPlansList(theme, isDark),
                  const SizedBox(height: 25),
                  _buildSectionHeader(Icons.verified_user, "Vérification des reçus", isDark),
                  _buildVerificationList(theme, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white24 : Colors.black26, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAccountsList(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final acc = accounts[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: ApiConfig.kPrimary, child: Icon(Icons.attach_money, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(acc['provider_name'], style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                      Text(acc['account_number'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => handleDelete("payment-methods", acc['id'])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlansList(ThemeData theme, bool isDark) {
    return Column(
      children: plans.map((plan) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
        ),
        child: ListTile(
          leading: const Icon(Icons.card_membership, color: Colors.orange),
          title: Text(plan['title'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text("${plan['price']} MRU / ${plan['duration_months']} Mois", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
          trailing: IconButton(icon: Icon(Icons.delete_sweep, color: isDark ? Colors.white24 : Colors.black26), onPressed: () => handleDelete("subscription-plans", plan['id'])),
        ),
      )).toList(),
    );
  }

  Widget _buildVerificationList(ThemeData theme, bool isDark) {
    return Column(
      children: subscriptions.map((sub) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub['enterprise_name'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: ApiConfig.kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text(sub['plan_title'], style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _showReceiptPreview(sub['payment_receipt']),
              icon: const Icon(Icons.image, size: 16, color: Colors.amber),
              label: const Text("Reçu", style: TextStyle(color: Colors.amber, fontSize: 12)),
            ),
            IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => handleVerify(sub['id'], 'ACTIVE')),
            IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: () => handleVerify(sub['id'], 'REJECTED')),
          ],
        ),
      )).toList(),
    );
  }

  void _showReceiptPreview(String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network("${ApiConfig.baseUrl}$url",
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 100, color: isDark ? Colors.white24 : Colors.black26),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Fermer")
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String msg) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: Text("Confirmation", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text(msg, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Non", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Oui", style: TextStyle(color: Colors.redAccent))),
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