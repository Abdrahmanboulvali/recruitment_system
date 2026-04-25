import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'screens/espace_candidat_screen.dart';
import 'screens/mes_candidatures_screen.dart';
import 'screens/postuler_screen.dart';
import 'screens/profile_entreprise_screen.dart';

const List<String> dgRoles = [
  'DG',
  'DG_COMPANY',
  'DG_GOV',
  'DG_BUSINESS',
  'PROPRIÉTAIRE D\'ENTREPRISE',
  'HOMME D\'AFFAIRES'
];

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recrutement System',
      themeMode: _themeMode,
      // تعريف الثيم المضيء بشكل كامل
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: ApiConfig.kPrimary,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        cardColor: Colors.white,
        dividerColor: Colors.black12,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // تعريف الثيم المظلم بشكل كامل
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: ApiConfig.kPrimary,
        scaffoldBackgroundColor: ApiConfig.kBgMain,
        cardColor: ApiConfig.kBgCard,
        dividerColor: Colors.white12,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      initialRoute: '/espace-candidat', // تم تغييرها من /login لتعمل كواجهة أولى
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/all-stats': (context) => AllStatsScreen(),
        '/manage-offres': (context) => ManageOffresScreen(),
        '/profile': (context) => ProfileScreen(),
        '/espace-candidat': (context) => const EspaceCandidat(),
        '/manage-enterprises': (context) => ManageEnterprisesScreen(),
        '/manage-payments': (context) => ManagePaymentsScreen(),
        '/users': (context) => UsersScreen(),
        '/manage-candidatures': (context) => const ManageCandidaturesScreen(),
        '/subscriptions': (context) => const SubscriptionsScreen(),
        '/mes-candidatures': (context) => const MesCandidaturesScreen(),
        '/postuler': (context) => const PostulerScreen(),
        '/profile-entreprise': (context) => const ProfileEntrepriseScreen(),
      },
    );
  }
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _storage = const FlutterSecureStorage();
  String _user = "Utilisateur";
  String _role = "";
  String? _enterpriseId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  _loadUserInfo() async {
    String? u = await _storage.read(key: 'username');
    String? r = await _storage.read(key: 'role');
    String? eId = await _storage.read(key: 'enterprise_id');
    if (mounted) {
      setState(() {
        _user = u ?? "Utilisateur";
        _role = (r ?? "").toUpperCase().trim();
        _enterpriseId = eId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuperAdmin = _role == 'SUPER_ADMIN';
    bool isDG = dgRoles.contains(_role);
    bool isAgent = _role == 'ADMIN' || _role == 'RESPONSABLE RH';
    bool isCandidat = _role == 'CANDIDAT' || _role == "";

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: isDark ? ApiConfig.kBgCard : ApiConfig.kPrimary),
            accountName: Text(_user, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(_role.isEmpty ? "Visiteur" : _role, style: TextStyle(color: isDark ? ApiConfig.kPrimary : Colors.white70, fontSize: 12)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: isDark ? ApiConfig.kPrimary : Colors.white,
              child: Text(_user.isNotEmpty ? _user[0].toUpperCase() : "U",
                  style: TextStyle(fontSize: 24, color: isDark ? Colors.white : ApiConfig.kPrimary)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isSuperAdmin) ...[
                  _buildItem(context, Icons.analytics_outlined, "Stats Globales", '/all-stats'),
                  _buildItem(context, Icons.business_rounded, "Manage Enterprises", '/manage-enterprises'),
                  _buildItem(context, Icons.payments_outlined, "Paiements", '/manage-payments'),
                ],
                if (isDG) ...[
                  _buildItem(context, Icons.dashboard_outlined, "Tableau de bord", '/dashboard'),
                  _buildItem(context, Icons.card_membership_outlined, "Subscriptions", '/subscriptions'),
                ],
                if (isDG || isAgent) ...[
                  _buildItem(context, Icons.work_outline, "Gestion Offres", '/manage-offres'),
                  _buildItem(context, Icons.assignment_turned_in_outlined, "Candidatures", '/manage-candidatures'),
                  if (_enterpriseId != null && _enterpriseId!.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.business, color: isDark ? Colors.white70 : Colors.black54),
                      title: const Text("Mon Entreprise", style: TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/profile-entreprise',
                          arguments: {'id': int.parse(_enterpriseId!)}
                        );
                      },
                    ),
                ],

                if (isCandidat) ...[
                  _buildItem(context, Icons.search, "Explorer Offres", '/espace-candidat'),
                  if (_role != "") // لا تظهر "طلباتي" للزائر غير المسجل
                    _buildItem(context, Icons.history_edu_outlined, "Mes Postulations", '/mes-candidatures'),
                ],
                if (isDG || isSuperAdmin)
                  _buildItem(context, Icons.people_outline, "Users System", '/users'),

                _buildItem(context, Icons.person_outline, "Mon Profil", '/profile'),

                Divider(color: theme.dividerColor),

                ListTile(
                  leading: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    color: isDark ? Colors.orangeAccent : Colors.indigo),
                  title: Text(isDark ? "Mode Clair" : "Mode Sombre",
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  onTap: () => MyApp.of(context).toggleTheme(),
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor),
          _buildItem(context, Icons.logout_rounded, "Déconnexion", '/espace-candidat', isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String route, {bool isLogout = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black54)),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.redAccent : (isDark ? Colors.white : Colors.black87), fontSize: 14)),
      onTap: () async {
        if (isLogout) {
          await _storage.deleteAll();
          if (!mounted) return;
          // التوجيه لصفحة البداية (الفضاء العام) بعد الخروج
          Navigator.pushNamedAndRemoveUntil(context, '/espace-candidat', (r) => false);
        } else {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _screens = [OffresScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.cardColor,
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