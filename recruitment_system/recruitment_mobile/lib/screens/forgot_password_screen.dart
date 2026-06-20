import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  String _error = '';

  Future<void> _handleResetPassword(String currentLang) async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = currentLang == 'ar'
            ? "يرجى إدخال عنوان بريدك الإلكتروني."
            : "Veuillez saisir votre adresse email.";
        _message = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _message = '';
    });

    try {
      // إرسال طلب استعادة كلمة المرور إلى الباكيند (نفس دالة الويب الخاصة بـ Djoser أو برمجتك الخاصة)
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/users/reset_password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _emailController.text.trim()}),
      );

      // تقبل الاستجابة 204 (No Content) الشائعة في Djoser عند نجاح الطلب، أو 200
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _message = currentLang == 'ar'
              ? "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني بنجاح."
              : "Un lien de réinitialisation a été envoyé à votre adresse email avec succès.";
        });
      } else {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _error = data['detail'] ?? (currentLang == 'ar'
              ? "عنوان البريد الإلكتروني غير موجود أو غير صحيح."
              : "Adresse email introuvable ou incorrecte.");
        });
      }
    } catch (err) {
      setState(() => _error = currentLang == 'ar'
          ? "خطأ في الاتصال بالخادم."
          : "Erreur de connexion au serveur.");
      debugPrint("Reset Password Error: $err");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // كشف الوضع الحالي للتطبيق (مظلم أم مضيء) تلقائياً للتوافق الكامل مع الـ main.dart
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? ApiConfig.kBgMain : const Color(0xFFF8FAFC);
    final cardBg = isDark ? ApiConfig.kBgCard : Colors.white.withOpacity(0.9);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white54 : Colors.grey[600];
    final inputBg = isDark ? Colors.black.withOpacity(0.3) : Colors.white;

    // معرفة لغة التطبيق الحالية لترجمة محتوى الصفحة بالكامل ديناميكياً
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.05),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة قفل مميزة في الأعلى تنبض بهوية التصميم
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ApiConfig.kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: ApiConfig.kPrimary, size: 40),
                ),
                const SizedBox(height: 25),
                Text(
                  currentLang == 'ar' ? "نسيت كلمة المرور" : (currentLang == 'en' ? "Forgot Password" : "Mot de passe oublié"),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  currentLang == 'ar'
                      ? "أدخل عنوان بريدك الإلكتروني لتلقي رابط استعادة الحساب."
                      : (currentLang == 'en' ? "Enter your email address to receive a recovery link." : "Entrez votre adresse e-mail pour recevoir un lien de récupération."),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 35),

                // حقل إدخال الإيميل
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: currentLang == 'ar' ? "بريدك الإلكتروني" : (currentLang == 'en' ? "Your Email" : "Votre Email"),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                    contentPadding: const EdgeInsets.all(18),
                  ),
                ),
                const SizedBox(height: 20),

                // رسالة الخطأ إن وجدت
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                  ),

                // رسالة النجاح إن وجدت
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      _message,
                      // تم الالتزام هنا باللون الأخضر المعتمد Colors.teal بدلاً من اللون غير المعرف لتجنب المشاكل البرمجية
                      style: const TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center
                    ),
                  ),

                // زر الإرسال المتناسق مع تدرج زر تسجيل الدخول
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 12))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleResetPassword(currentLang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              currentLang == 'ar' ? "إرسال الطلب" : (currentLang == 'en' ? "Send Request" : "Envoyer la demande"),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}