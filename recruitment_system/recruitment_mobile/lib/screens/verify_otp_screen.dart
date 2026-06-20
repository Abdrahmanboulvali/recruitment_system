import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email; // استلام الإيميل من صفحة التسجيل

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _error = '';
  int _timerSeconds = 120;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _canResend = false;
    _timerSeconds = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _verifyOtp(String currentLang) async {
    if (_otpController.text.length != 6) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': _otpController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        String successMsg = currentLang == 'ar' ? "تم تفعيل الحساب بنجاح!" : "Compte activé avec succès !";
        _showSnack(successMsg, Colors.green);
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else if (response.statusCode == 202) {
        String pendingMsg = currentLang == 'ar' ? "تم التحقق من البريد الإلكتروني! في انتظار المراجعة والموافقة." : "Email vérifié ! En attente d'approbation.";
        _showSnack(pendingMsg, Colors.blue);
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() => _error = data['error'] ?? (currentLang == 'ar' ? "الرمز غير صحيح." : "Code incorrect."));
      }
    } catch (e) {
      setState(() => _error = currentLang == 'ar' ? "خطأ في الاتصال بالخادم." : "Erreur de connexion.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp(String currentLang) async {
    if (!_canResend) return;
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/resend-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      String resendMsg = currentLang == 'ar' ? "تم إرسال رمز تحقق جديد بنجاح." : "Un nouveau code a été envoyé.";
      _showSnack(resendMsg, Colors.green);
      _startTimer();
    } catch (e) {
      String errResend = currentLang == 'ar' ? "حدث خطأ أثناء إرسال الرمز." : "Erreur lors de l'envoi.";
      _showSnack(errResend, Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: Stack(
        children: [
          // Blobs (الخلفية الملونة كما في الويب)
          Positioned(top: -50, left: -50, child: _buildBlob(Colors.indigo.withOpacity(0.2))),
          Positioned(bottom: -50, right: -50, child: _buildBlob(Colors.teal.withOpacity(0.15))),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                decoration: BoxDecoration(
                  color: isDark ? ApiConfig.kBgCard.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconCircle(),
                    const SizedBox(height: 20),
                    Text(
                      currentLang == 'ar' ? "التحقق من الحساب" : "Vérification",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentLang == 'ar' ? "تم إرسال رمز التحقق إلى \n${widget.email}" : "Code envoyé à \n${widget.email}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)
                    ),
                    const SizedBox(height: 40),

                    // حقل إدخال الـ OTP
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, letterSpacing: 15, fontWeight: FontWeight.bold, color: ApiConfig.kPrimary),
                      decoration: InputDecoration(
                        counterText: "",
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _error.isNotEmpty ? Colors.red : Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: ApiConfig.kPrimary, width: 2)),
                      ),
                      onChanged: (val) { if (val.length == 6) _verifyOtp(currentLang); },
                    ),

                    const SizedBox(height: 20),

                    // التايمر
                    Text(
                      _timerSeconds > 0
                          ? (currentLang == 'ar' ? "تنتهي صلاحية الرمز خلال: ${_formatTime(_timerSeconds)}" : "Expire dans: ${_formatTime(_timerSeconds)}")
                          : (currentLang == 'ar' ? "انتهت صلاحية الرمز" : "Code expiré"),
                      style: TextStyle(color: _timerSeconds > 0 ? ApiConfig.kPrimary : Colors.red, fontWeight: FontWeight.bold),
                    ),

                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],

                    const SizedBox(height: 35),

                    _buildSubmitButton(currentLang),

                    const SizedBox(height: 30),

                    // زر إعادة الإرسال
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(currentLang == 'ar' ? "لم يصلك الرمز؟ " : "Pas reçu ? "),
                        TextButton(
                          onPressed: _canResend ? () => _resendOtp(currentLang) : null,
                          child: Text(
                            currentLang == 'ar' ? "إعادة إرسال" : "Renvoyer",
                            style: TextStyle(color: _canResend ? ApiConfig.kPrimary : Colors.grey, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          // زر الرجوع المترجم حسب اتجاه اللغة
          Positioned(
            top: 50,
            left: currentLang == 'ar' ? null : 20,
            right: currentLang == 'ar' ? 20 : null,
            child: IconButton(
              icon: Icon(currentLang == 'ar' ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle() => Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: ApiConfig.kPrimary.withOpacity(0.1)), child: const Center(child: Text("🔐", style: TextStyle(fontSize: 30))));

  Widget _buildSubmitButton(String currentLang) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: _isLoading || _otpController.text.length != 6 ? null : () => _verifyOtp(currentLang),
        child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              currentLang == 'ar' ? "التحقق من الرمز" : "Vérifier le code",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
      ),
    );
  }
}