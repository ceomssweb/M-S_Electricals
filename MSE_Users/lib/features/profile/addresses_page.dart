import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../auth/auth_state.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  void _showAddressDialog(BuildContext context, {UserAddress? existing}) {
    final labelCtrl = TextEditingController(text: existing?.label ?? 'Home');
    final houseCtrl = TextEditingController(text: existing?.houseNo ?? '');
    final streetCtrl = TextEditingController(text: existing?.street ?? '');
    final landmarkCtrl = TextEditingController(text: existing?.landmark ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Chennai');
    final pinCtrl = TextEditingController(text: existing?.pincode ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');
    bool isDefault = existing?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      existing == null ? 'Add New Address' : 'Edit Address',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: ['Home', 'Work', 'Other'].contains(labelCtrl.text)
                      ? labelCtrl.text
                      : 'Home',
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Home', child: Text('🏠 Home')),
                    DropdownMenuItem(value: 'Work', child: Text('🏢 Work')),
                    DropdownMenuItem(value: 'Other', child: Text('📍 Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) labelCtrl.text = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: houseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'House / Flat / Building No.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Street / Area / Colony',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: landmarkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Landmark (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pincode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: isDefault,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setModalState(() => isDefault = v ?? false);
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (houseCtrl.text.isEmpty || streetCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter house number and street')),
                      );
                      return;
                    }
                    final auth = context.read<AuthState>();
                    final addr = UserAddress(
                      id: existing?.id ?? '',
                      label: labelCtrl.text,
                      houseNo: houseCtrl.text.trim(),
                      street: streetCtrl.text.trim(),
                      landmark: landmarkCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      pincode: pinCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      isDefault: isDefault,
                    );

                    if (existing == null) {
                      await auth.addAddress(addr);
                    } else {
                      await auth.updateAddress(addr);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Save Address' : 'Update Address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: StreamBuilder<List<UserAddress>>(
        stream: auth.userAddresses(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Could not load addresses.'));
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
                  const Icon(Icons.location_off_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No saved addresses yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddressDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add your first address'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = list[i];
              return Card(
                elevation: a.isDefault ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: a.isDefault
                        ? const Color(0xFF1976D2)
                        : Colors.black12,
                    width: a.isDefault ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            a.label == 'Work'
                                ? Icons.business
                                : a.label == 'Home'
                                    ? Icons.home
                                    : Icons.location_on,
                            color: const Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            a.label,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (a.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1976D2)),
                              ),
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                _showAddressDialog(context, existing: a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Address'),
                                  content: const Text(
                                      'Are you sure you want to remove this address?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await auth.deleteAddress(a.id);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(a.formattedAddress,
                          style: const TextStyle(color: Colors.black87)),
                      if (a.phoneNumber != null && a.phoneNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Phone: ${a.phoneNumber}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ),
                      if (!a.isDefault) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => auth.setDefaultAddress(a.id),
                          child: const Text('Set as default'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
