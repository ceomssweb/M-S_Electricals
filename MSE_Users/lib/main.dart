import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/config/firestore_config.dart';
import 'core/config/razorpay_config.dart';
import 'core/models/models.dart';
import 'features/auth/auth_state.dart';
import 'features/booking/booking_service.dart';
import 'features/notifications/notification_service.dart';
import 'features/profile/addresses_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/booking/booking_detail_page.dart';
import 'features/support/help_support_page.dart';
import 'features/admin/admin_analytics_page.dart';
import 'features/admin/admin_bookings_page.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/admin/admin_feedback_page.dart';
import 'features/admin/admin_login_page.dart';
import 'features/admin/admin_users_page.dart';
import 'features/notifications/notifications_page.dart';
import 'core/services/language_service.dart';
import 'core/services/permission_service.dart';

/// Entry point for the customer-facing M&S app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    RazorpayConfig.initDynamicConfig();
    PermissionService.requestInitialPermissions();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  runApp(const RasiCustomerApp());
}

class RasiCustomerApp extends StatelessWidget {
  const RasiCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => BookingService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LanguageService()..init()),
      ],
      child: Consumer<AuthState>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'M&S Electricals',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            routerConfig: _buildRouter(auth),
          );
        },
      ),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xFF0F2C59);       // Deep Navy Blue
  static const Color primaryLight = Color(0xFF1E3A8A);  // Medium Navy
  static const Color accent = Color(0xFFEE5922);        // Electric Orange
  static const Color accentLight = Color(0xFFFFF1EB);   // Soft Orange Tint
  static const Color background = Color(0xFFF8FAFC);    // Off-white
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

ThemeData _buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      color: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

