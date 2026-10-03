import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/config/razorpay_config.dart';
import 'core/models/models.dart';
import 'features/auth/auth_state.dart';
import 'features/booking/booking_service.dart';
import 'features/notifications/notification_service.dart';
import 'features/profile/addresses_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/booking/booking_detail_page.dart';
import 'features/support/help_support_page.dart';

/// Entry point for the customer-facing M&S app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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

ThemeData _buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1F2937),
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        if (!loggedIn && !isAuthRoute) return '/login';
        if (loggedIn && isAuthRoute) return '/home';
        return null;
      },
      routes: [
        GoRoute(
            path: '/splash', builder: (_, __) => const _SplashRedirector()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
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
      final auth = context.read<AuthState>();
      context.go(auth.loggedIn ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 72)),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              const Text('⚡', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Welcome back',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Text('Sign in to book electrical services',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwd,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await auth.signInWithEmail(
                            _email.text.trim(), _pwd.text);
                        if (mounted) setState(() => _busy = false);
                      },
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign in'),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('New here? Create an account'),
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Full name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwd,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password (min 6)',
                    border: OutlineInputBorder()),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await auth.registerWithEmail(_email.text.trim(),
                            _pwd.text, _name.text.trim());
                        if (mounted) setState(() => _busy = false);
                      },
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// HOME SHELL ----------------------------------------------------------------

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    ('/home', Icons.home_outlined, Icons.home, 'Home'),
    ('/bookings', Icons.receipt_long_outlined, Icons.receipt_long, 'Bookings'),
    ('/profile', Icons.person_outline, Icons.person, 'Profile'),
    ('/settings', Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
                icon: Icon(t.$2), selectedIcon: Icon(t.$3), label: t.$4),
        ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('M&S Electricals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hi, ${auth.user?.displayName ?? 'Customer'} 👋',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'What electrical service do you need today?',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // Interactive Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
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
                const Icon(Icons.search, color: Color(0xFF1976D2)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search wiring, AC repair, lighting...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
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
          const Text(
            'Categories & Shortcuts',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
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
                          ? const Color(0xFF1976D2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1976D2).withValues(alpha: 0.3),
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
                          c.$1,
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
                    ? 'Popular Services'
                    : 'Category: $_selectedCategory',
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
                  child: const Text('Reset filters'),
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
                return const _ErrorCard('Could not load services.');
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No services found matching "${_searchCtrl.text}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'All';
                            _searchCtrl.clear();
                          });
                        },
                        child: const Text('View All Services'),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [for (final s in list) _ServiceCard(service: s)],
              );
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/service/${service.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(service.iconEmoji,
                    style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(service.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(service.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Text('• ${service.durationMinutes} min',
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      service.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: service.isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      svc.toggleFavorite(service.id, service.isFavorite);
                    },
                  ),
                  Text('₹${service.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1976D2))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  const _ErrorCard(this.msg);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
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
        future: FirebaseFirestore.instance
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
  String? _bookingId;
  UserAddress? _selectedSavedAddress;

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
      _bookingId = await svc.createBooking(
        serviceId: widget.serviceId,
        serviceTitle: widget.serviceTitle,
        scheduledAt: _scheduledAt,
        addressLine: _address.text.trim(),
        amount: widget.basePrice,
        notes: _notes.text.trim(),
      );
      if (RazorpayConfig.isPlaceholder) {
        _toast('Booking submitted successfully!');
        if (mounted) context.go('/bookings');
        return;
      }
      await svc.openCheckout(
        bookingId: _bookingId!,
        amount: widget.basePrice,
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                      child: Text(widget.serviceTitle,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600))),
                  Text('₹${widget.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1976D2))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.event, color: Color(0xFF1976D2)),
            title: const Text('Scheduled Time'),
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

          // Select Saved Address Dropdown
          StreamBuilder<List<UserAddress>>(
            stream: auth.userAddresses(),
            builder: (context, snap) {
              if (snap.hasData && snap.data!.isNotEmpty) {
                final addrs = snap.data!;

                // Auto-fill default address if unselected
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
                            const Icon(Icons.my_location,
                                color: Color(0xFF1976D2), size: 20),
                            const SizedBox(width: 8),
                            const Text('Select Saved Address',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/addresses'),
                              child: const Text('+ Add New'),
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
                                '${a.label}: ${a.formattedAddress}',
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

          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Service Address', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Contact Phone', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Notes for Technician (optional)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _confirmAndPay,
            child: _busy
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(RazorpayConfig.isPlaceholder
                    ? 'Confirm Booking (Test Mode)'
                    : 'Pay ₹${widget.basePrice.toStringAsFixed(0)}'),
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

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedStatus == null,
                  onSelected: (_) => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                for (final st in BookingStatus.values) ...[
                  FilterChip(
                    label: Text(st.label),
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
                hintText: 'Search bookings by service name...',
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
                        const Text('No matching bookings found.',
                            style: TextStyle(color: Colors.black54)),
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
                                    child: Text(b.status.label,
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
    final u = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                      label: 'Total Jobs',
                      value: '$total',
                      icon: Icons.assignment_outlined),
                  const SizedBox(width: 8),
                  _StatTile(
                      label: 'Active',
                      value: '$active',
                      icon: Icons.engineering_outlined),
                  const SizedBox(width: 8),
                  _StatTile(
                      label: 'Completed',
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
                  title: const Text('Saved Addresses'),
                  subtitle: const Text('Manage home, office & work addresses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/addresses'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: Color(0xFF1976D2)),
                  title: const Text('Edit Personal Info'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/edit-profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent,
                      color: Color(0xFF1976D2)),
                  title: const Text('Help & Support'),
                  subtitle: const Text('24/7 hotline, FAQs & feedback'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/support'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined,
                      color: Color(0xFF1976D2)),
                  title: const Text('App Settings'),
                  subtitle: const Text('Push & email notifications, language'),
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
            label: const Text('Sign Out'),
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
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1976D2)),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Notifications Preferences',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2))),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive instant booking status alerts'),
            value: notif.pushEnabled,
            onChanged: (val) => notif.setPushEnabled(val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive invoices and status updates via email'),
            value: notif.emailEnabled,
            onChanged: (val) => notif.setEmailEnabled(val),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Send Test Push Notification'),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('App & Preferences',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2))),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => ListView(
                  shrinkWrap: true,
                  children: [
                    const ListTile(
                        title: Text('Select Language',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(
                        title: const Text('English (Default)'),
                        trailing: const Icon(Icons.check, color: Colors.blue),
                        onTap: () => Navigator.pop(ctx)),
                    ListTile(
                        title: const Text('Tamil (தமிழ்)'),
                        onTap: () => Navigator.pop(ctx)),
                    ListTile(
                        title: const Text('Hindi (हिंदी)'),
                        onTap: () => Navigator.pop(ctx)),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            subtitle: const Text('M&S Electricals v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'M&S Electricals',
                applicationVersion: '1.0.0',
                applicationIcon: const Text('⚡', style: TextStyle(fontSize: 32)),
                children: [
                  const Text(
                      'Your trusted electrical service partner. Professional wiring, AC repair, lighting & emergency services.'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Privacy Policy'),
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
