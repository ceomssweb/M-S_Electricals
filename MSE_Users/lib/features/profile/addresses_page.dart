import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: ['Home', 'Work', 'Other'].contains(labelCtrl.text)
                      ? labelCtrl.text
                      : 'Home',
                  decoration: AppStyles.inputDecoration(labelText: 'Label'),
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
                  decoration: AppStyles.inputDecoration(
                      labelText: 'House / Flat / Building No.'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: streetCtrl,
                  decoration: AppStyles.inputDecoration(
                      labelText: 'Street / Area / Colony'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: landmarkCtrl,
                  decoration: AppStyles.inputDecoration(
                      labelText: 'Landmark (Optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityCtrl,
                        decoration: AppStyles.inputDecoration(labelText: 'City'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            AppStyles.inputDecoration(labelText: 'Pincode'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: AppStyles.inputDecoration(
                      labelText: 'Contact Phone Number'),
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
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: AppStyles.filledButton,
                    onPressed: () async {
                      if (houseCtrl.text.isEmpty || streetCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please enter house number and street')),
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
                    child:
                        Text(existing == null ? 'Save Address' : 'Update Address'),
                  ),
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
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddressDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Address',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No saved addresses yet',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: a.isDefault ? AppColors.primary : AppColors.border,
                    width: a.isDefault ? 2 : 1,
                  ),
                  boxShadow: AppStyles.cardShadow,
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
                            color: AppColors.primary,
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
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
                                size: 20, color: AppColors.error),
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
                                            style: TextStyle(
                                                color: AppColors.error))),
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
                          style:
                              const TextStyle(color: AppColors.textPrimary)),
                      if (a.phoneNumber != null && a.phoneNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Phone: ${a.phoneNumber}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
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