GoRouter _buildRouter(AuthState auth) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.loggedIn;
        final loc = state.matchedLocation;
        final isAuthRoute = loc == '/login' || loc == '/register';
        if (loc == '/splash') return null;
        if (loggedIn && isAuthRoute) return '/home';

        if (loc.startsWith('/bookings') && !loggedIn) {
          return '/login';
        }

        if (loc.startsWith('/admin') && loc != '/admin/login') {
          if (!auth.isAdmin) {
            return '/admin/login';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
            path: '/splash', builder: (_, __) => const _SplashRedirector()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(
            path: '/admin/login',
            builder: (_, __) => const AdminLoginPage()),
        ShellRoute(
          builder: (_, __, child) => HomeShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const ServicesPage()),
            GoRoute(
                path: '/bookings',
                builder: (_, __) => const MyBookingsPage()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
            GoRoute(
                path: '/settings', builder: (_, __) => const SettingsPage()),
          ],
        ),
        GoRoute(
          path: '/service/:id',
          builder: (ctx, st) =>
              ServiceDetailPage(serviceId: st.pathParameters['id']!),
        ),
        GoRoute(
          path: '/book/:id',
          builder: (ctx, st) => BookingFormPage(
              serviceId: st.pathParameters['id']!,
              serviceTitle: st.uri.queryParameters['t'] ?? 'Service',
              basePrice:
                  double.tryParse(st.uri.queryParameters['p'] ?? '0') ?? 0),
        ),
        GoRoute(
          path: '/addresses',
          builder: (_, __) => const AddressesPage(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (_, __) => const EditProfilePage(),
        ),
        GoRoute(
          path: '/booking-detail/:id',
          builder: (ctx, st) =>
              BookingDetailPage(bookingId: st.pathParameters['id']!),
        ),
        GoRoute(
          path: '/support',
          builder: (_, __) => const HelpSupportPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (_, __) => const AdminUsersPage(),
        ),
        GoRoute(
          path: '/admin/bookings',
          builder: (_, __) => const AdminBookingsPage(),
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
    );

class _SplashRedirector extends StatefulWidget {
  const _SplashRedirector();
  @override
  State<_SplashRedirector> createState() => _SplashRedirectorState();
}

class _SplashRedirectorState extends State<_SplashRedirector> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/logo/M&S.PNG',
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('⚡', style: TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 16),
              Text('M&S Electricals',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Your trusted electrical partner'),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
}

// AUTH ----------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Image.asset(
                    'lib/assets/logo/M&S.PNG',
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.bolt, color: AppColors.primary, size: 32),
                          SizedBox(width: 8),
                          Text('M&S Electricals',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to manage and book electrical services',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pwd,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  await auth.signInWithEmail(
                                      _email.text.trim(), _pwd.text);
                                  if (mounted) setState(() => _busy = false);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'lib/assets/logo/M&S.PNG',
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'M&S Electricals',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join M&S Electricals for expert electrical services',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'John Doe',
                          prefixIcon: const Icon(Icons.person_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pwd,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password (min 6 chars)',
                          prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  await auth.registerWithEmail(
                                      _email.text.trim(), _pwd.text, _name.text.trim());
                                  if (mounted) setState(() => _busy = false);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/login'),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

// HOME SHELL ----------------------------------------------------------------

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Timer? _guestPromptTimer;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Start 2-minute periodic check for guest login prompt
    _guestPromptTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkAndShowGuestPrompt(),
    );
  }

  @override
  void dispose() {
    _guestPromptTimer?.cancel();
    super.dispose();
  }

  void _checkAndShowGuestPrompt() {
    if (!mounted || _dialogShowing) return;

    final auth = context.read<AuthState>();
    if (auth.loggedIn) return;

    final loc = GoRouterState.of(context).matchedLocation;
    // Do NOT show popup on signin, signup, or splash pages
    if (loc == '/login' || loc == '/register' || loc == '/splash') return;

    setState(() => _dialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Image.asset(
              'lib/assets/logo/M&S.PNG',
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.electrical_services,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sign In to M&S',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign in or create an account to easily book electrical services, manage addresses, and track technician dispatches.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/register');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Sign Up',
                        style: TextStyle(
                            color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/login');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Sign In',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Continue as Guest',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _dialogShowing = false);
      }
    });
  }

  List<(String, IconData, IconData, String)> _activeTabs(
      bool loggedIn, LanguageService lang) {
    if (loggedIn) {
      return [
        ('/home', Icons.home_outlined, Icons.home, lang.t('nav_home')),
        (
          '/bookings',
          Icons.receipt_long_outlined,
          Icons.receipt_long,
          lang.t('nav_bookings')
        ),
        ('/profile', Icons.person_outline, Icons.person, lang.t('nav_profile')),
        ('/settings', Icons.settings_outlined, Icons.settings, lang.t('nav_settings')),
      ];
    } else {
      return [
        ('/home', Icons.home_outlined, Icons.home, lang.t('nav_home')),
        ('/profile', Icons.person_outline, Icons.person, lang.t('nav_profile')),
        ('/settings', Icons.settings_outlined, Icons.settings, lang.t('nav_settings')),
      ];
    }
  }

  int _indexFor(
      String location, List<(String, IconData, IconData, String)> activeTabs) {
    for (var i = 0; i < activeTabs.length; i++) {
      if (location.startsWith(activeTabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final lang = context.watch<LanguageService>();
    final loc = GoRouterState.of(context).matchedLocation;
    final activeTabs = _activeTabs(auth.loggedIn, lang);
    final idx = _indexFor(loc, activeTabs);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _CustomTopBorderNavBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(activeTabs[i].$1),
        tabs: activeTabs,
      ),
    );
  }
}

