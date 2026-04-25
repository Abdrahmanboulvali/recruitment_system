import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../api_config.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _storage = const FlutterSecureStorage();
  List plans = [];
  List accounts = [];
  List pendingRequests = [];
  Map<String, dynamic>? activeSubscription;
  bool loading = true;
  File? _receiptFile;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    return double.tryParse(price.toString()) ?? 0.0;
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final config = {'Authorization': 'Bearer $token'};

      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/subscription-plans/'), headers: config),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/payment-methods/'), headers: config),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/'), headers: config),
      ]);

      if (mounted) {
        setState(() {
          plans = json.decode(utf8.decode(results[0].bodyBytes));
          accounts = json.decode(utf8.decode(results[1].bodyBytes));
          List allSubs = json.decode(utf8.decode(results[2].bodyBytes));

          activeSubscription = allSubs.cast<Map<String, dynamic>?>().firstWhere(
            (req) => req?['status'] == 'ACTIVE',
            orElse: () => null,
          );

          pendingRequests = allSubs.where((req) => req['status'] == 'PENDING').toList();
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickImage(StateSetter setStateModal) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setStateModal(() => _receiptFile = File(pickedFile.path));
    }
  }

  Future<void> handleSubscribe(int planId) async {
    if (_receiptFile == null) {
      _showSnackBar("Veuillez joindre le reçu de paiement");
      return;
    }

    try {
      String? token = await _storage.read(key: 'access');
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['plan'] = planId.toString();
      request.files.add(await http.MultipartFile.fromPath('payment_receipt', _receiptFile!.path));

      var response = await request.send();
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar("Demande envoyée avec succès !");
        _receiptFile = null;
        fetchData();
      }
    } catch (e) {
      _showSnackBar("Erreur lors de l'envoi");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Plans d'Abonnement",
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : RefreshIndicator(
              onRefresh: fetchData,
              color: ApiConfig.kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text("Gérez votre abonnement et découvrez nos solutions premium.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 25),
                  if (activeSubscription != null) _buildActiveSubCard(isDark),
                  if (pendingRequests.isNotEmpty) _buildPendingSection(isDark),
                  _buildPaymentMethods(theme, isDark),
                  const SizedBox(height: 20),
                  ...plans.map((plan) => _buildPlanCard(plan, theme, isDark)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveSubCard(bool isDark) {
    final details = activeSubscription?['plan_details'];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Votre abonnement est actif", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 15),
          _rowInfo("Pack:", details?['title']?.toString() ?? "N/A", isDark),
          _rowInfo("Utilisation:", "${details?['current_usage'] ?? 0} / ${details?['offres_count'] ?? 0} offres", isDark),
          _rowInfo("Expire le:", activeSubscription?['date_expiration'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(activeSubscription!['date_expiration']))
              : "N/A", isDark),
        ],
      ),
    );
  }

  Widget _buildPendingSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text("Demandes en attente", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          ...pendingRequests.map((req) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(req['plan_details']?['title']?.toString() ?? "Plan",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
            subtitle: const Text("Vérification du paiement...", style: TextStyle(color: Colors.orange, fontSize: 11)),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: accounts.map((acc) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: ApiConfig.kPrimary.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10)),
          child: Text("${acc['provider_name']}: ${acc['account_number']}",
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
        )).toList(),
      ),
    );
  }

  Widget _buildPlanCard(Map plan, ThemeData theme, bool isDark) {
    bool isCurrent = activeSubscription != null && activeSubscription!['plan'] == plan['id'];
    double priceValue = _parsePrice(plan['price']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCurrent ? Colors.green : ApiConfig.kPrimary, width: 2),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          if (isCurrent) const Align(alignment: Alignment.topRight, child: Badge(label: Text("ACTUEL"), backgroundColor: Colors.green)),
          Icon(priceValue > 1000 ? Icons.bolt : Icons.star, color: priceValue > 1000 ? Colors.orange : ApiConfig.kPrimary, size: 40),
          const SizedBox(height: 10),
          Text(plan['title']?.toString() ?? "",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 10),
          Text("${plan['price']} MRU", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ApiConfig.kPrimary)),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 30),
          _featureRow("${plan['offres_count']} Offres", isDark),
          _featureRow("Validité: ${plan['duration_months']} mois", isDark),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.green : ApiConfig.kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () => _showUploadSheet(plan, theme, isDark),
              child: Text(isCurrent ? "Renouveler" : "Choisir ce plan", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadSheet(Map plan, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Confirmer: ${plan['title']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _pickImage(setModalState),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.05),
                    border: Border.all(color: ApiConfig.kPrimary, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _receiptFile == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.upload_file, size: 40, color: ApiConfig.kPrimary),
                        Text("Cliquez pour joindre le reçu", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))
                      ])
                    : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_receiptFile!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  handleSubscribe(plan['id']);
                  Navigator.pop(context);
                },
                child: const Text("Envoyer la preuve", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
        const SizedBox(width: 5),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))
      ]),
    );
  }

  Widget _featureRow(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 18),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: isDark ? Colors.white : Colors.black87))
      ]),
    );
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}