import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config.dart';

class AddAgentScreen extends StatefulWidget {
  @override
  _AddAgentScreenState createState() => _AddAgentScreenState();
}

class _AddAgentScreenState extends State<AddAgentScreen> {
  // تم إزالة المتغير الثابت lang هنا

  final Map<String, Map<String, String>> _texts = {
    'fr': {
      'title': "Ajouter un Nouvel Agent",
      'user': "Nom d'utilisateur",
      'email': "Email",
      'pass': "Mot de passe",
      'dept': "Département",
      'btn': "Créer le compte",
      'success': "Le compte agent a été créé avec succès!",
      'err_wrong': "Erreur : Vérifiez les informations saisies.",
      'err_server': "Erreur : Impossible de contacter le serveur."
    },
    'ar': {
      'title': "إضافة وكيل جديد",
      'user': "اسم المستخدم",
      'email': "البريد الإلكتروني",
      'pass': "كلمة المرور",
      'dept': "القسم",
      'btn': "إنشاء الحساب",
      'success': "تم إنشاء حساب الوكيل بنجاح!",
      'err_wrong': "خطأ: يرجى التحقق من البيانات.",
      'err_server': "خطأ: تعذر الاتصال بالسيرفر."
    },
    'en': {
      'title': "Add New Agent",
      'user': "Username",
      'email': "Email",
      'pass': "Password",
      'dept': "Department",
      'btn': "Create Account",
      'success': "Agent account created successfully!",
      'err_wrong': "Error: Check the entered information.",
      'err_server': "Error: Unable to contact the server."
    }
  };

  // الدالة الآن تجلب اللغة تلقائياً من الـ context
  String tr(String key) {
    String lang = Localizations.localeOf(context).languageCode;
    // إذا لم تكن اللغة مدعومة، نرجع الفرنسية افتراضياً
    return _texts.containsKey(lang) ? _texts[lang]![key]! : _texts['fr']![key]!;
  }

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();

  String _message = '';

  Future<void> _handleSubmit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/manage-agents/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'departement': _deptController.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _message = tr('success');
          _usernameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _deptController.clear();
        });
      } else {
        setState(() => _message = tr('err_wrong'));
      }
    } catch (e) {
      setState(() => _message = tr('err_server'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد الوضع (ليلي أم نهاري)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? ApiConfig.kBgMain : Colors.white;
    final cardColor = isDark ? ApiConfig.kBgCard : Colors.grey[200]!;
    final textColor = isDark ? ApiConfig.kTextMain : Colors.black87;
    final hintColor = isDark ? ApiConfig.kTextMuted : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? ApiConfig.kBgCard : ApiConfig.kPrimary,
        title: Text(tr('title'), style: ApiConfig.kHeaderStyle.copyWith(fontSize: 20, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(tr('user'), _usernameController, cardColor, textColor, hintColor),
            _buildTextField(tr('email'), _emailController, cardColor, textColor, hintColor, isEmail: true),
            _buildTextField(tr('pass'), _passwordController, cardColor, textColor, hintColor, isPassword: true),
            _buildTextField(tr('dept'), _deptController, cardColor, textColor, hintColor),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ApiConfig.kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: ApiConfig.kBorderRadius),
              ),
              child: Text(tr('btn'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_message, textAlign: TextAlign.center, style: TextStyle(color: _message.contains('Err') ? ApiConfig.kError : ApiConfig.kSuccess)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, Color bg, Color text, Color hintC, {bool isPassword = false, bool isEmail = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: bg, borderRadius: ApiConfig.kBorderRadius),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: TextStyle(color: text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintC),
          border: OutlineInputBorder(borderRadius: ApiConfig.kBorderRadius, borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }
}