class _CustomTopBorderNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<(String, IconData, IconData, String)> tabs;

  const _CustomTopBorderNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
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
            children: [
              for (int i = 0; i < tabs.length; i++) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => onDestinationSelected(i),
                    splashColor: AppColors.primary.withValues(alpha: 0.05),
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Active Top Border Indicator Line (Electric Orange)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3.5,
                          width: i == selectedIndex ? 36 : 0,
                          decoration: BoxDecoration(
                            color: i == selectedIndex
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(2),
                              bottomRight: Radius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          i == selectedIndex ? tabs[i].$3 : tabs[i].$2,
                          color: i == selectedIndex
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        Text(
                          tabs[i].$4,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == selectedIndex
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: i == selectedIndex
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// SERVICES (home) -----------------------------------------------------------

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  static const _categories = [
    ('All', '🛠️'),
    ('Wiring', '🔌'),
    ('Lighting', '💡'),
    ('AC', '❄️'),
    ('Fan', '🌀'),
    ('Repair', '🔧'),
    ('Inspection', '🔍'),
    ('Emergency', '🚨'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BookingService>();
    final auth = context.watch<AuthState>();
    final lang = context.watch<LanguageService>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'lib/assets/logo/M&S.PNG',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'M&S Electricals',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hi, ${auth.user?.displayName ?? (auth.loggedIn ? 'Customer' : lang.t('welcome_guest'))} 👋',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            lang.t('home_greeting'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Interactive Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: lang.t('home_search_hint'),
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Shortcut Icons
          Text(
            lang.t('home_categories_title'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = _categories[i];
                final isSelected = _selectedCategory == c.$1;
                final localizedCategory = lang.category(c.$1);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _selectedCategory = isSelected ? 'All' : c.$1;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 84,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.$2, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          localizedCategory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Header for services
          Row(
            children: [
              Text(
                _selectedCategory == 'All'
                    ? lang.t('home_popular_services')
                    : '${lang.t('home_category_prefix')}${lang.category(_selectedCategory)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_selectedCategory != 'All' || _searchCtrl.text.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _searchCtrl.clear();
                    });
                  },
                  child: Text(lang.t('home_reset_filters')),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Reactive Services Stream
          StreamBuilder<List<RasiService>>(
            stream: svc.servicesFiltered(
              categoryFilter: _selectedCategory,
              searchQuery: _searchCtrl.text,
            ),
            builder: (context, snap) {
              if (snap.hasError) {
                return _ErrorCard('Could not load services.', onRetry: () {
                  setState(() {});
                });
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return _buildEmptyState(context, lang);
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 920
                      ? 3
                      : (constraints.maxWidth > 620 ? 2 : 1);

                  if (crossAxisCount == 1) {
                    return Column(
                      children: [
                        for (final s in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ServiceCard(service: s),
                          ),
                      ],
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _ServiceCard(service: list[i]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageService lang) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⚡', style: TextStyle(fontSize: 38)),
              SizedBox(width: 10),
              Text('🔌', style: TextStyle(fontSize: 38)),
              SizedBox(width: 10),
              Text('🛠️', style: TextStyle(fontSize: 38)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'No services found matching "${_searchCtrl.text}"'
                : 'No services available in this category',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try resetting your category filters or searching for another term.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(lang.t('home_reset_filters')),
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
                _searchCtrl.clear();
              });
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final RasiService service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<BookingService>();
    final lang = context.watch<LanguageService>();
    final auth = context.watch<AuthState>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0C0F2C59),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/service/${service.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 40% Visual Frame Left
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 13, color: AppColors.accent),
                                  const SizedBox(width: 2),
                                  Text(
                                    service.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (service.discountPercent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${service.discountPercent.toStringAsFixed(0)}% OFF',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Center Emoji / Image Thumbnail
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: 62,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: service.imageUrl != null &&
                                      service.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(34),
                                      child: CachedNetworkImage(
                                        imageUrl: service.imageUrl!,
                                        fit: BoxFit.cover,
                                        width: 62,
                                        height: 68,
                                        errorWidget: (_, __, ___) => Text(
                                          service.iconEmoji,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      service.iconEmoji,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                            ),
                          ),
                        ),

                        // Bottom Duration Pill
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule,
                                    size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  '${service.durationMinutes} min',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 60% Content Column Right
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category & Favorite Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lang.category(service.category),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                service.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: service.isFavorite
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                svc.toggleFavorite(
                                    service.id, service.isFavorite);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Title
                        Text(
                          service.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Description Preview
                        Text(
                          service.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Price & Book CTA Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${service.finalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (service.discountPercent > 0)
                                  Text(
                                    '₹${service.basePrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 36,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  if (!auth.loggedIn) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        title: const Text(
                                            'Sign In Required to Book',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        content: const Text(
                                          'Please sign in or create an account to book electrical services and track technician dispatch.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              context.push('/register');
                                            },
                                            child: const Text('Sign Up'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              context.push('/login');
                                            },
                                            child: const Text('Sign In'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    context.push(
                                        '/book/${service.id}?t=${Uri.encodeComponent(service.title)}&p=${service.finalPrice}');
                                  }
                                },
                                child: const Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _ErrorCard extends StatelessWidget {
  final String msg;
  final VoidCallback? onRetry;

  const _ErrorCard(this.msg, {this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⚡', style: TextStyle(fontSize: 32)),
              SizedBox(width: 8),
              Text('🔧', style: TextStyle(fontSize: 32)),
              SizedBox(width: 8),
              Text('💡', style: TextStyle(fontSize: 32)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'M&S Electrical Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Services',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: onRetry ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

// SERVICE DETAIL ------------------------------------------------------------

class ServiceDetailPage extends StatelessWidget {
  final String serviceId;
  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Details')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirestoreConfig.db
            .collection('services')
            .doc(serviceId)
            .get(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Could not load service.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return const Center(child: Text('Service not found.'));
          }
          final s = RasiService.fromDoc(snap.data!);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child:
                    Text(s.iconEmoji, style: const TextStyle(fontSize: 96)),
              ),
              const SizedBox(height: 20),
              Text(s.title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(s.description,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _Chip(icon: Icons.timer, label: '${s.durationMinutes} min'),
                  const SizedBox(width: 8),
                  _Chip(
                      icon: Icons.star,
                      label:
                          '${s.rating.toStringAsFixed(1)} (${s.ratingCount})'),
                  const SizedBox(width: 8),
                  _Chip(icon: Icons.category, label: s.category),
                ],
              ),
              const SizedBox(height: 32),
              Card(
                color: const Color(0xFFF1F8E9),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text('Total Base Price',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('₹${s.basePrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(
                    '/book/${s.id}?t=${Uri.encodeComponent(s.title)}&p=${s.basePrice}'),
                child: const Text('Book Now'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}

// BOOKING FORM + RAZORPAY ---------------------------------------------------

class BookingFormPage extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;
  final double basePrice;
  const BookingFormPage(
      {super.key,
      required this.serviceId,
      required this.serviceTitle,
      required this.basePrice});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final _phone = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  bool _busy = false;
  bool _fetchingLocation = false;
  bool _saveAddressForLater = false;
  String _addressLabel = 'Home';
  String _paymentMode = 'razorpay'; // 'razorpay' or 'cod'
  String? _bookingId;
  UserAddress? _selectedSavedAddress;

  double get baseAmount => widget.basePrice;
  double get gstAmount => baseAmount * 0.18;
  double get totalPayable => baseAmount + gstAmount;

  @override
  void initState() {
    super.initState();
    final svc = context.read<BookingService>();
    final auth = context.read<AuthState>();
    _phone.text = auth.profile?.phoneNumber ?? '';

    svc.initRazorpay(
      onSuccess: _onPaySuccess,
      onError: _onPayError,
      onExternalWallet: (w) => _toast('External wallet: $w'),
    );
  }

  @override
  void dispose() {
    context.read<BookingService>().disposeRazorpay();
    _address.dispose();
    _notes.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final granted = await PermissionService.requestLocationPermission();
      if (!granted) {
        _toast('Location permission denied.');
        return;
      }
      _address.text = 'Main Street, Sector 4, Chennai, Tamil Nadu - 600001';
      _toast('Location fetched successfully!');
    } catch (e) {
      _toast('Location fetch error: $e');
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _onPaySuccess(String paymentId, String? orderId) async {
    final svc = context.read<BookingService>();
    if (_bookingId != null) {
      await svc.markPaid(bookingId: _bookingId!, paymentId: paymentId);
    }
    _toast('Payment successful! Booking confirmed.');
    if (mounted) context.go('/bookings');
  }

  void _onPayError(String msg) => _toast('Payment failed: $msg');

  Future<void> _confirmAndPay() async {
    if (_address.text.trim().isEmpty) {
      _toast('Please select or enter a service address.');
      return;
    }
    setState(() => _busy = true);
    final svc = context.read<BookingService>();
    final auth = context.read<AuthState>();

    try {
      if (_saveAddressForLater && auth.loggedIn) {
        try {
          final parts = _address.text.trim().split(',');
          await auth.addAddress(
            UserAddress(
              id: '',
              label: _addressLabel,
              houseNo: parts.isNotEmpty ? parts.first.trim() : 'Address',
              street: parts.length > 1 ? parts[1].trim() : 'Street',
              city: parts.length > 2 ? parts[2].trim() : 'City',
              pincode: '600001',
              phoneNumber: _phone.text.trim(),
            ),
          );
        } catch (_) {}
      }

      _bookingId = await svc.createBooking(
        serviceId: widget.serviceId,
        serviceTitle: widget.serviceTitle,
        scheduledAt: _scheduledAt,
        addressLine: _address.text.trim(),
        baseAmount: baseAmount,
        paymentMode: _paymentMode,
        notes: _notes.text.trim(),
      );

      if (_paymentMode == 'cod') {
        _toast('Booking confirmed with Cash on Delivery (COD)!');
        if (mounted) context.go('/bookings');
        return;
      }

      if (RazorpayConfig.isPlaceholder) {
        _toast('Booking confirmed (Test Mode)!');
        if (mounted) context.go('/bookings');
        return;
      }

      await svc.openCheckout(
        bookingId: _bookingId!,
        amount: totalPayable,
        contactPhone: _phone.text.trim(),
        contactEmail: auth.user?.email ?? '',
        description: widget.serviceTitle,
      );
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Service & 18% GST Fee Breakdown Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text('Service Base Amount',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const Spacer(),
                      Text('₹${baseAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('GST (18%)',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const Spacer(),
                      Text('₹${gstAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text('Grand Total Payable',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('₹${totalPayable.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scheduled Date & Time
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border)),
            leading: const Icon(Icons.event, color: AppColors.primary),
            title: const Text('Scheduled Time',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('EEE, dd MMM yyyy • hh:mm a')
                .format(_scheduledAt)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _scheduledAt,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)));
              if (d == null || !mounted) return;
              final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_scheduledAt));
              if (t == null || !mounted) return;
              setState(() {
                _scheduledAt =
                    DateTime(d.year, d.month, d.day, t.hour, t.minute);
              });
            },
          ),
          const SizedBox(height: 16),

          // Saved Address Selection Dropdown
          StreamBuilder<List<UserAddress>>(
            stream: auth.userAddresses(),
            builder: (context, snap) {
              if (snap.hasData && snap.data!.isNotEmpty) {
                final addrs = snap.data!;

                if (_selectedSavedAddress == null && _address.text.isEmpty) {
                  final def = addrs.firstWhere((a) => a.isDefault,
                      orElse: () => addrs.first);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedSavedAddress = def;
                        _address.text = def.formattedAddress;
                      });
                    }
                  });
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Select Saved Address',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/addresses'),
                              child: const Text('+ Manage'),
                            ),
                          ],
                        ),
                        DropdownButton<UserAddress>(
                          isExpanded: true,
                          value: _selectedSavedAddress,
                          hint: const Text('Choose a saved address'),
                          items: addrs.map((a) {
                            return DropdownMenuItem<UserAddress>(
                              value: a,
                              child: Text(
                                '${a.label}${a.isDefault ? ' (Default)' : ''}: ${a.formattedAddress}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSavedAddress = val;
                                _address.text = val.formattedAddress;
                                if (val.phoneNumber != null &&
                                    val.phoneNumber!.isNotEmpty) {
                                  _phone.text = val.phoneNumber!;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Service Address Field + Auto Fetch Location Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Service Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
            icon: _fetchingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, size: 18),
            label: const Text('Auto-Fetch Current Location'),
            onPressed: _fetchingLocation ? null : _fetchCurrentLocation,
          ),
          const SizedBox(height: 12),

          // Save Address Checkbox & Label Dropdown
          if (auth.loggedIn) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Save this address for future bookings',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: _saveAddressForLater,
              onChanged: (val) =>
                  setState(() => _saveAddressForLater = val ?? false),
            ),
            if (_saveAddressForLater)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Text('Address Label: ',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _addressLabel,
                      items: const [
                        DropdownMenuItem(value: 'Home', child: Text('Home')),
                        DropdownMenuItem(value: 'Work', child: Text('Work')),
                        DropdownMenuItem(
                            value: 'Office', child: Text('Office')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _addressLabel = val);
                      },
                    ),
                  ],
                ),
              ),
          ],

          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Contact Phone', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Notes for Technician (optional)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),

          // Payment Method Options (Pay Online vs Cash on Delivery)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Payment Method',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                RadioListTile<String>(
                  title: const Text('💳 Pay Online (Razorpay)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('UPI, Credit/Debit Cards, NetBanking'),
                  value: 'razorpay',
                  groupValue: _paymentMode,
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMode = val);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('💵 Cash on Delivery (COD)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pay technician in cash after service'),
                  value: 'cod',
                  groupValue: _paymentMode,
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMode = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm & Book Button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _confirmAndPay,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _paymentMode == 'cod'
                          ? 'Confirm Booking (COD)'
                          : 'Pay ₹${totalPayable.toStringAsFixed(0)} Online',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// MY BOOKINGS ---------------------------------------------------------------

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  BookingStatus? _selectedStatus;
  final TextEditingController _searchCtrl = TextEditingController();

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.assigned:
      case BookingStatus.inProgress:
        return Colors.indigo;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BookingService>();
    final lang = context.watch<LanguageService>();

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('bookings_title'))),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(lang.t('cat_All')),
                  selected: _selectedStatus == null,
                  onSelected: (_) => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                for (final st in BookingStatus.values) ...[
                  FilterChip(
                    label: Text(lang.t('status_${st.label}')),
                    selected: _selectedStatus == st,
                    onSelected: (_) => setState(() => _selectedStatus = st),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          // Search inside bookings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: lang.t('bookings_search_hint'),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: svc.myBookingsFiltered(
                statusFilter: _selectedStatus,
                searchQuery: _searchCtrl.text,
              ),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Could not load bookings.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(lang.t('bookings_empty'),
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final b = list[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        onTap: () => context.push('/booking-detail/${b.id}'),
                        title: Text(b.serviceTitle,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('EEE, dd MMM • hh:mm a')
                                  .format(b.scheduledAt)),
                              const SizedBox(height: 4),
                              Text(b.addressLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(b.status)
                                          .withValues(alpha: .15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                        lang.t('status_${b.status.label}'),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(b.status))),
                                  ),
                                  if (b.emailNotificationSent) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.mark_email_read,
                                        size: 16, color: Colors.green),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${b.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// PROFILE + SETTINGS --------------------------------------------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final svc = context.watch<BookingService>();
    final lang = context.watch<LanguageService>();
    final u = auth.user;

    if (!auth.loggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.t('profile_title'))),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'lib/assets/logo/M&S.PNG',
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.account_circle_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.t('profile_sign_in_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.t('profile_sign_in_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(lang.t('sign_up'),
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.push('/login'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(lang.t('sign_in'),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('profile_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Card(
            elevation: 0,
            color: const Color(0xFFE3F2FD),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1976D2),
                    child: Text(
                      (u?.displayName?.isNotEmpty ?? false)
                          ? u!.displayName![0].toUpperCase()
                          : '👤',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u?.displayName ?? 'Customer',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(u?.email ?? '',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 13)),
                        if (auth.profile?.phoneNumber != null &&
                            auth.profile!.phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(auth.profile!.phoneNumber,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                    onPressed: () => context.push('/edit-profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reactive Stats Row
          StreamBuilder<List<Booking>>(
            stream: svc.myBookings(),
            builder: (context, snap) {
              final bookings = snap.data ?? [];
              final total = bookings.length;
              final completed = bookings
                  .where((b) => b.status == BookingStatus.completed)
                  .length;
              final active = bookings
                  .where((b) =>
                      b.status == BookingStatus.pending ||
                      b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.assigned ||
                      b.status == BookingStatus.inProgress)
                  .length;

              return Row(
                children: [
                  _StatTile(
                      label: lang.t('profile_total_jobs'),
                      value: '$total',
                      icon: Icons.assignment_outlined),
                  const SizedBox(width: 8),
                  _StatTile(
                      label: lang.t('profile_active_jobs'),
                      value: '$active',
                      icon: Icons.engineering_outlined),
                  const SizedBox(width: 8),
                  _StatTile(
                      label: lang.t('profile_completed_jobs'),
                      value: '$completed',
                      icon: Icons.verified_outlined),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Navigation Links Card
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: Color(0xFF1976D2)),
                  title: Text(lang.t('profile_saved_addresses')),
                  subtitle: Text(lang.t('profile_saved_addresses_sub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/addresses'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: Color(0xFF1976D2)),
                  title: Text(lang.t('profile_edit_personal_info')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/edit-profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent,
                      color: Color(0xFF1976D2)),
                  title: Text(lang.t('profile_help_support')),
                  subtitle: Text(lang.t('profile_help_support_sub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/support'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined,
                      color: Color(0xFF1976D2)),
                  title: Text(lang.t('profile_app_settings')),
                  subtitle: Text(lang.t('profile_app_settings_sub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            icon: const Icon(Icons.logout),
            label: Text(lang.t('sign_out')),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationService>();
    final auth = context.watch<AuthState>();
    final lang = context.watch<LanguageService>();

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('settings_title'))),
      body: ListView(
        children: [
          if (auth.loggedIn) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.displayName ?? 'Valued Customer',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?.email ?? 'Logged in',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => auth.signOut(),
                    icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                    label: Text(lang.t('sign_out'),
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(lang.t('settings_notifications_header'),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2))),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: Text(lang.t('settings_push_notifications')),
              subtitle: Text(lang.t('settings_push_sub')),
              value: notif.pushEnabled,
              onChanged: (val) => notif.setPushEnabled(val),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.email_outlined),
              title: Text(lang.t('settings_email_notifications')),
              subtitle: Text(lang.t('settings_email_sub')),
              value: notif.emailEnabled,
              onChanged: (val) => notif.setEmailEnabled(val),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.send),
                label: Text(lang.t('settings_send_test_push')),
                onPressed: () {
                  notif.sendTestPushNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.notifications, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Test Push Alert: ${notif.lastNotificationBody ?? 'Active!'}'),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1976D2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ] else ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'lib/assets/logo/M&S.PNG',
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_circle_outlined,
                        size: 48,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lang.t('settings_account_auth'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.t('settings_account_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(
                                color: AppColors.accent, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(lang.t('sign_up'),
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.push('/login'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(lang.t('sign_in')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(lang.t('settings_app_preferences'),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
          if (auth.loggedIn)
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(lang.t('settings_language')),
              subtitle: Text(lang.currentLanguageName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                          title: Text(lang.t('settings_select_language'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold))),
                      ListTile(
                          title: const Text('English'),
                          trailing: lang.currentLanguageCode == 'en'
                              ? const Icon(Icons.check, color: Colors.blue)
                              : null,
                          onTap: () {
                            lang.setLanguage('en');
                            Navigator.pop(ctx);
                          }),
                      ListTile(
                          title: const Text('Tamil (தமிழ்)'),
                          trailing: lang.currentLanguageCode == 'ta'
                              ? const Icon(Icons.check, color: Colors.blue)
                              : null,
                          onTap: () {
                            lang.setLanguage('ta');
                            Navigator.pop(ctx);
                          }),
                      ListTile(
                          title: const Text('Hindi (हिंदी)'),
                          trailing: lang.currentLanguageCode == 'hi'
                              ? const Icon(Icons.check, color: Colors.blue)
                              : null,
                          onTap: () {
                            lang.setLanguage('hi');
                            Navigator.pop(ctx);
                          }),
                    ],
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(lang.t('settings_about_app')),
            subtitle: const Text('M&S Electricals v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'M&S Electricals',
                applicationVersion: '1.0.0',
                applicationIcon:
                    const Text('⚡', style: TextStyle(fontSize: 32)),
                children: [
                  const Text(
                      'Your trusted electrical service partner. Professional wiring, AC repair, lighting & emergency services.'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(lang.t('settings_privacy_policy')),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(lang.t('settings_privacy_policy')),
                  content: const SingleChildScrollView(
                    child: Text(
                        'M&S Electricals respects your privacy. All customer location addresses, phone numbers, and booking records are stored securely in encrypted cloud data stores and used strictly for dispatching qualified electrical technicians.'),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
