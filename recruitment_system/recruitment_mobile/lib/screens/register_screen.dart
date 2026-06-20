import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
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
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    String? mode = await _storage.read(key: 'isDarkMode');
    if (mode != null) {
      if (mounted) {
        setState(() => _isDarkMode = mode == 'true');
      }
    }
  }

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

  Future<void> _handleSubmit(String currentLang) async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _rePasswordController.text) {
      String passMsg = currentLang == 'ar' ? "كلمات المرور غير متطابقة." : "Les mots de passe ne correspondent pas.";
      _showSnack(passMsg, Colors.red);
      return;
    }

    if (_selectedRole != 'CANDIDAT' && _pickedFile == null) {
      String docMsg = currentLang == 'ar' ? "يرجى إرفاق وثيقة إثبات الهوية." : "Veuillez joindre un document d'identification.";
      _showSnack(docMsg, Colors.orange);
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
        String successMsg = currentLang == 'ar' ? "تم التسجيل بنجاح! يرجى التحقق من رمز OTP." : "Inscription réussie! Vérifiez votre OTP.";
        _showSnack(successMsg, Colors.green);

        // التعديل الجوهري هنا: الانتقال مع تمرير الإيميل
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyOtpScreen(email: _emailController.text.trim()),
              ),
            );
          }
        });
      } else {
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          String errorMessage = currentLang == 'ar' ? "خطأ في التسجيل" : "Erreur d'inscription";

          if (errorData['email'] != null) {
            if (errorData['email'] is List && errorData['email'].isNotEmpty) {
              errorMessage = currentLang == 'ar' ? "هذا البريد الإلكتروني مستخدم بالفعل من قبل حساب آخر." : "Cet e-mail est déjà utilisé par un autre compte.";
            } else {
              errorMessage = errorData['email'].toString();
            }
          } else if (errorData['username'] != null) {
            if (errorData['username'] is List && errorData['username'].isNotEmpty) {
              errorMessage = currentLang == 'ar' ? "اسم المستخدم هذا مأخوذ بالفعل." : "Ce nom d'utilisateur est déjà pris.";
            } else {
              errorMessage = errorData['username'].toString();
            }
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }

          _showSnack(errorMessage, Colors.red);
        } catch (e) {
          String fallbackErr = currentLang == 'ar' ? "خطأ في التسجيل. يرجى المحاولة مرة أخرى." : "Erreur d'inscription. Veuillez réessayer.";
          _showSnack(fallbackErr, Colors.red);
        }
      }
    } catch (e) {
      String serverErr = currentLang == 'ar' ? "خطأ في الاتصال بالخادم." : "Erreur de connexion au serveur.";
      _showSnack(serverErr, Colors.red);
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
    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    final bgColor = _isDarkMode ? ApiConfig.kBgMain : const Color(0xFFF8FAFC);
    final cardBg = _isDarkMode ? ApiConfig.kBgCard : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: currentLang == 'ar' ? null : 20,
            right: currentLang == 'ar' ? 20 : null,
            child: IconButton(
              icon: Icon(
                currentLang == 'ar' ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_ios_new,
                color: textColor
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/espace-candidat'),
            ),
          ),
          Positioned(
            top: 40,
            right: currentLang == 'ar' ? null : 20,
            left: currentLang == 'ar' ? 20 : null,
            child: ElevatedButton(
              onPressed: _toggleTheme,
              style: ElevatedButton.styleFrom(
                backgroundColor: ApiConfig.kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                _isDarkMode
                    ? (currentLang == 'ar' ? '☀️ الوضع الفاتح' : '☀️ Mode Clair')
                    : (currentLang == 'ar' ? '🌙 الوضع الداكن' : '🌙 Mode Sombre')
              ),
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
                      Text(
                        currentLang == 'ar' ? "إنشاء حساب" : "Créer un compte",
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentLang == 'ar' ? "انضم إلى منصتنا الآن" : "Rejoignez notre plateforme",
                        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14)
                      ),
                      const SizedBox(height: 35),

                      _buildDropdown(textColor, _isDarkMode, currentLang),
                      const SizedBox(height: 15),

                      _buildInput(_usernameController, currentLang == 'ar' ? "اسم المستخدم" : "Nom d'utilisateur", Icons.person, _isDarkMode, currentLang),
                      const SizedBox(height: 15),

                      _buildInput(_emailController, currentLang == 'ar' ? "البريد الإلكتروني" : "E-mail", Icons.email, _isDarkMode, currentLang, isEmail: true),
                      const SizedBox(height: 15),

                      if (_selectedRole != 'CANDIDAT') ...[
                        _buildInput(_enterpriseController, currentLang == 'ar' ? "اسم المؤسسة / الشركة" : "Nom de l'organisation", Icons.business, _isDarkMode, currentLang),
                        const SizedBox(height: 15),
                        _buildFilePicker(textColor, _isDarkMode, currentLang),
                        const SizedBox(height: 15),
                      ],

                      _buildInput(_passwordController, currentLang == 'ar' ? "كلمة المرور" : "Mot de passe", Icons.lock, _isDarkMode, currentLang, isPass: true),
                      const SizedBox(height: 15),

                      _buildInput(_rePasswordController, currentLang == 'ar' ? "تأكيد كلمة المرور" : "Confirmer le mot de passe", Icons.lock_outline, _isDarkMode, currentLang, isPass: true),
                      const SizedBox(height: 25),

                      _buildSubmitButton(currentLang),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: currentLang == 'ar' ? "مسجل بالفعل؟ " : "Déjà inscrit ? ",
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                            children: [
                              TextSpan(
                                text: currentLang == 'ar' ? "تسجيل الدخول" : "Se connecter",
                                style: const TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.bold)
                              )
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

  Widget _buildDropdown(Color textColor, bool isDark, String currentLang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          dropdownColor: isDark ? ApiConfig.kBgCard : Colors.white,
          isExpanded: true,
          style: TextStyle(color: textColor, fontSize: 15),
          items: [
            DropdownMenuItem(value: 'CANDIDAT', child: Text(currentLang == 'ar' ? "مترشح (باحث عن عمل)" : "Candidat")),
            DropdownMenuItem(value: 'DG', child: Text(currentLang == 'ar' ? "شركة خاصة" : "Entreprise Privée")),
            DropdownMenuItem(value: 'DG_GOV', child: Text(currentLang == 'ar' ? "مؤسسة عمومية / حكومية" : "Institution Publique")),
            DropdownMenuItem(value: 'DG_BUSINESS', child: Text(currentLang == 'ar' ? "مقاول / رائد أعمال" : "Entrepreneur / Business")),
          ],
          onChanged: (val) => setState(() => _selectedRole = val!),
        ),
      ),
    );
  }

  Widget _buildFilePicker(Color textColor, bool isDark, String currentLang) {
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
            const Icon(Icons.upload_file, color: ApiConfig.kPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _pickedFile?.name ?? (currentLang == 'ar' ? "وثيقة إثبات الهوية" : "Document d'identification"),
                style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14)
              )
            ),
            if (_pickedFile != null) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, bool isDark, String currentLang, {bool isPass = false, bool isEmail = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return currentLang == 'ar' ? "هذا الحقل إجباري" : "Ce champ est obligatoire";
        }
        if (isEmail && !value.contains('@')) {
          return currentLang == 'ar' ? "البريد الإلكتروني غير صالحة" : "Email invalide";
        }
        if (isPass && value.length < 6) {
          return currentLang == 'ar' ? "يجب أن تكون 6 أحرف على الأقل" : "Minimum 6 caractères";
        }
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

  Widget _buildSubmitButton(String currentLang) {
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
        onPressed: _isLoading ? null : () => _handleSubmit(currentLang),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              currentLang == 'ar' ? "إنشاء حساب" : "S'inscrire",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)
            ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    _enterpriseController.dispose();
    super.dispose();
  }
}