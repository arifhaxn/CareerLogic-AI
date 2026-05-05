
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/resume_model.dart';
import '../services/ai_service.dart';

/// Full Analysis screen — 🚀 BEST FEATURE.
/// Shows before/after ATS scores + AI improvements.
/// Combines /full-analysis and /apply-tailor endpoints.
class AiFullAnalysisScreen extends StatefulWidget {
  final ResumeModel resume;

  const AiFullAnalysisScreen({super.key, required this.resume});

  @override
  State<AiFullAnalysisScreen> createState() => _AiFullAnalysisScreenState();
}

class _AiFullAnalysisScreenState extends State<AiFullAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final AiService _aiService = AiService();
  final TextEditingController _jobDescController = TextEditingController();

  bool _isLoading = false;
  bool _isApplying = false;
  Map<String, dynamic>? _analysisResult;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _jobDescController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _runFullAnalysis() async {
    if (_jobDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job description.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    setState(() => _isLoading = true);

    try {
      final result = await _aiService.fullAnalysis(
        token: token,
        resumeId: widget.resume.id,
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

  Future<void> _applyImprovements() async {
    if (_analysisResult == null || _analysisResult!['improvements'] == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    final improvements = _analysisResult!['improvements'];

    setState(() => _isApplying = true);

    try {
      final experiencesList = (improvements['experiences'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final updatedResume = await _aiService.applyTailorChanges(
        token: token,
        resumeId: widget.resume.id,
        summary: improvements['summary'] ?? widget.resume.summary,
        experiences: experiencesList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Improvements applied!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, updatedResume);
      }
    } catch (e) {
      setState(() => _isApplying = false);
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
        title: const Text('Full AI Analysis'),
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
                  colors: [Colors.purple.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rocket_launch, color: Colors.purple, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Full Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Get ATS scores before & after AI optimization.',
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
                  onPressed: _isLoading ? null : _runFullAnalysis,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isLoading ? 'Analyzing...' : 'Run Full Analysis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // Results
            if (_analysisResult != null) ...[
              // Score Comparison
              AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final beforeScore = (_analysisResult!['before']?['score'] ?? 0).toDouble();
                  final afterScore = (_analysisResult!['after']?['score'] ?? 0).toDouble();
                  final progress = _animController.value;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildScoreCircle(
                          'BEFORE',
                          (beforeScore * progress).toInt(),
                          beforeScore.toInt(),
                          Colors.red,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      Expanded(
                        child: _buildScoreCircle(
                          'AFTER',
                          (afterScore * progress).toInt(),
                          afterScore.toInt(),
                          Colors.green,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              // Score Change Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '+${((_analysisResult!['after']?['score'] ?? 0) - (_analysisResult!['before']?['score'] ?? 0))} points improvement',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Improvements Preview
              if (_analysisResult!['improvements'] != null) ...[
                const Text('Proposed Improvements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (_analysisResult!['improvements']['summary'] != null)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.subject, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Improved Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _analysisResult!['improvements']['summary'],
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Apply Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isApplying ? null : _applyImprovements,
                    icon: _isApplying
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isApplying ? 'Applying...' : 'Apply All Improvements'),
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
                    setState(() => _analysisResult = null);
                    _animController.reset();
                  },
                  child: const Text('Discard & Try Again'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(String label, int animatedScore, int targetScore, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: animatedScore / 100,
                  strokeWidth: 10,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animatedScore',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text('/100', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }
}
