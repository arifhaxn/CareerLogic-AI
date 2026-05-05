import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/ai_service.dart';

/// Screen for generating a professional summary using AI.
/// Inputs: job title, experience level, skills.
class AiSummaryScreen extends StatefulWidget {
  final String resumeId;
  final String currentSummary;

  const AiSummaryScreen({
    super.key,
    required this.resumeId,
    required this.currentSummary,
  });

  @override
  State<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends State<AiSummaryScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  String _experienceLevel = 'Junior';
  
  bool _isLoading = false;
  String? _generatedSummary;

  final List<String> _experienceLevels = [
    'Entry Level',
    'Junior',
    'Mid-Level',
    'Senior',
    'Lead',
    'Manager',
    'Director',
    'Executive',
  ];

  @override
  void dispose() {
    _jobTitleController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_jobTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job title.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    final skills = _skillsController.text.trim().isNotEmpty
        ? _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    setState(() => _isLoading = true);

    try {
      final summary = await _aiService.generateSummary(
        token: token,
        jobTitle: _jobTitleController.text.trim(),
        experienceLevel: _experienceLevel,
        skills: skills,
      );

      setState(() {
        _generatedSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Summary Generator'),
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
                  colors: [colorScheme.primary.withValues(alpha: 0.1), colorScheme.tertiary.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Generate with AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Tell us about the role, and AI will craft a professional summary.', 
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Job Title
            TextField(
              controller: _jobTitleController,
              decoration: InputDecoration(
                labelText: 'Job Title *',
                hintText: 'e.g. Frontend Developer',
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Experience Level Dropdown
            DropdownButtonFormField<String>(
              initialValue: _experienceLevel,
              decoration: InputDecoration(
                labelText: 'Experience Level',
                prefixIcon: const Icon(Icons.trending_up),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _experienceLevels.map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _experienceLevel = value);
              },
            ),
            const SizedBox(height: 16),

            // Skills
            TextField(
              controller: _skillsController,
              decoration: InputDecoration(
                labelText: 'Key Skills',
                hintText: 'React, Node.js, MongoDB (comma-separated)',
                prefixIcon: const Icon(Icons.code),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateSummary,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Generating...' : 'Generate Summary', style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Current Summary (if exists)
            if (widget.currentSummary.isNotEmpty) ...[
              const Text('Current Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.currentSummary, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 24),
            ],

            // Generated Summary Result
            if (_generatedSummary != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text('AI Generated Summary', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_generatedSummary!, style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, _generatedSummary);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Use This Summary'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
