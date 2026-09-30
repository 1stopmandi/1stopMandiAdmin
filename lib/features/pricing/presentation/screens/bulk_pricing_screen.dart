import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/models/pricing.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/skeleton_card.dart';

class BulkPricingScreen extends ConsumerStatefulWidget {
  const BulkPricingScreen({super.key});

  @override
  ConsumerState<BulkPricingScreen> createState() => _BulkPricingScreenState();
}

class _BulkPricingScreenState extends ConsumerState<BulkPricingScreen> {
  final _slugCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;
  String? _exportPreview;
  BulkImportPreview? _importPreview;

  @override
  void dispose() {
    _slugCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final csv = await ref.read(pricingRepositoryProvider).exportCsv();
      setState(() => _exportPreview = csv);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndPreview() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _loading = true);
    try {
      final preview = await ref.read(pricingRepositoryProvider).importPreview(
            file.bytes!,
            file.name,
          );
      setState(() => _importPreview = preview);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmImport() async {
    final batch = _importPreview;
    if (batch == null || !batch.canConfirm) return;
    setState(() => _loading = true);
    try {
      final updated =
          await ref.read(pricingRepositoryProvider).confirmImport(batch.batchId);
      if (mounted) {
        AppToast.success(context, 'Applied pricing to $updated products');
        setState(() => _importPreview = null);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickUpdate() async {
    final slug = _slugCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (slug.isEmpty || price == null || price <= 0) {
      AppToast.warning(context, 'Enter product slug and valid price');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(pricingRepositoryProvider).bulkUpdate([
        {'slug': slug, 'base_price': price},
      ]);
      if (mounted) {
        if (result.applied) {
          AppToast.success(context, 'Updated ${result.updated} product(s)');
        } else {
          AppToast.error(
            context,
            result.failed.isNotEmpty
                ? result.failed.first['reason']?.toString() ?? 'Update failed'
                : 'Update failed',
          );
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
    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Bulk Pricing'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const ContentSkeleton(type: ContentSkeletonType.form)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: 'Export CSV template',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Download current pricing as CSV. Edit offline and re-import.',
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _export,
                        icon: const Icon(Icons.download),
                        label: const Text('Export CSV'),
                      ),
                      if (_exportPreview != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _exportPreview!));
                              AppToast.success(context, 'CSV copied to clipboard');
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy to clipboard'),
                          ),
                        ),
                        Container(
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _exportPreview!.split('\n').take(8).join('\n'),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _Section(
                  title: 'Import CSV',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickAndPreview,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Pick CSV & preview'),
                      ),
                      if (_importPreview != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_importPreview!.valid}/${_importPreview!.total} rows valid',
                          style: TextStyle(
                            color: _importPreview!.canConfirm
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_importPreview!.errors.isNotEmpty)
                          ..._importPreview!.errors.take(5).map(
                                (e) => Text(
                                  'Line ${e['line']}: ${e['reason']}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed:
                              _importPreview!.canConfirm ? _confirmImport : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirm import'),
                        ),
                      ],
                    ],
                  ),
                ),
                _Section(
                  title: 'Quick single update',
                  child: Column(
                    children: [
                      TextField(
                        controller: _slugCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Product slug',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Base price (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _quickUpdate,
                        child: const Text('Apply bulk update'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}
