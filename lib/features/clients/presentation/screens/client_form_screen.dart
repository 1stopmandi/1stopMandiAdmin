import 'package:flutter/material.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/utils/app_toast.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final String? clientId;

  const ClientFormScreen({super.key, this.clientId});

  bool get isEdit => clientId != null;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _outletTypeCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _fssaiCtrl = TextEditingController();

  bool _loading = false;
  bool _loaded = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _ownerCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _outletTypeCtrl.dispose();
    _gstCtrl.dispose();
    _fssaiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (!widget.isEdit || _loaded) return;
    try {
      final client = await ref.read(clientsRepositoryProvider).getClient(widget.clientId!);
      _phoneCtrl.text = client.phone ?? '';
      _nameCtrl.text = client.name ?? '';
      _businessCtrl.text = client.businessName ?? '';
      _ownerCtrl.text = client.ownerName ?? '';
      _addressCtrl.text = client.address ?? '';
      _pincodeCtrl.text = client.pincode ?? '';
      _outletTypeCtrl.text = client.outletType ?? '';
      _gstCtrl.text = client.gstNumber ?? '';
      _fssaiCtrl.text = client.fssaiNumber ?? '';
      _loaded = true;
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
        context.pop();
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(clientsRepositoryProvider);
      if (widget.isEdit) {
        await repo.updateClient(widget.clientId!, {
          if (_nameCtrl.text.trim().isNotEmpty) 'name': _nameCtrl.text.trim(),
          if (_businessCtrl.text.trim().isNotEmpty) 'business_name': _businessCtrl.text.trim(),
          if (_ownerCtrl.text.trim().isNotEmpty) 'owner_name': _ownerCtrl.text.trim(),
          if (_addressCtrl.text.trim().isNotEmpty) 'address': _addressCtrl.text.trim(),
          if (_pincodeCtrl.text.trim().isNotEmpty) 'pincode': _pincodeCtrl.text.trim(),
          if (_outletTypeCtrl.text.trim().isNotEmpty) 'outlet_type': _outletTypeCtrl.text.trim(),
          if (_gstCtrl.text.trim().isNotEmpty) 'gst_number': _gstCtrl.text.trim(),
          if (_fssaiCtrl.text.trim().isNotEmpty) 'fssai_number': _fssaiCtrl.text.trim(),
        });
        if (mounted) {
          AppToast.success(context, 'Client updated successfully');
          context.pop(true);
        }
      } else {
        if (_phoneCtrl.text.trim().length < 10) {
          throw const ApiException('Enter a valid phone number (min 10 digits)');
        }
        final client = await repo.createClient(
          phone: _phoneCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          businessName: _businessCtrl.text.trim(),
          ownerName: _ownerCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          pincode: _pincodeCtrl.text.trim(),
          outletType: _outletTypeCtrl.text.trim(),
          gstNumber: _gstCtrl.text.trim(),
          fssaiNumber: _fssaiCtrl.text.trim(),
        );
        if (mounted) {
          AppToast.success(context, 'Client created successfully');
          context.pushReplacement('/clients/${client.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && !_loaded) {
      _loadExisting().then((_) {
        if (mounted) setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Client' : 'Add Client'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: widget.isEdit && !_loaded
          ? const ContentSkeleton(type: ContentSkeletonType.form)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: 'Primary Contact'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!widget.isEdit)
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: 'e.g. 9876543210',
                              helperText: 'Client will use this phone number to login.',
                            ),
                          )
                        else
                          TextFormField(
                            controller: _phoneCtrl,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (Read-only)',
                              filled: true,
                              fillColor: Color(0xFFF9FAFB),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contact Name',
                            hintText: 'e.g. John Doe',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ownerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Owner Name',
                            hintText: 'e.g. Jane Doe (if different)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SectionHeader(title: 'Business Profile'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _businessCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                            hintText: 'e.g. John\'s Cafe',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _outletTypeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Outlet Type',
                            hintText: 'e.g. Restaurant, Hotel, Caterer',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SectionHeader(title: 'Location'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _addressCtrl,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Full Address',
                            hintText: 'e.g. 123 Main Street',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pincodeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                            hintText: 'e.g. 110001',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SectionHeader(title: 'Legal Documents'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _gstCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'GST Number',
                            hintText: 'e.g. 22AAAAA0000A1Z5',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fssaiCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'FSSAI License Number',
                            hintText: 'e.g. 10012011000001',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  AppButton.primary(
                    onPressed: _submit,
                    isLoading: _loading,
                    label: widget.isEdit ? 'Save Changes' : 'Create Client',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
