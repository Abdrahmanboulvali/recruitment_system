import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضروري لعملية النسخ التلقائي
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // وحدات التحكم لنظام B-Pay
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // --- واجهة إدخال بيانات B-Pay الجديدة ---

  void _showBPayDialog(Map plan, Map account, String currentLang) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          currentLang == 'ar' ? "دفع عبر بي-باي (B-Pay)" : "Paiement B-Pay",
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${currentLang == 'ar' ? 'المبلغ: ' : 'Montant: '}${plan['price']} MRU",
              style: const TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: currentLang == 'ar' ? "رقم بنكيلي" : "Numéro Bankily",
                hintText: currentLang == 'ar' ? "مثال: 4xxxxxxx" : "Ex: 4xxxxxxx",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: currentLang == 'ar' ? "رمز السري لـ B-Pay" : "Passcode B-Pay",
                hintText: currentLang == 'ar' ? "رمز مكون من 4-6 أرقام" : "Code à 4-6 chiffres",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(currentLang == 'ar' ? "إلغاء" : "Annuler", style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
            onPressed: () {
              Navigator.pop(ctx);
              _handleBPaySubmit(plan['id'], account['id'], currentLang);
            },
            child: Text(currentLang == 'ar' ? "تأكيد" : "Confirmer", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBPaySubmit(int planId, int methodId, String currentLang) async {
    if (_phoneController.text.isEmpty || _passcodeController.text.isEmpty) {
      _showSnackBar(currentLang == 'ar' ? "يرجى ملء جميع الحقول" : "Veuillez remplir tous les champs");
      return;
    }

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
          'payment_method': methodId,
          'is_bpay': true, // إشارة للباكيند لمعالجة الطلب تلقائياً
          'client_phone': _phoneController.text.trim(),
          'passcode': _passcodeController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _showSnackBar(currentLang == 'ar' ? "تم تفعيل الاشتراك بنجاح!" : "Abonnement activé avec succès !");

        _phoneController.clear();
        _passcodeController.clear();

        fetchData();
      } else {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _showSnackBar(data['detail'] ?? (currentLang == 'ar' ? "فشلت عملية الدفع" : "Erreur de paiement"));
      }
    } catch (e) {
      _showSnackBar(currentLang == 'ar' ? "خطأ في الاتصال بالشبكة" : "Erreur de connexion");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --- واجهة تأكيد فتح تطبيقات البنوك الأخرى ---

  Future<void> _confirmAndOpenBank(String techName, String receiver, String amount, String ref, String currentLang) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "${currentLang == 'ar' ? 'الدفع عبر ' : 'Paiement via '}$techName",
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLang == 'ar'
                  ? "هل تريد فتح تطبيق $techName لدفع $amount أوقية جديدة؟"
                  : "Voulez-vous ouvrir $techName pour payer $amount MRU ?",
            ),
            const SizedBox(height: 10),
            Text(
              "${currentLang == 'ar' ? 'الرقم المرجعي: ' : 'Référence: '}$ref",
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(currentLang == 'ar' ? "إلغاء" : "Annuler", style: const TextStyle(color: Colors.red))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _openBankApp(techName, receiver, amount, ref, currentLang);
            },
            child: Text(currentLang == 'ar' ? "فتح" : "Ouvrir", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openBankApp(String techName, String accountNumber, String amount, String reference, String currentLang) async {
    final String key = techName.toLowerCase().trim();
    String package = key.contains('bankily') ? "com.bim.bankily" :
                     key.contains('masrvi') ? "com.mauripost.masrvi" : "com.bms.sedad";

    try {
      await Clipboard.setData(ClipboardData(text: reference));
      final String intentUrl = "intent:#Intent;package=$package;end";
      bool launched = await launchUrl(Uri.parse(intentUrl), mode: LaunchMode.externalApplication);

      if (launched) {
        _showSnackBar(currentLang == 'ar' ? "تم فتح التطبيق ونسخ الرقم المرجعي للعملية!" : "Application ouverte. Référence copiée !");
      } else {
        _showSnackBar(currentLang == 'ar' ? "لم يتم العثور على التطبيق المثبت." : "Application non trouvée.");
      }
    } catch (e) {
      _showSnackBar(currentLang == 'ar' ? "يرجى فتح التطبيق يدوياً." : "Veuillez ouvrir l'application manuellement.");
    }
  }

  // --- معالجة الدفع التلقائي للبنوك الأخرى ---

  Future<void> _handleAutoPay(int planId, Map paymentMethod, String currentLang) async {
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'plan': planId, 'payment_method': paymentMethod['id']}),
      );

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        _confirmAndOpenBank(
          responseData['bank_technical_name']?.toString() ?? "",
          responseData['receiver_number']?.toString() ?? "",
          responseData['amount']?.toString() ?? "0",
          responseData['transaction_ref']?.toString() ?? "",
          currentLang
        );
        fetchData();
      } else {
        _showSnackBar(responseData['detail'] ?? (currentLang == 'ar' ? "حدث خطأ" : "Erreur"));
      }
    } catch (e) {
      _showSnackBar(currentLang == 'ar' ? "خطأ في الاتصال" : "Erreur de connexion");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --- جلب البيانات وبناء الواجهة ---

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/subscription-plans/'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/payment-methods/'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/'), headers: headers),
      ]);

      if (mounted) {
        setState(() {
          plans = json.decode(utf8.decode(results[0].bodyBytes));
          accounts = json.decode(utf8.decode(results[1].bodyBytes));
          List allSubs = json.decode(utf8.decode(results[2].bodyBytes));
          activeSubscription = allSubs.cast<Map<String, dynamic>?>().firstWhere((req) => req?['status'] == 'ACTIVE', orElse: () => null);
          pendingRequests = allSubs.where((req) => req['status'] == 'PENDING').toList();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          currentLang == 'ar' ? "الاشتراكات وباقات الدفع" : "Abonnements",
          style: const TextStyle(fontWeight: FontWeight.bold)
        )
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: ApiConfig.kPrimary))
          : RefreshIndicator(
              onRefresh: fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (activeSubscription != null) _buildActiveSubCard(currentLang),
                  if (accounts.isNotEmpty) _buildPaymentMethodsGrid(currentLang),
                  if (pendingRequests.isNotEmpty) _buildPendingSection(currentLang),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      currentLang == 'ar' ? "الباقات المتاحة" : "Forfaits disponibles",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...plans.map((plan) => _buildPlanCard(plan, theme, currentLang)).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentMethodsGrid(String currentLang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(currentLang == 'ar' ? "وسائل الدفع" : "Moyens de paiement", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: ApiConfig.kPrimary.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet, color: ApiConfig.kPrimary),
                    const SizedBox(height: 5),
                    Text(acc['provider_name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(acc['account_number'] ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showPaymentSelection(Map plan, ThemeData theme, String currentLang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLang == 'ar' ? "اختر طريقة الدفع" : "Mode de paiement",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 15),
            ...accounts.map((acc) {
              final String techName = (acc['technical_name'] ?? '').toString().toLowerCase();
              final String providerName = (acc['provider_name'] ?? '').toString().toLowerCase();

              return ListTile(
                leading: const Icon(Icons.flash_on, color: Colors.orange),
                title: Text(currentLang == 'ar' ? "الدفع بواسطة ${acc['provider_name']}" : "Payer via ${acc['provider_name']}"),
                onTap: () {
                  Navigator.pop(context);
                  if (techName.contains('bankily') || techName.contains('bpay') || providerName.contains('bankily')) {
                    _showBPayDialog(plan, acc, currentLang);
                  } else {
                    _handleAutoPay(plan['id'], acc, currentLang);
                  }
                },
              );
            }).toList(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(currentLang == 'ar' ? "طريقة يدوية (رفع الإيصال)" : "Méthode manuelle (Upload)"),
              onTap: () {
                Navigator.pop(context);
                _showManualUploadSheet(plan, theme, currentLang);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map plan, ThemeData theme, String currentLang) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan['title'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: ApiConfig.kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text("${plan['price']} MRU", style: const TextStyle(fontWeight: FontWeight.bold, color: ApiConfig.kPrimary)),
                )
              ],
            ),
            const SizedBox(height: 15),

            // --- التعديل المطبق: استخدام المفاتيح الصحيحة كما في الويب ---
            Row(
              children: [
                Icon(Icons.layers_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Text("${plan['offres_count'] ?? 0} ${currentLang == 'ar' ? 'عرض' : 'Offres'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(width: 20),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Text("${plan['duration_months'] ?? 0} ${currentLang == 'ar' ? 'شهر' : 'mois'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(height: 15),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 45)),
              onPressed: () => _showPaymentSelection(plan, theme, currentLang),
              child: Text(currentLang == 'ar' ? "اشترك الآن" : "S'abonner", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubCard(String currentLang) {
    final details = activeSubscription?['plan_details'];
    final String planTitle = details?['title'] ?? activeSubscription?['plan']?.toString() ?? (currentLang == 'ar' ? "اشتراك نشط" : "Abonnement Actif");

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentLang == 'ar' ? "اشتراكك نشط" : "Abonnement actif", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(planTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPendingSection(String currentLang) {
    return Column(
      children: pendingRequests.map((req) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "${currentLang == 'ar' ? 'في انتظار التأكيد للرقم: ' : 'Attente confirmation: '}${req['transaction_ref']}",
                style: const TextStyle(color: Colors.orange, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
          ],
        ),
      )).toList(),
    );
  }

  void _showManualUploadSheet(Map plan, ThemeData theme, String currentLang) {
    _receiptFile = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLang == 'ar' ? "إرفاق إثبات الدفع" : "Preuve de paiement",
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) setModalState(() => _receiptFile = File(picked.path));
                },
                child: Container(
                  height: 120, width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15)),
                  child: _receiptFile == null ? const Icon(Icons.add_a_photo) : Image.file(_receiptFile!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, minimumSize: const Size(double.infinity, 45)),
                onPressed: () {
                  handleManualUpload(plan['id'], currentLang);
                  Navigator.pop(context);
                },
                child: Text(currentLang == 'ar' ? "إرسال الإيصال" : "Envoyer", style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleManualUpload(int planId, String currentLang) async {
    if (_receiptFile == null) return;
    setState(() => loading = true);
    try {
      String? token = await _storage.read(key: 'access');
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['plan'] = planId.toString();
      request.files.add(await http.MultipartFile.fromPath('payment_receipt', _receiptFile!.path));
      var res = await request.send();
      if (res.statusCode == 201) {
        fetchData();
        _showSnackBar(currentLang == 'ar' ? "تم إرسال إيصال الدفع بنجاح!" : "Reçu envoyé !");
      }
    } catch (e) {
      _showSnackBar(currentLang == 'ar' ? "حدث خطأ أثناء إرسال الإيصال" : "Erreur lors de l'envoi");
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}