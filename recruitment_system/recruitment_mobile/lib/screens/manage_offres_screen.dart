import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../api_config.dart';

class ManageOffresScreen extends StatefulWidget {
  const ManageOffresScreen({super.key});

  @override
  State<ManageOffresScreen> createState() => _ManageOffresScreenState();
}

class _ManageOffresScreenState extends State<ManageOffresScreen> {
  final _storage = const FlutterSecureStorage();
  List offres = [];
  bool isLoading = true;
  bool showForm = false;
  bool isEditing = false;
  int? currentId;

  // حالة الاشتراك
  Map<String, dynamic>? subscription;

  // Controllers للنموذج
  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _expController = TextEditingController(text: '0');
  final _skillsController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    await _fetchOffres();
    await _checkSubscription();
    setState(() => isLoading = false);
  }

  Future<void> _fetchOffres() async {
    final token = await _storage.read(key: 'access');
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/offres/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => offres = json.decode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint("Error fetching offres: $e");
    }
  }

  Future<void> _checkSubscription() async {
    final token = await _storage.read(key: 'access');
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/my-subscription/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => subscription = json.decode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint("Error checking subscription: $e");
    }
  }

  void _resetForm() {
    _titreController.clear();
    _descController.clear();
    _expController.text = '0';
    _skillsController.clear();
    _selectedDate = null;
    setState(() {
      showForm = false;
      isEditing = false;
      currentId = null;
    });
  }

  void _handleEditClick(Map offre) {
    _titreController.text = offre['titre'];
    _descController.text = offre['description'];
    _expController.text = offre['experience_min'].toString();
    _skillsController.text = offre['competences_requises'] ?? '';
    if (offre['date_expiration'] != null) {
      _selectedDate = DateTime.parse(offre['date_expiration']);
    }
    setState(() {
      isEditing = true;
      currentId = offre['id'];
      showForm = true;
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez choisir une date d'expiration")));
      return;
    }

    final token = await _storage.read(key: 'access');
    final data = {
      "titre": _titreController.text,
      "description": _descController.text,
      "experience_min": int.tryParse(_expController.text) ?? 0,
      "competences_requises": _skillsController.text,
      "date_expiration": _selectedDate!.toIso8601String(),
    };

    try {
      final url = isEditing
          ? '${ApiConfig.baseUrl}/api/offres/$currentId/'
          : '${ApiConfig.baseUrl}/api/offres/';

      final response = await (isEditing
          ? http.put(Uri.parse(url), headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}, body: jsonEncode(data))
          : http.post(Uri.parse(url), headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}, body: jsonEncode(data)));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        _initData();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? "Modifiée !" : "Publiée !")));
      } else {
        final err = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['error'] ?? "Erreur")));
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // تم تحديث زر العودة هنا لمنع الصفحة البيضاء
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gestion des Offres", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              subscription != null && subscription!['status'] == 'ACTIVE'
                  ? "✅ Pack Actif: ${subscription!['plan_details']['title']} (${subscription!['plan_details']['current_usage']}/${subscription!['plan_details']['offres_count']})"
                  : "🟠 Mode Gratuit (${subscription?['plan_details']?['current_usage'] ?? 0}/3)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (showForm) _resetForm();
              else {
                final usage = subscription?['plan_details']?['current_usage'] ?? 0;
                final limit = subscription?['plan_details']?['offres_count'] ?? 3;
                if (usage >= limit) {
                  _showLimitDialog();
                } else {
                  setState(() => showForm = true);
                }
              }
            },
            icon: Icon(showForm ? Icons.close : Icons.add_circle, color: showForm ? Colors.red : ApiConfig.kPrimary),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (showForm) _buildGlassForm(),
                  const SizedBox(height: 20),
                  ...offres.map((o) => _buildOffreCard(o)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGlassForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ApiConfig.kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? "📝 Modifier" : "📌 Nouvelle offre", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          _buildInput(_titreController, "Titre du poste"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildInput(_expController, "Exp min", isNumber: true)),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                    child: Text(_selectedDate == null ? "Date Exp." : DateFormat('dd/MM/yyyy').format(_selectedDate!), style: const TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInput(_skillsController, "Compétences (ex: SQL, Java)"),
          const SizedBox(height: 10),
          _buildInput(_descController, "Description", maxLines: 3),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(isEditing ? "Enregistrer" : "Publier"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOffreCard(Map o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: ApiConfig.kBgCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(o['titre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
              Row(
                children: [
                  IconButton(onPressed: () => _handleEditClick(o), icon: const Icon(Icons.edit, color: Colors.blue, size: 20)),
                  IconButton(onPressed: () => _showDeleteDialog(o['id']), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                ],
              )
            ],
          ),
          Text(o['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            children: (o['competences_requises']?.toString().split(',') ?? []).map((s) => Chip(
              label: Text(s.trim(), style: const TextStyle(fontSize: 10, color: ApiConfig.kPrimary)),
              backgroundColor: ApiConfig.kPrimary.withOpacity(0.1),
              padding: EdgeInsets.zero,
            )).toList(),
          ),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("⏳ Exp: ${o['experience_min']} ans", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text("⌛ Expire: ${o['date_expiration'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(o['date_expiration'])) : 'N/A'}", style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  void _showLimitDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("⚠️ Limite atteinte"),
      content: const Text("Veuillez activer ένα pack pour publier plus d'offres."),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
    ));
  }

  void _showDeleteDialog(int id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Supprimer ?"),
      content: const Text("Voulez-vous really supprimer cette offre ?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Annuler")),
        TextButton(onPressed: () async {
          final token = await _storage.read(key: 'access');
          await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/offres/$id/'), headers: {"Authorization": "Bearer $token"});
          Navigator.pop(c);
          _initData();
        }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}