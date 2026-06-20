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

  Future<void> _submitCandidature(String currentLang) async {
    if (_cvFile == null) {
      String cvMsg = currentLang == 'ar'
          ? "يرجى تحديد السيرة الذاتية الخاصة بك (PDF)"
          : "Veuillez sélectionner votre CV (PDF)";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cvMsg)));
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
        String successMsg = currentLang == 'ar'
            ? "تم بنجاح! تم إرسال ترشيحك."
            : "Succès ! Votre candidature a été transmise.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
        Navigator.pushReplacementNamed(context, '/mes-candidatures');
      }
    } catch (e) {
      String errMsg = currentLang == 'ar'
          ? "حدث خطأ أثناء تقديم الطلب."
          : "Erreur lors de la postulation.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    if (!_hasCheckedProfile) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));

    if (_alreadyApplied) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                currentLang == 'ar' ? "تم التقديم مسبقاً" : "Déjà postulé",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  currentLang == 'ar'
                      ? "لقد قمت بالفعل بتقديم طلب توظيف لهذا المنصب سابقاً."
                      : "Vous avez déjà soumis votre candidature pour ce poste.",
                  textAlign: TextAlign.center
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/mes-candidatures'),
                child: Text(currentLang == 'ar' ? "متابعة حالة ترشيحي" : "Suivre ma candidature"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLang == 'ar' ? "الترشح للعرض #$_offreId" : "Postuler à l'offre #$_offreId"
        )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_candidatId == null) ...[
                Text(
                  currentLang == 'ar' ? "📝 المعلومات الشخصية" : "📝 Informations personnelles",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(labelText: currentLang == 'ar' ? "الاسم العائلي" : "Nom"),
                  validator: (v) => v!.isEmpty ? (currentLang == 'ar' ? "مطلوب" : "Requis") : null
                ),
                TextFormField(
                  controller: _prenomController,
                  decoration: InputDecoration(labelText: currentLang == 'ar' ? "الاسم الشخصي" : "Prénom"),
                  validator: (v) => v!.isEmpty ? (currentLang == 'ar' ? "مطلوب" : "Requis") : null
                ),
                TextFormField(
                  controller: _diplomeController,
                  decoration: InputDecoration(labelText: currentLang == 'ar' ? "آخر شهادة محصل عليها" : "Dernier diplôme"),
                  validator: (v) => v!.isEmpty ? (currentLang == 'ar' ? "مطلوب" : "Requis") : null
                ),
                TextFormField(
                  controller: _experienceController,
                  decoration: InputDecoration(labelText: currentLang == 'ar' ? "الخبرة (سنوات)" : "Expérience (ans)"),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? (currentLang == 'ar' ? "مطلوب" : "Requis") : null
                ),
                const SizedBox(height: 30),
              ],

              Text(
                currentLang == 'ar' ? "📄 السيرة الذاتية (PDF)" : "📄 Votre CV (PDF)",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
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
                      Text(
                        _cvFile == null
                            ? (currentLang == 'ar' ? "اضغط هنا لاختيار ملف PDF" : "Cliquez pour sélectionner un fichier PDF")
                            : "✅ ${_cvFile!.path.split('/').last}"
                      ),
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
                  onPressed: _isLoading ? null : () => _submitCandidature(currentLang),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _candidatId != null
                            ? (currentLang == 'ar' ? "تأكيد الترشح" : "Confirmer la postulation")
                            : (currentLang == 'ar' ? "إنشاء ملف شخصي والترشح" : "Créer profil & Postuler")
                      ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}