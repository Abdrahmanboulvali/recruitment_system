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

  Future<void> handleApprove(int? userId) async {
    if (userId == null) return;
    bool confirm = await _showConfirmDialog("Approuver cette entité ?");
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/activate/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _showSnackBar("Entité activée !");
        fetchEnterprises();
      }
    } catch (e) {
      _showSnackBar("Erreur lors de l'activation");
    }
  }

  Future<void> handleDeactivate(int? userId) async {
    if (userId == null) return;
    bool confirm = await _showConfirmDialog("Désactiver cette entité ?");
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/deactivate/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _showSnackBar("Entité désactivée !");
        fetchEnterprises();
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la désactivation");
    }
  }

  Future<void> handleDelete(int enterpriseId) async {
    bool confirm = await _showConfirmDialog("Voulez-vous vraiment supprimer définitivement cette entreprise ?");
    if (!confirm) return;

    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/enterprises/$enterpriseId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _showSnackBar("Entreprise supprimée !");
        fetchEnterprises();
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la suppression");
    }
  }

  Future<void> openPreview(String? fileUrl) async {
    if (fileUrl == null) return;
    final fullUrl = fileUrl.startsWith('http') ? fileUrl : "${ApiConfig.baseUrl}$fileUrl";
    final uri = Uri.parse(fullUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar("Impossible d'ouvrir le document");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Gestion des Entités",
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : _buildEnterprisesGrid(theme, isDark),
    );
  }

  Widget _buildEnterprisesGrid(ThemeData theme, bool isDark) {
    if (enterprises.isEmpty) {
      return Center(child: Text("Aucune entreprise trouvée",
        style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)));
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
                      isApproved ? "● ACTIVE" : "● EN ATTENTE",
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
              Text(ent['name'] ?? "Nom non défini",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Text(ent['description'] ?? 'Aucune description',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
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
                  "👤 Manager: ${ent['dg_name'] ?? 'Non assigné'}",
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
                    onPressed: () => openPreview(ent['verification_document']),
                    icon: const Icon(Icons.search, color: Colors.amber, size: 18),
                    label: const Text("Voir le document", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                const Text("⚠️ Document manquant", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              if (isApproved)
                _buildActionButton("Désactiver l'entité", Colors.orange, () => handleDeactivate(ent['owner_id']))
              else
                _buildActionButton("Approuver l'entité", Colors.green, () => handleApprove(ent['owner_id'])),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: () => handleDelete(ent['id']),
                child: const Text(
                  "Supprimer l'entreprise",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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

  Future<bool> _showConfirmDialog(String message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E232D) : Colors.white,
        title: const Text("Confirmation"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text("Annuler", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmer", style: TextStyle(color: ApiConfig.kPrimary))),
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