import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/resume_service.dart';
import '../models/resume_model.dart';
import '../models/experience_model.dart';
import 'ai_summary_screen.dart';
import 'ai_tailor_screen.dart';
import 'ai_analysis_screen.dart';
import 'ai_full_analysis_screen.dart';
import 'template_selection_screen.dart';

class ResumeEditorScreen extends StatefulWidget {
  final String resumeId;

  const ResumeEditorScreen({super.key, required this.resumeId});

  @override
  State<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends State<ResumeEditorScreen> {
  final ResumeService _resumeService = ResumeService();
  
  bool _isLoading = true;
  String? _errorMessage;
  ResumeModel? _resume;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  List<Map<String, dynamic>> _educationList = [];

  @override
  void initState() {
    super.initState();
    _fetchResumeData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  /// Build a ResumeModel reflecting the CURRENT text field values.
  /// This ensures unsaved edits are included when generating PDF.
  ResumeModel _currentResume() {
    return ResumeModel(
      id: _resume!.id,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : _resume!.title,
      summary: _summaryController.text.trim(),
      experiences: _resume!.experiences,
      skills: _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      education: _educationList,
      projects: _resume!.projects,
    );
  }

  Future<void> _fetchResumeData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    if (token.isEmpty) return;

    try {
      final resume = await _resumeService.getResumeById(token, widget.resumeId);
      setState(() {
        _resume = resume;
        _titleController.text = resume.title;
        _summaryController.text = resume.summary;
        _skillsController.text = resume.skills.join(', ');
        _educationList = List<Map<String, dynamic>>.from(resume.education);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBasicInfo() async {
    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    try {
      // Calls PATCH/PUT /api/resumes/:id
      final updatedResume = await _resumeService.updateResumeInfo(
        token, 
        widget.resumeId, 
        _titleController.text.trim(), 
        _summaryController.text.trim(),
        _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        _educationList,
      );
      setState(() {
        _resume = updatedResume;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Basic info saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteExperience(String expId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';
    try {
      // Calls DELETE /api/resumes/:id/experience/:expId
      final updatedResume = await _resumeService.deleteExperience(token, widget.resumeId, expId);
      setState(() {
        _resume = updatedResume;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting experience: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEducationModal({int? editIndex}) {
    final institutionCtrl = TextEditingController(
      text: editIndex != null ? _educationList[editIndex]['institution']?.toString() : ''
    );
    final degreeCtrl = TextEditingController(
      text: editIndex != null ? _educationList[editIndex]['degree']?.toString() : ''
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editIndex == null ? 'Add Education' : 'Edit Education'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: institutionCtrl,
              decoration: const InputDecoration(labelText: 'Institution', hintText: 'e.g. MIT'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: degreeCtrl,
              decoration: const InputDecoration(labelText: 'Degree / Qualification', hintText: 'e.g. BSc Computer Science'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final entry = {
                  'institution': institutionCtrl.text.trim(),
                  'degree': degreeCtrl.text.trim(),
                };
                if (editIndex == null) {
                  _educationList.add(entry);
                } else {
                  _educationList[editIndex] = entry;
                }
              });
              Navigator.pop(context);
              _saveBasicInfo(); // Auto-save
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteEducation(int index) {
    setState(() {
      _educationList.removeAt(index);
    });
    _saveBasicInfo();
  }

  void _showExperienceModal(BuildContext parentContext) {
    Navigator.push(
      parentContext,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ExperienceFormScreen(
          resumeId: widget.resumeId,
          resumeService: _resumeService,
          onSaved: (updatedResume) {
            setState(() => _resume = updatedResume);
          },
        ),
      ),
    );
  }

  void _showEditExperienceModal(BuildContext parentContext, ExperienceModel job) {
    Navigator.push(
      parentContext,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ExperienceFormScreen(
          resumeId: widget.resumeId,
          resumeService: _resumeService,
          existingJob: job,
          onSaved: (updatedResume) {
            setState(() => _resume = updatedResume);
          },
        ),
      ),
    );
  }

  void _showAiMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow it to be taller if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).padding.bottom + 20, 
              left: 20, 
              right: 20, 
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('AI Tools', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Supercharge your resume with AI', style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                const SizedBox(height: 20),
              _buildAiOption(
                icon: Icons.auto_awesome,
                color: Colors.blue,
                title: 'Generate Summary',
                subtitle: 'AI creates a professional summary for you',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiSummaryScreen(
                        resumeId: widget.resumeId,
                        currentSummary: _resume?.summary ?? '',
                      ),
                    ),
                  ).then((result) {
                    if (result != null && result is String) {
                      setState(() {
                        _summaryController.text = result;
                      });
                      _saveBasicInfo();
                    }
                  });
                },
              ),
              _buildAiOption(
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
                title: 'Tailor for a Job',
                subtitle: 'Optimize resume for a specific job posting',
                onTap: () {
                  Navigator.pop(ctx);
                  if (_resume == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AiTailorScreen(resume: _resume!)),
                  ).then((result) {
                    if (result != null && result is ResumeModel) {
                      setState(() {
                        _resume = result;
                        _titleController.text = result.title;
                        _summaryController.text = result.summary;
                      });
                    }
                  });
                },
              ),
              _buildAiOption(
                icon: Icons.fact_check,
                color: Colors.teal,
                title: 'ATS Score Check',
                subtitle: 'Get your resume score and missing keywords',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AiAnalysisScreen(resumeId: widget.resumeId)),
                  );
                },
              ),
              _buildAiOption(
                icon: Icons.rocket_launch,
                color: Colors.purple,
                title: 'Full AI Analysis',
                subtitle: 'Before & after scores with improvements',
                onTap: () {
                  Navigator.pop(ctx);
                  if (_resume == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AiFullAnalysisScreen(resume: _resume!)),
                  ).then((result) {
                    if (result != null && result is ResumeModel) {
                      setState(() {
                        _resume = result;
                        _titleController.text = result.title;
                        _summaryController.text = result.summary;
                      });
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ), // Close Padding
        ); // Close SingleChildScrollView
      },
    );
  }

  Widget _buildAiOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Resume'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            onPressed: () => _showAiMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Summary Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Basic Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _saveBasicInfo,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Info'),
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Resume Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _summaryController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Professional Summary', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillsController,
              decoration: const InputDecoration(
                labelText: 'Skills (comma-separated)', 
                border: OutlineInputBorder(),
                hintText: 'e.g. Flutter, Dart, Firebase',
              ),
            ),
            const SizedBox(height: 32),

            // Experience Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Work Experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showExperienceModal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Experience'),
                )
              ],
            ),
            const Divider(),
            
