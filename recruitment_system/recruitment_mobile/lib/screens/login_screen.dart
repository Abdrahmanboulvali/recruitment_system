import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _isDarkMode = true;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    String? savedMode = await _storage.read(key: 'isDarkMode');
    if (savedMode != null) {
      setState(() {
        _isDarkMode = savedMode == 'true';
      });
    }
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await _storage.write(key: 'isDarkMode', value: _isDarkMode.toString());
  }

  final List<String> dgRoles = [
    'DG',
    'DIRECTEUR GÉNÉRAL',
    'DG_BUSINESS',
    'DG_GOV',
    'DG_COMPANY',
    'HOMME D\'AFFAIRES',
    'PROPRIÉTAIRE D\'ENTREPRISE'
  ];

  Future<void> _handleSubmit() async {
    setState(() { _isLoading = true; _error = ''; });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/jwt/create/'),
        body: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String accessToken = data['access'];
        await _storage.write(key: 'access', value: accessToken);

        final userRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/profile/'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (userRes.statusCode == 200) {
          final userData = json.decode(utf8.decode(userRes.bodyBytes));
          final String rawRole = userData['role'].toString().toUpperCase().trim();

          await _storage.write(key: 'role', value: rawRole);
          await _storage.write(key: 'username', value: userData['username'] ?? '');

          // حفظ معرف الشركة لربط المدير بشركته كما في الويب
          if (userData['enterprise'] != null) {
            await _storage.write(key: 'enterprise_id', value: userData['enterprise'].toString());
          } else {
            await _storage.delete(key: 'enterprise_id');
          }

          if (!mounted) return;

          if (rawRole == 'SUPER_ADMIN') {
            Navigator.pushReplacementNamed(context, '/all-stats');
          } else if (rawRole == 'CANDIDAT') {
            Navigator.pushReplacementNamed(context, '/espace-candidat');
          } else if (dgRoles.contains(rawRole)) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/manage-offres');
          }
        }
      } else {
        setState(() => _error = "Email ou mot de passe incorrect.");
      }
    } catch (err) {
      setState(() => _error = "Erreur de connexion au serveur.");
      debugPrint("Login Error: $err");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? ApiConfig.kBgMain : const Color(0xFFF8FAFC);
    final cardBg = _isDarkMode ? ApiConfig.kBgCard : Colors.white.withOpacity(0.9);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final inputBg = _isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => Navigator.pushReplacementNamed(context, '/espace-candidat'),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: ElevatedButton(
              onPressed: _toggleTheme,
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
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, offset: const Offset(0, 25))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Connexion", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1)),
                    const SizedBox(height: 5),
                    Text("Accédez à votre compte professionnel", style: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 35),
                    _buildInput(controller: _emailController, hint: "Email", isDarkMode: _isDarkMode, inputBg: inputBg, textColor: textColor),
                    const SizedBox(height: 20),
                    _buildInput(controller: _passwordController, hint: "Mot de passe", isPassword: true, isDarkMode: _isDarkMode, inputBg: inputBg, textColor: textColor),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text("Mot de passe oublié ?", style: TextStyle(color: ApiConfig.kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 12))],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Se connecter", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text("Vous n'avez pas de compte ?", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: const Text(" Créer un compte", style: TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, bool isPassword = false, required bool isDarkMode, required Color inputBg, required Color textColor}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12)),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }
}