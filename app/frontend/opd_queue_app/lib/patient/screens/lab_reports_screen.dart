import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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

  /// Copies picked file to app documents directory and returns local path
  Future<String> _saveFileLocally(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sourcePath);
    final dest = File('${dir.path}/lab_reports/$fileName');
    await dest.parent.create(recursive: true);
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  Future<void> _showForm({LabReportModel? existing}) async {
    final nameCtrl  = TextEditingController(text: existing?.reportName ?? '');
    final dateCtrl  = TextEditingController(text: existing?.testDate ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String selectedCat = existing?.category ?? 'Blood Test';
    String? pickedFilePath = existing?.documentUrl.isNotEmpty == true
        ? existing!.documentUrl
        : null;
    String? pickedFileName = pickedFilePath != null ? p.basename(pickedFilePath) : null;

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

                  // Report Name
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Report Name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Category
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

                  // Test Date
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

                  // Notes
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        hintText: 'Notes (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // File Picker
                  const Text('Document / Image',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      );
                      if (result != null && result.files.single.path != null) {
                        setModal(() {
                          pickedFilePath = result.files.single.path;
                          pickedFileName = result.files.single.name;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pickedFileName ?? 'Choose file (PDF, JPG, PNG)',
                              style: TextStyle(
                                color: pickedFileName != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pickedFileName != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                              onPressed: () => setModal(() {
                                pickedFilePath = null;
                                pickedFileName = null;
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModal(() => saving = true);
                              try {
                                // Save file locally if a new file was picked
                                String localPath = '';
                                if (pickedFilePath != null &&
                                    !pickedFilePath!.contains('lab_reports')) {
                                  localPath = await _saveFileLocally(pickedFilePath!);
                                } else {
                                  localPath = pickedFilePath ?? '';
                                }

                                if (existing == null) {
                                  await LabReportService.create(
                                    reportName: nameCtrl.text.trim(),
                                    category: selectedCat,
                                    testDate: dateCtrl.text,
                                    notes: notesCtrl.text.trim(),
                                    documentUrl: localPath,
                                  );
                                } else {
                                  await LabReportService.update(
                                    id: existing.id,
                                    reportName: nameCtrl.text.trim(),
                                    category: selectedCat,
                                    testDate: dateCtrl.text,
                                    notes: notesCtrl.text.trim(),
                                    documentUrl: localPath,
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
                          : Text(existing == null ? 'Add Report' : 'Save Changes',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(String path) async {
    if (path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await OpenFile.open(path);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found on this device.')),
        );
      }
    }
  }

  Future<void> _delete(LabReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Delete "${report.reportName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
          // Category filter chips
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

          // Reports list
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
                    final hasFile = r.documentUrl.isNotEmpty;
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
                            style: const TextStyle(fontWeight: FontWeight.w600)),
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
                            if (hasFile)
                              GestureDetector(
                                onTap: () => _openFile(r.documentUrl),
                                child: const Text('📎 View File',
                                    style: TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontSize: 12,
                                        decoration: TextDecoration.underline)),
                              ),
                          ],
                        ),
                        isThreeLine: true,
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
