import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// استيراد الشاشات
import 'screens/offres_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/all_stats_screen.dart';
import 'screens/manage_offres_screen.dart';
import 'screens/profile_screen.dart';
import 'api_config.dart';
import 'screens/manage_enterprises_screen.dart';
import 'screens/manage_payments_screen.dart';
import 'screens/users_screen.dart';
import 'screens/manage_candidatures_screen.dart';
import 'screens/subscriptions_screen.dart';


const List<String> dgRoles = [
  'DG',
  'DG_COMPANY',
  'DG_GOV',
  'DG_BUSINESS',
  'PROPRIÉTAIRE D\'ENTREPRISE',
  'HOMME D\'AFFAIRES'
];

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recrutement System',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: ApiConfig.kPrimary,
        scaffoldBackgroundColor: ApiConfig.kBgMain,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ApiConfig.kPrimary,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // تم حذف const لضمان تحديث البيانات عند التنقل
        '/dashboard': (context) => DashboardScreen(),
        '/all-stats': (context) => AllStatsScreen(),
        '/manage-offres': (context) => ManageOffresScreen(),
        '/profile': (context) => ProfileScreen(),
        '/espace-candidat': (context) => MainNavigation(),
        '/manage-enterprises': (context) => ManageEnterprisesScreen(),
        '/manage-payments': (context) => ManagePaymentsScreen(),
        '/users': (context) => UsersScreen(),
        '/manage-candidatures': (context) => const ManageCandidaturesScreen(),
        '/subscriptions': (context) => const SubscriptionsScreen(),
      },
    );
  }
}

// --- مكون القائمة الجانبية الموحد (المطابق لـ Sidebar الويب) ---
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _storage = const FlutterSecureStorage();
  String _user = "Utilisateur";
  String _role = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  _loadUserInfo() async {
    String? u = await _storage.read(key: 'username');
    String? r = await _storage.read(key: 'role');
    if (mounted) {
      setState(() {
        _user = u ?? "Utilisateur";
        _role = (r ?? "").toUpperCase().trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // منطق تحديد الصلاحيات بناءً على القيم التي أرسلتها من الويب
    bool isSuperAdmin = _role == 'SUPER_ADMIN';
    bool isDG = dgRoles.contains(_role);
    bool isAgent = _role == 'ADMIN' || _role == 'RESPONSABLE RH';
    bool isCandidat = _role == 'CANDIDAT';

    return Drawer(
      backgroundColor: ApiConfig.kBgMain,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: ApiConfig.kBgCard),
            accountName: Text(_user, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(_role, style: const TextStyle(color: ApiConfig.kPrimary, fontSize: 12)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: ApiConfig.kPrimary,
              child: Text(_user.isNotEmpty ? _user[0].toUpperCase() : "U",
                  style: const TextStyle(fontSize: 24, color: Colors.white)),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. روابط الـ SUPER_ADMIN
                if (isSuperAdmin) ...[
                  _buildItem(context, Icons.analytics_outlined, "Stats Globales", '/all-stats'),
                  _buildItem(context, Icons.business_rounded, "Manage Enterprises", '/manage-enterprises'),
                  _buildItem(context, Icons.payments_outlined, "Paiements", '/manage-payments'),
                ],

                // 2. روابط الـ DG (أصحاب الشركات)
                if (isDG) ...[
                  _buildItem(context, Icons.dashboard_outlined, "Tableau de bord", '/dashboard'),
                  _buildItem(context, Icons.card_membership_outlined, "Subscriptions", '/subscriptions'),
                ],

                // 3. روابط مشتركة (DG + Agent/RH)
                if (isDG || isAgent) ...[
                  _buildItem(context, Icons.work_outline, "Gestion Offres", '/manage-offres'),
                  _buildItem(context, Icons.assignment_turned_in_outlined, "Candidatures", '/manage-candidatures'),
                ],

                // 4. روابط الـ CANDIDAT
                if (isCandidat) ...[
                  _buildItem(context, Icons.search, "Explorer Offres", '/espace-candidat'),
                  _buildItem(context, Icons.history_edu_outlined, "Mes Candidatures", '/mes-candidatures'),
                ],

                // 5. روابط عامة
                if (isDG || isSuperAdmin)
                  _buildItem(context, Icons.people_outline, "Users System", '/users'),

                _buildItem(context, Icons.person_outline, "Mon Profil", '/profile'),
              ],
            ),
          ),

          const Divider(color: Colors.white12),
          _buildItem(context, Icons.logout_rounded, "Déconnexion", '/login', isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String route, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.redAccent : Colors.white70),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.redAccent : Colors.white, fontSize: 14)),
      onTap: () async {
        if (isLogout) {
          await _storage.deleteAll();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
        } else {
          // التعديل الأساسي: إغلاق القائمة ثم استخدام pushNamed لترك مسار للعودة
          Navigator.pop(context); // إغلاق الـ Drawer أولاً
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

// --- الهيكل الأساسي للتنقل السفلي (Candidat) ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // تم حذف const هنا لأن الشاشات ديناميكية
  final List<Widget> _screens = [OffresScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // تم حذف const لتمكين تحديث البيانات داخل القائمة
      drawer: AppDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ApiConfig.kBgCard,
        selectedItemColor: ApiConfig.kPrimary,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explorer"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}