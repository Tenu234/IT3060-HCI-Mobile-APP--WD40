import 'package:flutter/material.dart';
import '../models/lab_report_model.dart';
import '../services/lab_report_service.dart';

class LabReportsScreen extends StatefulWidget {
  const LabReportsScreen({super.key});

  @override
  State<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends State<LabReportsScreen> {
  late Future<List<LabReportModel>> _reportsFuture;
  String? _selectedCategory;

  final List<String> _categories = [
    'All', 'Blood Test', 'X-Ray', 'ECG', 'Urine Test', 'Scan', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _reportsFuture = LabReportService.getAll(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
    });
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Blood Test': return Colors.red;
      case 'X-Ray':      return Colors.indigo;
      case 'ECG':        return Colors.orange;
      case 'Urine Test': return Colors.amber;
      case 'Scan':       return Colors.teal;
      default:           return Colors.grey;
    }
  }

  Future<void> _showForm({LabReportModel? existing}) async {
    final nameCtrl  = TextEditingController(text: existing?.reportName ?? '');
    final dateCtrl  = TextEditingController(text: existing?.testDate ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final urlCtrl   = TextEditingController(text: existing?.documentUrl ?? '');
    String selectedCat = existing?.category ?? 'Blood Test';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existing == null ? 'Add Lab Report' : 'Edit Lab Report',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Report Name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: const InputDecoration(
                        labelText: 'Category', border: OutlineInputBorder()),
                    items: ['Blood Test', 'X-Ray', 'ECG', 'Urine Test', 'Scan', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setModal(() => selectedCat = v!),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Test Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        dateCtrl.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        hintText: 'Notes (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Document/Image URL (optional)',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModal(() => saving = true);
                              try {
                                if (existing == null) {
                                  await LabReportService.create(
                                    reportName: nameCtrl.text.trim(),
                                    category: selectedCat,
                                    testDate: dateCtrl.text,
                                    notes: notesCtrl.text.trim(),
                                    documentUrl: urlCtrl.text.trim(),
                                  );
                                } else {
                                  await LabReportService.update(
                                    id: existing.id,
                                    reportName: nameCtrl.text.trim(),
                                    category: selectedCat,
                                    testDate: dateCtrl.text,
                                    notes: notesCtrl.text.trim(),
                                    documentUrl: urlCtrl.text.trim(),
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                _reload();
                              } catch (e) {
                                setModal(() => saving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(existing == null ? 'Add Report' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(LabReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Delete "${report.reportName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await LabReportService.delete(report.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Lab Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = (_selectedCategory ?? 'All') == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) {
                    setState(() =>
                        _selectedCategory = cat == 'All' ? null : cat);
                    _reload();
                  },
                  selectedColor: const Color(0xFF1565C0),
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87),
                );
              },
            ),
          ),

          Expanded(
            child: FutureBuilder<List<LabReportModel>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_outlined,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Could not load reports.'),
                        TextButton(onPressed: _reload, child: const Text('Retry')),
                      ],
                    ),
                  );
                }
                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return const Center(
                      child: Text('No lab reports yet. Tap + to add one.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = reports[i];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              _categoryColor(r.category).withOpacity(0.15),
                          child: Icon(Icons.science_outlined,
                              color: _categoryColor(r.category)),
                        ),
                        title: Text(r.reportName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.category}  •  ${r.testDate}'),
                            if (r.notes.isNotEmpty)
                              Text(r.notes,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        isThreeLine: r.notes.isNotEmpty,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _showForm(existing: r);
                            if (v == 'delete') _delete(r);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red))),
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
