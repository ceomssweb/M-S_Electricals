import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../auth/auth_state.dart';
import 'notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Bookings', 'Promos', 'System'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final notifService = context.watch<NotificationService>();
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Guest Mode Warning Banner
          if (!auth.loggedIn)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEE5922)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEE5922), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Guest Mode Active',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sign in to sync your live booking alerts & technician status.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign In',
                        style: TextStyle(
                            color: Color(0xFFEE5922),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Category Filters
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0F2C59),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Live Notifications List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Real-time FCM Test Alert if triggered
                if (notifService.lastNotificationTitle != null)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: const Color(0xFFFFF1EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFEE5922)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEE5922),
                        child: const Icon(Icons.bolt, color: Colors.white),
                      ),
                      title: Text(
                        notifService.lastNotificationTitle!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notifService.lastNotificationBody ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notifService.lastNotificationTime != null
                                ? dateFormat.format(notifService.lastNotificationTime!)
                                : 'Just now',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Default System Alerts
                _NotificationCard(
                  title: '⚡ Welcome to M&S Electricals!',
                  message:
                      'Book professional wiring, AC repair, lighting, and emergency electrical services directly from the app.',
                  time: 'System • Active',
                  icon: Icons.electric_bolt,
                  iconColor: const Color(0xFF0F2C59),
                  isUnread: true,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _NotificationCard(
                  title: '🚨 24/7 Emergency Support Available',
                  message:
                      'Facing urgent short circuits or power outages? Tap Help & Support for instant emergency dispatch.',
                  time: '2h ago',
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFEE5922),
                  isUnread: false,
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 10),
                _NotificationCard(
                  title: '🎉 10% Off First Booking Offer',
                  message:
                      'Use code MSTECH10 during booking for 10% off your first electrical repair service.',
                  time: '1d ago',
                  icon: Icons.local_offer_outlined,
                  iconColor: const Color(0xFFEE5922),
                  isUnread: false,
                  onTap: () => context.go('/home'),
                ),
                const SizedBox(height: 24),

                // Trigger Test Notification Button
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Send Test Push Alert'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F2C59),
                      side: const BorderSide(color: Color(0xFF0F2C59)),
                    ),
                    onPressed: () {
                      notifService.sendTestPushNotification(
                        title: '⚡ M&S Live Alert Test',
                        body:
                            'Your live push notification service is active and connected!',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification generated!'),
                          backgroundColor: Color(0xFF0F2C59),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            if (isUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEE5922),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1E293B)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
