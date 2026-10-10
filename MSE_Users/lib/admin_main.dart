import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'features/admin/admin_analytics_page.dart';
import 'features/admin/admin_bookings_page.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/admin/admin_feedback_page.dart';
import 'features/admin/admin_login_page.dart';
import 'features/admin/admin_services_page.dart';
import 'features/admin/admin_users_page.dart';
import 'features/auth/auth_state.dart';
import 'features/booking/booking_service.dart';
import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.adminWeb,
    );
  } catch (e) {
    debugPrint('Admin Firebase init failed: $e');
  }
  runApp(const MSEAdminApp());
}

class MSEAdminApp extends StatelessWidget {
  const MSEAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => BookingService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: Consumer<AuthState>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'M&S Electricals - Admin Portal',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0F2C59),
                primary: const Color(0xFF0F2C59),
                secondary: const Color(0xFFEE5922),
              ),
              textTheme: GoogleFonts.interTextTheme(),
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1E293B),
                elevation: 0,
                centerTitle: true,
              ),
            ),
            routerConfig: _buildAdminRouter(auth),
          );
        },
      ),
    );
  }
}

GoRouter _buildAdminRouter(AuthState auth) => GoRouter(
      initialLocation: '/admin',
      refreshListenable: auth,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isLoggingIn = loc == '/admin/login';
        final isAdmin = auth.isAdmin;

        if (!isAdmin && !isLoggingIn) {
          return '/admin/login';
        }
        if (isAdmin && isLoggingIn) {
          return '/admin';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/admin/login',
          builder: (_, __) => const AdminLoginPage(),
        ),
        ShellRoute(
          builder: (_, __, child) => _AdminNavBarShell(child: child),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (_, __) => const AdminDashboardPage(),
            ),
            GoRoute(
              path: '/admin/services',
              builder: (_, __) => const AdminServicesPage(),
            ),
            GoRoute(
              path: '/admin/bookings',
              builder: (_, __) => const AdminBookingsPage(),
            ),
            GoRoute(
              path: '/admin/users',
              builder: (_, __) => const AdminUsersPage(),
            ),
            GoRoute(
              path: '/admin/analytics',
              builder: (_, __) => const AdminAnalyticsPage(),
            ),
            GoRoute(
              path: '/admin/feedback',
              builder: (_, __) => const AdminFeedbackPage(),
            ),
          ],
        ),
      ],
    );

class _AdminNavBarShell extends StatelessWidget {
  final Widget child;
  const _AdminNavBarShell({required this.child});

  static const _adminTabs = [
    ('/admin', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    ('/admin/services', Icons.electrical_services_outlined,
        Icons.electrical_services, 'Services'),
    ('/admin/bookings', Icons.assignment_outlined, Icons.assignment,
        'Bookings'),
    ('/admin/users', Icons.people_outline, Icons.people, 'Users'),
    ('/admin/analytics', Icons.analytics_outlined, Icons.analytics,
        'Analytics'),
    ('/admin/feedback', Icons.rate_review_outlined, Icons.rate_review,
        'Feedback'),
  ];

  int _indexFor(String loc) {
    for (var i = 0; i < _adminTabs.length; i++) {
      if (loc == _adminTabs[i].$1) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);
    final auth = context.watch<AuthState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                // Left Navigation Sidebar
                Container(
                  width: 240,
                  color: const Color(0xFF0F2C59),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Header Logo & Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'lib/assets/logo/M&S.PNG',
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.admin_panel_settings,
                                  color: Color(0xFF0F2C59),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'M&S Portal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Admin Control',
                                    style: TextStyle(
                                      color: Color(0xFFEE5922),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 16),

                      // Navigation Items
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _adminTabs.length,
                          itemBuilder: (ctx, i) {
                            final tab = _adminTabs[i];
                            final isSelected = i == idx;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: isSelected
                                    ? const Color(0xFFEE5922)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => context.go(tab.$1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? tab.$3 : tab.$2,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          tab.$4,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom Admin User Profile Card
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFEE5922),
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.user?.displayName ?? 'Admin User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    auth.user?.email ?? 'admin@ms.com',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout,
                                  color: Colors.white70, size: 18),
                              tooltip: 'Sign Out',
                              onPressed: () => auth.signOut(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(child: child),
              ],
            ),
          );
        }

        // Mobile Layout
        return Scaffold(
          body: child,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _adminTabs.length; i++)
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go(_adminTabs[i].$1),
                          splashColor:
                              const Color(0xFF0F2C59).withValues(alpha: 0.05),
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 3.5,
                                  width: i == idx ? 28 : 0,
                                  decoration: BoxDecoration(
                                    color: i == idx
                                        ? const Color(0xFFEE5922)
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(2),
                                      bottomRight: Radius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Icon(
                                  i == idx
                                      ? _adminTabs[i].$3
                                      : _adminTabs[i].$2,
                                  color: i == idx
                                      ? const Color(0xFF0F2C59)
                                      : const Color(0xFF64748B),
                                  size: 20,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _adminTabs[i].$4,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: i == idx
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: i == idx
                                          ? const Color(0xFF0F2C59)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
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
      },
    );
  }
}
