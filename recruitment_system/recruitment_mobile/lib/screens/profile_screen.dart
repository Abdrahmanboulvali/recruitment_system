import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final _picker = ImagePicker();

  Map<String, dynamic>? user;
  bool isLoading = true;
  bool isEditing = false;
  bool isChangingPassword = false;
  bool showOTPField = false;

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => isLoading = true);
    String? token = await _storage.read(key: 'access');
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          user = json.decode(utf8.decode(res.bodyBytes));
          _usernameController.text = user!['username'];
          _emailController.text = user!['email'];
        });
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleImageAction(bool delete) async {
    String? token = await _storage.read(key: 'access');
    var request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/api/profile/'));
    request.headers['Authorization'] = 'Bearer $token';

    if (delete) {
      request.fields['photo'] = "";
    } else {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      _showSnackBar(delete ? "Photo supprimée !" : "Photo mise à jour !");
      _fetchProfile();
    }
  }

  Future<void> _saveInfo() async {
    String? token = await _storage.read(key: 'access');
    Map<String, String> body = {
      'username': _usernameController.text,
      'email': _emailController.text,
    };
    if (showOTPField) body['otp'] = _otpController.text;

    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final data = json.decode(res.body);
      if (data['detail'] == "OTP_SENT") {
        setState(() => showOTPField = true);
        _showSnackBar("Code OTP envoyé à votre email");
      } else if (res.statusCode == 200) {
        setState(() {
          isEditing = false;
          showOTPField = false;
        });
        _fetchProfile();
        _showSnackBar("Profil mis à jour !");
      } else {
        _showSnackBar(data['detail'] ?? "Erreur");
      }
    } catch (e) {
      _showSnackBar("Erreur de serveur");
    }
  }

  Future<void> _updatePassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      _showSnackBar("Les mots de passe ne correspondent pas");
      return;
    }
    String? token = await _storage.read(key: 'access');
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/change-password/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'old_password': _oldPassController.text,
        'new_password': _newPassController.text,
        'confirm_password': _confirmPassController.text,
      }),
    );

    if (res.statusCode == 200) {
      _showSnackBar("Mot de passe changé !");
      setState(() => isChangingPassword = false);
      _oldPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    } else {
      _showSnackBar(json.decode(res.body)['detail'] ?? "Erreur");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: ApiConfig.kBgMain, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              isEditing = !isEditing;
              isChangingPassword = false;
              showOTPField = false;
            }),
            child: Text(isEditing || isChangingPassword ? "Annuler" : "Modifier",
                  style: const TextStyle(color: ApiConfig.kPrimary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ApiConfig.kBgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 30),
              if (!isChangingPassword) _buildInfoSection() else _buildPasswordSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    String? photoUrl = user!['photo'];
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ApiConfig.kPrimary, width: 3),
              image: photoUrl != null
                ? DecorationImage(image: NetworkImage(photoUrl.startsWith('http') ? photoUrl : "${ApiConfig.baseUrl}$photoUrl"), fit: BoxFit.cover)
                : null,
              color: ApiConfig.kPrimary,
            ),
            child: photoUrl == null
              ? Center(child: Text(user!['username'][0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)))
              : null,
          ),
          if (isEditing) ...[
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: () => _handleImageAction(false),
                child: const CircleAvatar(radius: 18, backgroundColor: ApiConfig.kPrimary, child: Icon(Icons.camera_alt, size: 16, color: Colors.white)),
              ),
            ),
            if (photoUrl != null)
              Positioned(
                bottom: 0, left: 0,
                child: GestureDetector(
                  onTap: () => _handleImageAction(true),
                  child: const CircleAvatar(radius: 18, backgroundColor: Colors.red, child: Icon(Icons.delete, size: 16, color: Colors.white)),
                ),
              ),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoCard("Nom d'utilisateur", _usernameController, Icons.person_outline, !isEditing),
        const SizedBox(height: 15),
        _buildInfoCard("Adresse Email", _emailController, Icons.email_outlined, !isEditing || showOTPField),
        if (showOTPField) ...[
          const SizedBox(height: 15),
          _buildInfoCard("Code OTP", _otpController, Icons.lock_outline, false),
        ],
        const SizedBox(height: 15),
        _buildRoleBadge(),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEditing ? _saveInfo : () => setState(() => isChangingPassword = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditing ? ApiConfig.kPrimary : Colors.white.withOpacity(0.05),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(isEditing ? (showOTPField ? "Vérifier OTP" : "Sauvegarder") : "Changer le mot de passe",
                style: TextStyle(color: isEditing ? Colors.white : ApiConfig.kPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      children: [
        _buildInfoCard("Ancien mot de passe", _oldPassController, Icons.lock_reset, false, isPassword: true),
        const SizedBox(height: 15),
        _buildInfoCard("Nouveau mot de passe", _newPassController, Icons.vpn_key_outlined, false, isPassword: true),
        const SizedBox(height: 15),
        _buildInfoCard("Confirmer", _confirmPassController, Icons.check_circle_outline, false, isPassword: true),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updatePassword,
            style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, padding: const EdgeInsets.all(16)),
            child: const Text("Mettre à jour le mot de passe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, TextEditingController controller, IconData icon, bool readOnly, {bool isPassword = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: ApiConfig.kPrimary, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 1)),
                TextField(
                  controller: controller,
                  readOnly: readOnly,
                  obscureText: isPassword,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, color: ApiConfig.kPrimary, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("RÔLE DU COMPTE", style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: ApiConfig.kPrimary, borderRadius: BorderRadius.circular(8)),
              child: Text(user!['role'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}