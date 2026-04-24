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
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final config = {'Authorization': 'Bearer $token'};

      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/subscriptions/pending/'), headers: config),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/payment-methods/'), headers: config),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/subscription-plans/'), headers: config),
      ]);

      setState(() {
        if (results[0].statusCode == 200) subscriptions = json.decode(utf8.decode(results[0].bodyBytes));
        if (results[1].statusCode == 200) accounts = json.decode(utf8.decode(results[1].bodyBytes));
        if (results[2].statusCode == 200) plans = json.decode(utf8.decode(results[2].bodyBytes));
        loading = false;
      });
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

  // --- دالات النوافذ المنبثقة الجديدة ---

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ApiConfig.kBgCard,
        title: const Text("Nouveau Compte", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, "Nom de la Banque"),
            const SizedBox(height: 10),
            _buildTextField(numberController, "Numéro de Compte", isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ApiConfig.kBgCard,
        title: const Text("Créer un Plan", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, "Titre"),
              const SizedBox(height: 10),
              _buildTextField(priceController, "Prix (MRU)", isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(offersController, "Nombre d'offres", isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(durationController, "Durée (Mois)", isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  // --- نهاية الدالات الجديدة ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      appBar: AppBar(
        title: const Text("Administration Financière"),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(Icons.credit_card, "Comptes de Réception"),
                  _buildAccountsList(),
                  const SizedBox(height: 25),
                  _buildSectionHeader(Icons.layers, "Packs d'Abonnement"),
                  _buildPlansList(),
                  const SizedBox(height: 25),
                  _buildSectionHeader(Icons.verified_user, "Vérification des reçus"),
                  _buildVerificationList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
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
              color: ApiConfig.kBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                      Text(acc['provider_name'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      Text(acc['account_number'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildPlansList() {
    return Column(
      children: plans.map((plan) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: ApiConfig.kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
        ),
        child: ListTile(
          leading: const Icon(Icons.card_membership, color: Colors.orange),
          title: Text(plan['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text("${plan['price']} MRU / ${plan['duration_months']} Mois", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.white24), onPressed: () => handleDelete("subscription-plans", plan['id'])),
        ),
      )).toList(),
    );
  }

  Widget _buildVerificationList() {
    return Column(
      children: subscriptions.map((sub) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: ApiConfig.kBgCard, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub['enterprise_name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white24),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String msg) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ApiConfig.kBgCard,
        title: const Text("Confirmation", style: TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Non")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Oui", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}