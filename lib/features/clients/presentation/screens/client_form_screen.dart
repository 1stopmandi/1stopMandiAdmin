import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';

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
  String? _error;

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
      _error = friendlyError(e);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(clientsRepositoryProvider);
      if (widget.isEdit) {
        await repo.updateClient(widget.clientId!, {
          if (_nameCtrl.text.trim().isNotEmpty) 'name': _nameCtrl.text.trim(),
          if (_businessCtrl.text.trim().isNotEmpty)
            'business_name': _businessCtrl.text.trim(),
          if (_ownerCtrl.text.trim().isNotEmpty)
            'owner_name': _ownerCtrl.text.trim(),
          if (_addressCtrl.text.trim().isNotEmpty)
            'address': _addressCtrl.text.trim(),
          if (_pincodeCtrl.text.trim().isNotEmpty)
            'pincode': _pincodeCtrl.text.trim(),
          if (_outletTypeCtrl.text.trim().isNotEmpty)
            'outlet_type': _outletTypeCtrl.text.trim(),
          if (_gstCtrl.text.trim().isNotEmpty)
            'gst_number': _gstCtrl.text.trim(),
          if (_fssaiCtrl.text.trim().isNotEmpty)
            'fssai_number': _fssaiCtrl.text.trim(),
        });
        if (mounted) context.pop(true);
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
        if (mounted) context.go('/clients/${client.id}');
      }
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && !_loaded && _error == null) {
      _loadExisting().then((_) {
        if (mounted) setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Client' : 'Add Client'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: widget.isEdit && !_loaded && _error == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.isEdit)
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                        helperText: 'Client claims account on first OTP login',
                      ),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Phone'),
                      subtitle: Text(_phoneCtrl.text),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _businessCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Business name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ownerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Owner name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _outletTypeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Outlet type',
                      hintText: 'restaurant, hotel, caterer…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pincodeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gstCtrl,
                    decoration: const InputDecoration(
                      labelText: 'GST number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fssaiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'FSSAI number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.isEdit ? 'Save changes' : 'Create client'),
                  ),
                ],
              ),
            ),
    );
  }
}
