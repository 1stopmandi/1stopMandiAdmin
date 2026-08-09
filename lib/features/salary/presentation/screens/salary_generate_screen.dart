import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/salary_provider.dart';

class SalaryGenerateScreen extends ConsumerStatefulWidget {
  const SalaryGenerateScreen({super.key});

  @override
  ConsumerState<SalaryGenerateScreen> createState() => _SalaryGenerateScreenState();
}

class _SalaryGenerateScreenState extends ConsumerState<SalaryGenerateScreen> {
  late String _periodStart;
  late String _periodEnd;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodStart = DateTime(now.year, now.month, 1).toString().split(' ')[0];
    _periodEnd = now.toString().split(' ')[0];
  }

  @override
  void dispose() {
    ref.read(salaryGenerateProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generateAsync = ref.watch(salaryGenerateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Salary'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_periodStart),
                    onPressed: () => _pickDate(isStart: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_periodEnd),
                    onPressed: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(salaryGenerateProvider.notifier).generate(_periodStart, _periodEnd),
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.blue[700]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: generateAsync.valueOrNull != null && !_confirming ? _confirm : null,
                    icon: const Icon(Icons.check_circle),
                    label: _confirming
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirm'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: generateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (breakdowns) {
                if (breakdowns == null || breakdowns.isEmpty) {
                  return const Center(child: Text('Select dates and tap Preview'));
                }
                final totalPayable = breakdowns.fold(0.0, (s, b) => s + b.finalPayable);
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.green[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${breakdowns.length} employees', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Total: ₹${totalPayable.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: breakdowns.length,
                        itemBuilder: (_, i) {
                          final b = breakdowns[i];
                          return ListTile(
                            dense: true,
                            title: Text(b.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'P:${b.presentDays} H:${b.halfDays} A:${b.absentDays} • ₹${b.dailyWage.toStringAsFixed(0)}/day × ${b.payableDays}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '₹${b.finalPayable.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(isStart ? _periodStart : _periodEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodStart = picked.toString().split(' ')[0];
        } else {
          _periodEnd = picked.toString().split(' ')[0];
        }
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      await ref.read(salaryGenerateProvider.notifier).confirm(_periodStart, _periodEnd);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salary periods created'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }
}
