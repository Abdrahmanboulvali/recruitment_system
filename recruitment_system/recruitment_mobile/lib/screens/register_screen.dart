import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // أضف هذا
import '../api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage(); // تعريف التخزين
  bool _isLoading = false;
  bool _isDarkMode = true;

  String _selectedRole = 'CANDIDAT';
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final _enterpriseController = TextEditingController();
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _loadThemeMode(); // جلب الوضع عند تشغيل الصفحة
  }

  // دالة لجلب الوضع من التخزين
  Future<void> _loadThemeMode() async {
    String? mode = await _storage.read(key: 'isDarkMode');
    if (mode != null) {
      setState(() => _isDarkMode = mode == 'true');
    }
  }

  // دالة لتغيير الوضع وحفظه
  Future<void> _toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    await _storage.write(key: 'isDarkMode', value: _isDarkMode.toString());
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _rePasswordController.text) {
      _showSnack("Les mots de passe ne correspondent pas.", Colors.red);
      return;
    }

    if (_selectedRole != 'CANDIDAT' && _pickedFile == null) {
      _showSnack("Veuillez joindre un document d'identification.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/register/'));

      request.fields['username'] = _usernameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['password'] = _passwordController.text;
      request.fields['re_password'] = _rePasswordController.text;
      request.fields['role'] = _selectedRole;

      if (_selectedRole != 'CANDIDAT') {
        request.fields['enterprise_name'] = _enterpriseController.text.trim();
        if (_pickedFile != null && _pickedFile!.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'verification_document',
            _pickedFile!.path!
          ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnack("Inscription réussie! Vérifiez votre OTP.", Colors.green);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/verify-otp');
        });
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        _showSnack(errorData['detail'] ?? "Erreur d'inscription", Colors.red);
      }
    } catch (e) {
      _showSnack("Erreur de connexion au serveur.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? ApiConfig.kBgMain : const Color(0xFFF8FAFC);
    final cardBg = _isDarkMode ? ApiConfig.kBgCard : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            right: 20,
            child: ElevatedButton(
              onPressed: _toggleTheme, // استدعاء الدالة المحدثة
              style: ElevatedButton.styleFrom(
                backgroundColor: ApiConfig.kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(_isDarkMode ? '☀️ Mode Clair' : '🌙 Mode Sombre'),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 10)
                    )
                  ],
                  border: Border.all(color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text("Créer un compte",
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1)),
                      const SizedBox(height: 10),
                      Text("Rejoignez notre plateforme",
                        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14)),
                      const SizedBox(height: 35),

                      _buildDropdown(textColor, _isDarkMode),
                      const SizedBox(height: 15),

                      _buildInput(_usernameController, "Nom d'utilisateur", Icons.person, _isDarkMode),
                      const SizedBox(height: 15),

                      _buildInput(_emailController, "E-mail", Icons.email, _isDarkMode, isEmail: true),
                      const SizedBox(height: 15),

                      if (_selectedRole != 'CANDIDAT') ...[
                        _buildInput(_enterpriseController, "Nom de l'organisation", Icons.business, _isDarkMode),
                        const SizedBox(height: 15),
                        _buildFilePicker(textColor, _isDarkMode),
                        const SizedBox(height: 15),
                      ],

                      _buildInput(_passwordController, "Mot de passe", Icons.lock, _isDarkMode, isPass: true),
                      const SizedBox(height: 15),

                      _buildInput(_rePasswordController, "Confirmer le mot de passe", Icons.lock_outline, _isDarkMode, isPass: true),
                      const SizedBox(height: 25),

                      _buildSubmitButton(),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: "Déjà inscrit ? ",
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                            children: const [
                              TextSpan(text: "Se connecter", style: TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.bold))
                            ]
                          )
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- دوال الـ Widgets الفرعية تبقى كما هي مع التأكد من تمرير _isDarkMode لها ---
  Widget _buildDropdown(Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          dropdownColor: isDark ? ApiConfig.kBgCard : Colors.white,
          isExpanded: true,
          style: TextStyle(color: textColor, fontSize: 15),
          items: const [
            DropdownMenuItem(value: 'CANDIDAT', child: Text("Candidat")),
            DropdownMenuItem(value: 'DG', child: Text("Entreprise Privée")),
            DropdownMenuItem(value: 'DG_GOV', child: Text("Institution Publique")),
            DropdownMenuItem(value: 'DG_BUSINESS', child: Text("Entrepreneur / Business")),
          ],
          onChanged: (val) => setState(() => _selectedRole = val!),
        ),
      ),
    );
  }

  Widget _buildFilePicker(Color textColor, bool isDark) {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[50],
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          borderRadius: BorderRadius.circular(14)
        ),
        child: Row(
          children: [
            Icon(Icons.upload_file, color: ApiConfig.kPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(_pickedFile?.name ?? "Document d'identification",
                style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14))),
            if (_pickedFile != null) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, bool isDark, {bool isPass = false, bool isEmail = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: (value) {
        if (value == null || value.isEmpty) return "Ce champ est obligatoire";
        if (isEmail && !value.contains('@')) return "Email invalide";
        if (isPass && value.length < 6) return "Minimum 6 caractères";
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDark ? Colors.white30 : Colors.black26),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 14),
        filled: true,
        fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8)
          )
        ]
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
      ),
    );
  }
}