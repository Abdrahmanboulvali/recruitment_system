import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../api_config.dart';

class ProfileEntrepriseScreen extends StatefulWidget {
  const ProfileEntrepriseScreen({super.key});

  @override
  State<ProfileEntrepriseScreen> createState() => _ProfileEntrepriseScreenState();
}

class _ProfileEntrepriseScreenState extends State<ProfileEntrepriseScreen> {
  final _storage = const FlutterSecureStorage();

  // حالات البيانات
  Map<String, dynamic>? entreprise;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _isEditing = false;

  // وحدات التحكم للتعديل
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  File? _selectedImage;
  bool _removeLogo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && entreprise == null) {
      _fetchData(args['id']);
    }
  }

  Future<void> _fetchData(int id) async {
    try {
      String? token = await _storage.read(key: 'access');
      var headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};

      // جلب بيانات الشركة
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/enterprises/$id/'),
        headers: headers,
      );

      // جلب بيانات المستخدم الحالي للتأكد من الصلاحية (Owner)
      if (token != null) {
        final profileRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/profile/'),
          headers: headers,
        );
        setState(() => userData = json.decode(utf8.decode(profileRes.bodyBytes)));
      }

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          entreprise = data;
          _nameController.text = data['nom'] ?? data['name'] ?? '';
          _descController.text = data['description'] ?? '';
          _isLoading = false;
          _removeLogo = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _removeLogo = false;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _storage.read(key: 'access');
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiConfig.baseUrl}/api/enterprises/${entreprise!['id']}/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nom'] = _nameController.text;
      request.fields['description'] = _descController.text;

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('logo', _selectedImage!.path));
      } else if (_removeLogo) {
        request.fields['logo'] = '';
      }

      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        setState(() {
          _isEditing = false;
          _selectedImage = null;
          _removeLogo = false;
        });
        _fetchData(entreprise!['id']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de l'enregistrement")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // التحقق هل المستخدم هو صاحب الشركة
    final isOwner = userData != null && entreprise != null &&
                    userData!['id'].toString() == entreprise!['owner_id'].toString();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text("Profil Entreprise"),
        actions: [
          if (isOwner)
            _isEditing
                ? IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _handleSave)
                : IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // قسم اللوجو
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isDark ? ApiConfig.kBgCard : Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: ApiConfig.kPrimary, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(33),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : (entreprise!['logo'] != null && !_removeLogo)
                              ? Image.network("${ApiConfig.baseUrl}${entreprise!['logo']}", fit: BoxFit.cover)
                              : Center(child: Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "E", style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: ApiConfig.kPrimary))),
                    ),
                  ),
                  if (_isEditing) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(35)),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    if (entreprise!['logo'] != null || _selectedImage != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImage = null;
                            _removeLogo = true;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.delete, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 25),

            // اسم الشركة
            _isEditing
                ? TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(hintText: "Nom de l'entreprise"),
                  )
                : Text(entreprise!['nom'] ?? "Sans Nom", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),

            Text("Dirigé par: ${entreprise!['dg_name'] ?? 'Non assigné'}", style: TextStyle(color: Colors.grey[600])),

            const SizedBox(height: 40),

            // بطاقة الوصف (About us)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: isDark ? ApiConfig.kBgCard : Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("À propos de nous", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _isEditing
                      ? TextFormField(
                          controller: _descController,
                          maxLines: 5,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        )
                      : Text(
                          entreprise!['description'] ?? "Aucune description disponible.",
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                ],
              ),
            ),

            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _selectedImage = null;
                    _removeLogo = false;
                  }),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text("Annuler les modifications", style: TextStyle(color: Colors.red)),
                ),
              )
          ],
        ),
      ),
    );
  }
}