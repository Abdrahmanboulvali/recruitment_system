import 'package:flutter/material.dart';

class ApiConfig {
  // --- إعدادات الاتصال ---
  // ملاحظة: إذا كنت تستخدم محاكي أندرويد، استبدل 127.0.0.1 بـ 10.0.2.2
  static const String baseUrl = "http://127.0.0.1:8000";

  // --- ألوان الخلفية والبطاقات (نفس ثيم الويب) ---
  static const Color kBgMain = Color(0xFF0F172A);      // الخلفية العميقة
  static const Color kBgCard = Color(0xFF1E293B);      // لون البطاقات (Sidebar)
  static const Color kPrimary = Color(0xFF6366F1);     // اللون البنفسجي الأساسي
  static const Color kAccent = Color(0xFF4338CA);      // لون متدرج (Indigo)

  // --- ألوان النصوص ---
  static const Color kTextMain = Color(0xFFF8FAFC);    // النص الأبيض الأساسي
  static const Color kTextMuted = Color(0xFF64748B);   // النص الرمادي (المكتوم)

  // --- ألوان إضافية للحالات (إحصائيات النجاح والفشل) ---
  static const Color kSuccess = Color(0xFF10B981);     // أخضر (Emerald)
  static const Color kWarning = Color(0xFFF59E0B);     // برتقالي (Amber)
  static const Color kError = Color(0xFFEF4444);       // أحمر (Rose)

  // --- إعدادات التنسيق (Styles) ---
  static BorderRadius kBorderRadius = BorderRadius.circular(16);
  static List<BoxShadow> kCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  // --- خطوط الكتابة ---
  static const TextStyle kHeaderStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: kTextMain,
    letterSpacing: -0.5,
  );

  static const TextStyle kSubtitleStyle = TextStyle(
    fontSize: 14,
    color: kTextMuted,
    fontWeight: FontWeight.w500,
  );
}