import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/resume_model.dart';
import '../services/ai_service.dart';

/// AI Tailor Resume screen — the 🔥 CORE FEATURE.
/// Shows old vs. new comparison for summary & experience bullets.
/// User can review and then apply changes.
class AiTailorScreen extends StatefulWidget {
  final ResumeModel resume;

  const AiTailorScreen({super.key, required this.resume});

  @override
  State<AiTailorScreen> createState() => _AiTailorScreenState();
}

class _AiTailorScreenState extends State<AiTailorScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _jobDescController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _suggestions;

  Future<void> _tailorResume() async {
    if (_jobDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job description.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    setState(() => _isLoading = true);

    try {
      final result = await _aiService.tailorResume(
        token: token,
        resumeId: widget.resume.id,
        jobDescription: _jobDescController.text.trim(),
      );

      setState(() {
        _suggestions = result;
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

  Future<void> _applyChanges() async {
    if (_suggestions == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';

    setState(() => _isLoading = true);

    try {
      final experiencesList = (_suggestions!['experiences'] as List? ?? [])
          .map((e) => {
                'experienceId': e['experienceId'],
                'bullets': e['bullets'],
              })
          .toList();

      final updatedResume = await _aiService.applyTailorChanges(
        token: token,
        resumeId: widget.resume.id,
        summary: _suggestions!['summary'] ?? widget.resume.summary,
        experiences: experiencesList.cast<Map<String, dynamic>>(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI changes applied successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, updatedResume);
      }
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
  void dispose() {
    _jobDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Tailor'),
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
                  colors: [Colors.orange.withValues(alpha: 0.1), Colors.deepOrange.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tailor for a Job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Paste a job description and AI will optimize your resume to match.',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Job Description Input
            TextField(
              controller: _jobDescController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Job Description *',
                hintText: 'Paste the full job description here...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Tailor Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _suggestions != null) ? null : _tailorResume,
                icon: _isLoading && _suggestions == null
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isLoading && _suggestions == null ? 'Analyzing...' : 'Tailor My Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Suggestions Results
            if (_suggestions != null) ...[
              const Divider(height: 32),

              // Summary Comparison
              if (_suggestions!['summary'] != null) ...[
                const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildComparisonCard(
                  'Before',
                  widget.resume.summary,
                  Colors.red.withValues(alpha: 0.1),
                  Colors.red,
                  Icons.arrow_back,
                ),
                const SizedBox(height: 8),
                Center(child: Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                _buildComparisonCard(
                  'After (AI Improved)',
                  _suggestions!['summary'],
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green,
                  Icons.arrow_forward,
                ),
                const SizedBox(height: 24),
              ],

              // Experience Bullets Comparison
              if (_suggestions!['experiences'] != null &&
                  (_suggestions!['experiences'] as List).isNotEmpty) ...[
                const Text('Experience Improvements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...(_suggestions!['experiences'] as List).map((exp) {
                  // Find original experience by ID
                  final originalExp = widget.resume.experiences.where(
                    (e) => e.id == exp['experienceId'],
                  );
                  final originalBullets = originalExp.isNotEmpty
                      ? originalExp.first.bullets
                      : <String>[];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originalExp.isNotEmpty ? '${originalExp.first.company} - ${originalExp.first.position}' : 'Experience',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          // Old bullets
                          if (originalBullets.isNotEmpty) ...[
                            const Text('Current:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                            ...originalBullets.map((b) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: TextStyle(color: Colors.red.shade400)),
                                  Expanded(child: Text(b, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                                ],
                              ),
                            )),
                            const SizedBox(height: 12),
                          ],
                          // New bullets
                          const Text('AI Improved:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                          ...(exp['bullets'] as List? ?? []).map((b) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: TextStyle(color: Colors.green.shade400)),
                                Expanded(child: Text(b.toString(), style: TextStyle(color: Colors.green.shade700, fontSize: 13))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Apply Changes Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _applyChanges,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isLoading ? 'Applying...' : 'Apply AI Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Discard Button
              TextButton(
                onPressed: () {
                  setState(() => _suggestions = null);
                },
                child: const Text('Discard & Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    String label, String content, Color bgColor, Color borderColor, IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: borderColor, fontSize: 13)),
          const SizedBox(height: 8),
          Text(content.isNotEmpty ? content : 'No summary set.', 
            style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
