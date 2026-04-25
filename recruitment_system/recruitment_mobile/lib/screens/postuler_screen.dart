import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../api_config.dart';

class PostulerScreen extends StatefulWidget {
  const PostulerScreen({super.key});

  @override
  State<PostulerScreen> createState() => _PostulerScreenState();
}

class _PostulerScreenState extends State<PostulerScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  // الحالات (States)
  int? _offreId;
  int? _candidatId;
  bool _isLoading = false;
  bool _hasCheckedProfile = false;
  bool _alreadyApplied = false;

  // بيانات النموذج
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _diplomeController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  File? _cvFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // الحصول على معرف الوظيفة من الـ Arguments
    _offreId = ModalRoute.of(context)?.settings.arguments as int?;
    if (!_hasCheckedProfile) _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      String? token = await _storage.read(key: 'access');
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final headers = {'Authorization': 'Bearer $token'};

      // 1. جلب معلومات المستخدم الحالي
      final userRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-info/'), headers: headers);
      final int userId = json.decode(userRes.body)['id'];

      // 2. التحقق من وجود ملف شخصي (Candidat)
      final candRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidats/'), headers: headers);
      final List candidates = json.decode(utf8.decode(candRes.bodyBytes));

      var profile = candidates.firstWhere((c) => c['user'] == userId, orElse: () => null);

      if (profile != null) {
        setState(() => _candidatId = profile['id']);

        // 3. التحقق من التقديم المسبق
        final appRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidatures/'), headers: headers);
        final List applications = json.decode(utf8.decode(appRes.bodyBytes));

        bool hasApplied = applications.any((can) =>
            can['candidat'] == _candidatId && can['offre'] == _offreId);

        if (hasApplied) setState(() => _alreadyApplied = true);
      }
    } catch (e) {
      debugPrint("Error checkStatus: $e");
    } finally {
      setState(() => _hasCheckedProfile = true);
    }
  }

  Future<void> _pickCV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _cvFile = File(result.files.single.path!));
    }
  }

  Future<void> _submitCandidature() async {
    if (_cvFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner votre CV (PDF)")));
      return;
    }

    if (_candidatId == null && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? token = await _storage.read(key: 'access');
      var headers = {'Authorization': 'Bearer $token'};

      int? currentCandidatId = _candidatId;

      // إنشاء ملف شخصي إذا لم يوجد
      if (currentCandidatId == null) {
        final userRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-info/'), headers: headers);
        final userId = json.decode(userRes.body)['id'];

        var profileReq = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/candidats/'));
        profileReq.headers.addAll(headers);
        profileReq.fields.addAll({
          'user': userId.toString(),
          'nom': _nomController.text,
          'prenom': _prenomController.text,
          'diplome': _diplomeController.text,
          'experience': _experienceController.text,
        });
        profileReq.files.add(await http.MultipartFile.fromPath('cv_file', _cvFile!.path));

        var profileRes = await profileReq.send();
        var responseData = await http.Response.fromStream(profileRes);
        currentCandidatId = json.decode(responseData.body)['id'];
      }

      // إرسال طلب التقديم
      var candReq = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/candidatures/'));
      candReq.headers.addAll(headers);
      candReq.fields.addAll({
        'offre': _offreId.toString(),
        'candidat': currentCandidatId.toString(),
        'statut': 'En attente',
      });
      candReq.files.add(await http.MultipartFile.fromPath('cv_file', _cvFile!.path));

      var finalRes = await candReq.send();
      if (finalRes.statusCode == 201 || finalRes.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Succès ! Votre candidature a été transmise.")));
        Navigator.pushReplacementNamed(context, '/mes-candidatures');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la postulation.")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedProfile) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_alreadyApplied) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text("Déjà postulé", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Vous avez déjà soumis votre candidature pour ce poste.", textAlign: TextAlign.center),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/mes-candidatures'),
                child: const Text("Suivre ma candidature"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Postuler à l'offre #$_offreId")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_candidatId == null) ...[
                const Text("📝 Informations personnelles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextFormField(controller: _nomController, decoration: const InputDecoration(labelText: "Nom"), validator: (v) => v!.isEmpty ? "Requis" : null),
                TextFormField(controller: _prenomController, decoration: const InputDecoration(labelText: "Prénom"), validator: (v) => v!.isEmpty ? "Requis" : null),
                TextFormField(controller: _diplomeController, decoration: const InputDecoration(labelText: "Dernier diplôme"), validator: (v) => v!.isEmpty ? "Requis" : null),
                TextFormField(controller: _experienceController, decoration: const InputDecoration(labelText: "Expérience (ans)"), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? "Requis" : null),
                const SizedBox(height: 30),
              ],

              const Text("📄 Votre CV (PDF)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickCV,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blue),
                      const SizedBox(height: 10),
                      Text(_cvFile == null ? "Cliquez pour sélectionner un fichier PDF" : "✅ ${_cvFile!.path.split('/').last}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitCandidature,
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_candidatId != null ? "Confirmer la postulation" : "Créer profil & Postuler"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}