import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/ai_service.dart';

/// ATS Analysis screen — score, missing keywords, and suggestions.
/// Uses the /analyze-resume endpoint.
class AiAnalysisScreen extends StatefulWidget {
  final String resumeId;

  const AiAnalysisScreen({super.key, required this.resumeId});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final AiService _aiService = AiService();
  final TextEditingController _jobDescController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _jobDescController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _analyzeResume() async {
    if (_jobDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job description.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    setState(() => _isLoading = true);

    try {
      final result = await _aiService.analyzeResume(
        token: token,
        resumeId: widget.resumeId,
        jobDescription: _jobDescController.text.trim(),
      );

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATS Resume Analysis'),
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
                  colors: [Colors.teal.withValues(alpha: 0.1), Colors.cyan.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fact_check, color: Colors.teal, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ATS Score Check', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'See how your resume scores against a job posting.',
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
            if (_analysisResult == null) ...[
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

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _analyzeResume,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isLoading ? 'Analyzing...' : 'Analyze Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // Results
            if (_analysisResult != null) ...[
              // Score Circle
              AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final score = (_analysisResult!['score'] ?? 0).toDouble();
                  final animScore = (score * _animController.value).toInt();
                  final color = _scoreColor(animScore);

                  return Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: animScore / 100,
                                  strokeWidth: 12,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$animScore',
                                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
                                  ),
                                  Text('ATS Score', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          animScore >= 80 ? 'Great match!' : animScore >= 60 ? 'Needs improvement' : 'Low match',
                          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Missing Keywords
              if (_analysisResult!['missingKeywords'] != null &&
                  (_analysisResult!['missingKeywords'] as List).isNotEmpty) ...[
                const Text('Missing Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Add these to improve your score:', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_analysisResult!['missingKeywords'] as List).map((keyword) {
                    return Chip(
                      label: Text(keyword.toString()),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      avatar: Icon(Icons.warning_amber, size: 16, color: Colors.red.shade400),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Suggestions
              if (_analysisResult!['suggestions'] != null &&
                  (_analysisResult!['suggestions'] as List).isNotEmpty) ...[
                const Text('Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...(_analysisResult!['suggestions'] as List).map((suggestion) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                      title: Text(suggestion.toString(), style: const TextStyle(fontSize: 14)),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Retry Button
              TextButton.icon(
                onPressed: () {
                  setState(() => _analysisResult = null);
                  _animController.reset();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Analyze Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
