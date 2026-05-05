import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/resume_model.dart';
import '../services/pdf_templates.dart';

/// Template selection screen — pick a CV design and preview/print/share the PDF.
class TemplateSelectionScreen extends StatefulWidget {
  final ResumeModel resume;

  const TemplateSelectionScreen({super.key, required this.resume});

  @override
  State<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  String _selectedTemplateId = 'classic';
  bool _isGenerating = false;

  final Map<String, IconData> _templateIcons = {
    'classic': Icons.description,
    'modern': Icons.auto_awesome_mosaic,
    'creative': Icons.palette,
    'executive': Icons.workspace_premium,
  };

  final Map<String, List<Color>> _templateGradients = {
    'classic': [const Color(0xFF2D3436), const Color(0xFF636E72)],
    'modern': [const Color(0xFF6C63FF), const Color(0xFF8B5CF6)],
    'creative': [const Color(0xFF00B894), const Color(0xFF00CEC9)],
    'executive': [const Color(0xFF0C2340), const Color(0xFFB8860B)],
  };

  Future<void> _previewAndPrint() async {
    setState(() => _isGenerating = true);

    try {
      final doc = PdfTemplates.generate(widget.resume, _selectedTemplateId);
      final bytes = await doc.save();

      if (mounted) {
        setState(() => _isGenerating = false);
        await Printing.layoutPdf(
          onLayout: (_) => bytes,
          name: '${widget.resume.title}.pdf',
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isGenerating = true);

    try {
      final doc = PdfTemplates.generate(widget.resume, _selectedTemplateId);
      final bytes = await doc.save();

      setState(() => _isGenerating = false);

      await Printing.sharePdf(bytes: bytes, filename: '${widget.resume.title}.pdf');
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = PdfTemplates.templates;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Template'),
      ),
      body: Column(
        children: [
          // Template Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  final isSelected = t.id == _selectedTemplateId;
                  final gradient = _templateGradients[t.id] ?? [Colors.grey, Colors.grey];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTemplateId = t.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.15),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          // Template Preview Area
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(17),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _templateIcons[t.id] ?? Icons.description,
                                      size: 44,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(height: 8),
                                    // Mini layout preview lines
                                    ...List.generate(3, (i) => Container(
                                      width: 50 - (i * 8).toDouble(),
                                      height: 3,
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.3 + i * 0.1),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Template Info
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isSelected)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      Text(
                                        t.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isSelected ? theme.colorScheme.primary : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                // Share Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isGenerating ? null : _sharePdf,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Preview / Print Button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _previewAndPrint,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(_isGenerating ? 'Generating...' : 'Preview & Print'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
