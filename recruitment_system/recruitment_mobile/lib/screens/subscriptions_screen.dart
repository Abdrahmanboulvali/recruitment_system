import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // --- دوال الأتمتة الجديدة ---

  Future<void> _openBankApp(String techName, String accountNumber, String amount, String reference) async {
    String url = '';
    if (techName.toLowerCase().contains('bankily')) {
      url = "bankily://pay?to=$accountNumber&amount=$amount&note=$reference";
    } else if (techName.toLowerCase().contains('masrvi')) {
      url = "masrvi://pay?to=$accountNumber&amount=$amount&note=$reference";
    }

    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar("تطبيق البنك غير مثبت أو لا يدعم الربط المباشر");
    }
  }

  Future<void> _handleAutoPay(int planId, Map paymentMethod) async {
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'plan': planId,
          'payment_method': paymentMethod['id'],
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final String ref = data['transaction_ref'];
        final String amount = data['amount'].toString();
        final String receiver = data['receiver_number'];
        final String bankTechName = data['bank_technical_name'];

        await _openBankApp(bankTechName, receiver, amount, ref);

        fetchData();
        _showSnackBar("Redirection vers l'application bancaire...");
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion");
    } finally {
      setState(() => loading = false);
    }
  }

  // --- جلب البيانات ---

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
      if (mounted) setState(() => loading = false);
    }
  }

  // --- واجهة العرض الرئيسية ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Abonnements",
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : RefreshIndicator(
              onRefresh: fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text("Payez instantanément et activez votre pack automatiquement.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 25),
                  if (activeSubscription != null) _buildActiveSubCard(isDark),
                  if (pendingRequests.isNotEmpty) _buildPendingSection(isDark),

                  // تم حذف _buildPaymentMethods من هنا لتنظيف الواجهة

                  const SizedBox(height: 10),
                  ...plans.map((plan) => _buildPlanCard(plan, theme, isDark)).toList(),
                ],
              ),
            ),
    );
  }

  // --- نافذة اختيار الدفع الذكية ---

  void _showPaymentSelection(Map plan, ThemeData theme, bool isDark) {
    // أتمتة: إذا كان هناك حساب بنكي واحد فقط، ابدأ الدفع فوراً
    if (accounts.length == 1) {
      _handleAutoPay(plan['id'], accounts[0]);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mode de paiement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...accounts.map((acc) => ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.orange),
              title: Text("Payer via ${acc['provider_name']}"),
              subtitle: const Text("Paiement automatique sécurisé"),
              onTap: () {
                Navigator.pop(context);
                _handleAutoPay(plan['id'], acc);
              },
            )).toList(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_edu, color: Colors.grey),
              title: const Text("Méthode manuelle (Upload)"),
              onTap: () {
                Navigator.pop(context);
                _showManualUploadSheet(plan, theme, isDark);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- بقية الـ Widgets المساعدة (نفس تصميمك الأصلي) ---

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
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 10),
            Text("Abonnement Actif", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          _rowInfo("Pack:", details?['title']?.toString() ?? "N/A", isDark),
          _rowInfo("Usage:", "${details?['current_usage'] ?? 0} / ${details?['offres_count'] ?? 0}", isDark),
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
            Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text("En attente de confirmation", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ]),
          ...pendingRequests.map((req) => ListTile(
            dense: true,
            title: Text("Ref: ${req['transaction_ref']}", style: const TextStyle(fontSize: 12)),
            trailing: const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map plan, ThemeData theme, bool isDark) {
    bool isCurrent = activeSubscription != null && activeSubscription!['plan'] == plan['id'];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCurrent ? Colors.green : ApiConfig.kPrimary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(plan['title']?.toString() ?? "", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Text("${plan['price']} MRU", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ApiConfig.kPrimary)),
          const Divider(height: 25),
          _featureRow("${plan['offres_count']} Offres", isDark),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ApiConfig.kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _showPaymentSelection(plan, theme, isDark),
              child: const Text("S'abonner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- الدوال اليدوية المتبقية ---

  void _showManualUploadSheet(Map plan, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Preuve de paiement"),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => _pickImage(setModalState),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                  child: _receiptFile == null ? const Icon(Icons.add_a_photo) : Image.file(_receiptFile!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(onPressed: () { handleManualUpload(plan['id']); Navigator.pop(context); }, child: const Text("Envoyer")),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleManualUpload(int planId) async {
    if (_receiptFile == null) return;
    try {
      String? token = await _storage.read(key: 'access');
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['plan'] = planId.toString();
      request.files.add(await http.MultipartFile.fromPath('payment_receipt', _receiptFile!.path));
      var res = await request.send();
      if (res.statusCode == 201) { fetchData(); _showSnackBar("Reçu envoyé !"); }
    } catch (e) { _showSnackBar("Erreur"); }
  }

  Future<void> _pickImage(StateSetter setStateModal) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setStateModal(() => _receiptFile = File(pickedFile.path));
  }

  Widget _rowInfo(String label, String value, bool isDark) {
    return Row(children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
      const SizedBox(width: 5),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }

  Widget _featureRow(String text, bool isDark) {
    return Row(children: [
      const Icon(Icons.check, color: Colors.green, size: 16),
      const SizedBox(width: 10),
      Text(text, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
    ]);
  }

  void _showSnackBar(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}