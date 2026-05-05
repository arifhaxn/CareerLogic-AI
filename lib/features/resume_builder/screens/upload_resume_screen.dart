import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/ai_service.dart';

/// Upload Resume screen — PDF upload → AI parse → review → save.
/// Uses /upload-resume and /from-upload endpoints.
class UploadResumeScreen extends StatefulWidget {
  const UploadResumeScreen({super.key});

  @override
  State<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen> {
  final AiService _aiService = AiService();

  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _parsedData;

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
        _parsedData = null; // Reset if re-picking
      });
    }
  }

  Future<void> _uploadAndParse() async {
    if (_selectedFile == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    setState(() => _isUploading = true);

    try {
      final parsed = await _aiService.uploadResumePdf(
        token: token,
        pdfFile: _selectedFile!,
      );

      setState(() {
        _parsedData = parsed;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveToDatabase() async {
    if (_parsedData == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    setState(() => _isSaving = true);

    try {
      final savedResume = await _aiService.saveFromUpload(
        token: token,
        parsedData: _parsedData!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, savedResume);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Resume'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: Colors.indigo, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Import Your CV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Upload a PDF and AI will extract all your information automatically.',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // File Picker Area
            GestureDetector(
              onTap: _pickPdf,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null ? Colors.green : Theme.of(context).dividerColor,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: _selectedFile != null ? Colors.green.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.picture_as_pdf : Icons.cloud_upload_outlined,
                        size: 48,
                        color: _selectedFile != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile != null ? _fileName ?? 'File selected' : 'Tap to select a PDF file',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedFile != null ? Colors.green : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (_selectedFile != null)
                        TextButton(
                          onPressed: _pickPdf,
                          child: const Text('Change file', style: TextStyle(fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Button
            if (_selectedFile != null && _parsedData == null)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadAndParse,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isUploading ? 'Parsing with AI...' : 'Upload & Parse with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            // Parsed Results Preview
            if (_parsedData != null) ...[
              const SizedBox(height: 24),
              const Text('Parsed Resume Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Review the extracted information below.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 13)),
              const SizedBox(height: 16),

              // Title
              _buildParsedSection('Title', _parsedData!['title']?.toString() ?? 'Untitled'),

              // Summary
              if (_parsedData!['summary'] != null && _parsedData!['summary'].toString().isNotEmpty)
                _buildParsedSection('Summary', _parsedData!['summary']),

              // Skills
              if (_parsedData!['skills'] != null && (_parsedData!['skills'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (_parsedData!['skills'] as List).map((skill) {
                    return Chip(
                      label: Text(skill.toString(), style: const TextStyle(fontSize: 13)),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                    );
                  }).toList(),
                ),
              ],

              // Experience
              if (_parsedData!['experience'] != null && (_parsedData!['experience'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Experience (${(_parsedData!['experience'] as List).length} entries)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...(_parsedData!['experience'] as List).map((exp) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.work, color: Colors.blue),
                      title: Text(exp['company']?.toString() ?? exp['position']?.toString() ?? 'Experience'),
                      subtitle: Text(exp['position']?.toString() ?? ''),
                    ),
                  );
                }),
              ],

              // Education
              if (_parsedData!['education'] != null && (_parsedData!['education'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Education (${(_parsedData!['education'] as List).length} entries)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...(_parsedData!['education'] as List).map((edu) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.school, color: Colors.purple),
                      title: Text(edu['institution']?.toString() ?? edu['degree']?.toString() ?? 'Education'),
                      subtitle: Text(edu['degree']?.toString() ?? ''),
                    ),
                  );
                }),
              ],

              // Projects
              if (_parsedData!['projects'] != null && (_parsedData!['projects'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Projects (${(_parsedData!['projects'] as List).length} entries)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...(_parsedData!['projects'] as List).map((proj) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.folder, color: Colors.teal),
                      title: Text(proj['name']?.toString() ?? 'Project'),
                      subtitle: Text(proj['description']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveToDatabase,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save to My Resumes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _parsedData = null;
                    _selectedFile = null;
                    _fileName = null;
                  });
                },
                child: const Text('Discard & Start Over'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParsedSection(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