            // Experience List
            if (_resume!.experiences.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('No experiences added yet.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _resume!.experiences.length,
                itemBuilder: (context, index) {
                  final job = _resume!.experiences[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(job.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showEditExperienceModal(context, job),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteExperience(job.id),
                              )
                            ],
                          ),
                          Text(job.position, style: const TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 8),
                          ...job.bullets.map((bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(bullet)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            
            // Education Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Education', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showEducationModal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Education'),
                )
              ],
            ),
            const Divider(),
            
            // Education List
            if (_educationList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('No education added yet.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _educationList.length,
                itemBuilder: (context, index) {
                  final edu = _educationList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(edu['institution']?.toString() ?? 'Institution', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(edu['degree']?.toString() ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _showEducationModal(editIndex: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteEducation(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _resume != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TemplateSelectionScreen(resume: _currentResume()),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate CV'),
                ),
              ),
            )
          : null,
    );
  }
}

// ─── Standalone Experience Form Screen ───
// Full-screen form for adding/editing work experience with individual bullet fields.
class _ExperienceFormScreen extends StatefulWidget {
  final String resumeId;
  final ResumeService resumeService;
  final ExperienceModel? existingJob; // null = add mode, non-null = edit mode
  final ValueChanged<ResumeModel> onSaved;

  const _ExperienceFormScreen({
    required this.resumeId,
    required this.resumeService,
    required this.onSaved,
    this.existingJob,
  });

  @override
  State<_ExperienceFormScreen> createState() => _ExperienceFormScreenState();
}

class _ExperienceFormScreenState extends State<_ExperienceFormScreen> {
  late final TextEditingController _companyController;
  late final TextEditingController _positionController;
  final List<TextEditingController> _bulletControllers = [];
  bool _isSaving = false;

  bool get _isEditMode => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.existingJob?.company ?? '');
    _positionController = TextEditingController(text: widget.existingJob?.position ?? '');

    // Pre-populate bullet fields from existing job, or start with one empty field
    if (widget.existingJob != null && widget.existingJob!.bullets.isNotEmpty) {
      for (final bullet in widget.existingJob!.bullets) {
        _bulletControllers.add(TextEditingController(text: bullet));
      }
    } else {
      _bulletControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    for (final c in _bulletControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addBulletField() {
    setState(() {
      _bulletControllers.add(TextEditingController());
    });
  }

  void _removeBulletField(int index) {
    if (_bulletControllers.length > 1) {
      setState(() {
        _bulletControllers[index].dispose();
        _bulletControllers.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    final company = _companyController.text.trim();
    final position = _positionController.text.trim();

    if (company.isEmpty || position.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company and Position are required!')),
      );
      return;
    }

    // Collect non-empty bullets
    final bullets = _bulletControllers
        .map((c) => c.text.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);

    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.token ?? '';

    final experience = ExperienceModel(
      id: widget.existingJob?.id ?? '',
      company: company,
      position: position,
      bullets: bullets,
    );

    debugPrint('[CareerLogic] ${_isEditMode ? "Updating" : "Adding"} experience:');
    debugPrint('[CareerLogic]   Company: $company');
    debugPrint('[CareerLogic]   Position: $position');
    debugPrint('[CareerLogic]   Bullets: $bullets');
    debugPrint('[CareerLogic]   Token present: ${token.isNotEmpty}');
    debugPrint('[CareerLogic]   Resume ID: ${widget.resumeId}');
    debugPrint('[CareerLogic]   JSON body: ${experience.toJson()}');

    try {
      ResumeModel updatedResume;
      if (_isEditMode) {
        updatedResume = await widget.resumeService.updateExperience(
          token, widget.resumeId, widget.existingJob!.id, experience,
        );
      } else {
        updatedResume = await widget.resumeService.addExperience(
          token, widget.resumeId, experience,
        );
      }

      debugPrint('[CareerLogic] ✅ Success! Experiences: ${updatedResume.experiences.length}');

      widget.onSaved(updatedResume);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Experience updated! ✅' : 'Experience added! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[CareerLogic] ❌ ERROR: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Experience' : 'Add Experience'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company *',
                hintText: 'e.g. Google, Microsoft',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // Position
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Position / Title *',
                hintText: 'e.g. Software Engineer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 24),

            // Bullet Points Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Roles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addBulletField,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Add Point'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dynamic bullet point fields
            ...List.generate(_bulletControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bullet number
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: CircleAvatar(
                        radius: 14,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _bulletControllers[index],
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Describe a responsibility or achievement...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          suffixIcon: _bulletControllers.length > 1
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeBulletField(index),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Save button at the bottom too
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : (_isEditMode ? 'Update Experience' : 'Save Experience'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

