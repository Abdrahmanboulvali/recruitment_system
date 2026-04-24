import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDarkMode = true;
  bool _isLoading = false;

  // الحقول (نفس الـ formData في React)
  String _selectedRole = 'CANDIDAT';
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final _enterpriseController = TextEditingController();
  PlatformFile? _pickedFile;

  // دالة اختيار الملف (Document d'identification)
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  // دالة الإرسال (Multipart Request لرفع الملفات)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _rePasswordController.text) {
      _showSnack("Les mots de passe ne correspondent pas.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/api/register/'));

      request.fields['username'] = _usernameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['re_password'] = _rePasswordController.text;
      request.fields['role'] = _selectedRole;

      if (_selectedRole != 'CANDIDAT') {
        request.fields['enterprise_name'] = _enterpriseController.text;
        if (_pickedFile != null && _pickedFile!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'verification_document',
            _pickedFile!.bytes!,
            filename: _pickedFile!.name
          ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnack("Inscription réussie! Vérifiez votre OTP.", Colors.green);
        Navigator.pushReplacementNamed(context, '/verify-otp');
      } else {
        final errorMsg = json.decode(response.body)['detail'] ?? "Erreur d'inscription";
        _showSnack(errorMsg, Colors.red);
      }
    } catch (e) {
      _showSnack("Erreur de connexion au serveur.", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? ApiConfig.kBgMain : const Color(0xFFF8FAFC);
    final cardBg = _isDarkMode ? ApiConfig.kBgCard : Colors.white.withOpacity(0.9);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text("Créer un compte", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 25),

                  // اختيار الدور
                  _buildDropdown(textColor),
                  const SizedBox(height: 15),

                  _buildInput(_usernameController, "Nom d'utilisateur", Icons.person),
                  const SizedBox(height: 15),

                  _buildInput(_emailController, "E-mail", Icons.email),
                  const SizedBox(height: 15),

                  // حقول إضافية للشركات
                  if (_selectedRole != 'CANDIDAT') ...[
                    _buildInput(_enterpriseController, "Nom de l'organisation", Icons.business),
                    const SizedBox(height: 15),
                    _buildFilePicker(textColor),
                    const SizedBox(height: 15),
                  ],

                  _buildInput(_passwordController, "Mot de passe", Icons.lock, isPass: true),
                  const SizedBox(height: 15),

                  _buildInput(_rePasswordController, "Confirmer", Icons.lock_outline, isPass: true),
                  const SizedBox(height: 25),

                  _buildSubmitButton(),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Déjà inscrit ? Se connecter", style: TextStyle(color: ApiConfig.kPrimary)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
      child: DropdownButton<String>(
        value: _selectedRole,
        dropdownColor: ApiConfig.kBgCard,
        isExpanded: true,
        underline: Container(),
        style: TextStyle(color: textColor),
        items: const [
          DropdownMenuItem(value: 'CANDIDAT', child: Text("Candidat")),
          DropdownMenuItem(value: 'DG', child: Text("Entreprise Privée")),
          DropdownMenuItem(value: 'DG_GOV', child: Text("Institution Publique")),
        ],
        onChanged: (val) => setState(() => _selectedRole = val!),
      ),
    );
  }

  Widget _buildFilePicker(Color textColor) {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(Icons.upload_file, color: ApiConfig.kPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(_pickedFile?.name ?? "Document d'identification", style: TextStyle(color: textColor.withOpacity(0.6)))),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, {bool isPass = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white30),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: ApiConfig.kPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}