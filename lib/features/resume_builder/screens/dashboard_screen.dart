import 'package:career_logic/features/auth/providers/auth_provider.dart';
import 'package:career_logic/features/auth/screens/login_screen.dart';
import 'package:career_logic/features/resume_builder/models/resume_model.dart';
import 'package:career_logic/features/resume_builder/screens/resume_editor_screen.dart';
import 'package:career_logic/features/resume_builder/screens/upload_resume_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../services/resume_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ResumeService _resumeService = ResumeService();
  late Future<List<ResumeModel>> _resumesFuture;
  bool _isCreating = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _fetchResumes();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _fetchResumes() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.currentUser?.token ?? '';
    setState(() {
      _resumesFuture = _resumeService.getAllResumes(token);
    });
  }

  Future<void> _deleteResume(String resumeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume'),
        content: const Text('This action cannot be undone. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.currentUser?.token ?? '';

    try {
      await _resumeService.deleteResume(token, resumeId);
      _fetchResumes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back,',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                              Text(userName,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Provider.of<ThemeProvider>(context).isDarkMode 
                                  ? Icons.light_mode 
                                  : Icons.dark_mode, 
                              color: Colors.white70,
                            ),
                            tooltip: 'Toggle Theme',
                            onPressed: () {
                              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.upload_file, color: Colors.white70),
                            tooltip: 'Upload CV',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const UploadResumeScreen()),
                              ).then((result) {
                                if (result != null) _fetchResumes();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white70),
                            onPressed: () {
                              authProvider.logout();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Resumes',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create, edit, and export professional CVs',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
                  ),
                ],
              ),
            ),

            // Resume List
            Expanded(
              child: FutureBuilder<List<ResumeModel>>(
                future: _resumesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                            const SizedBox(height: 16),
                            Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _fetchResumes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return FadeTransition(
                      opacity: _animController,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description_outlined,
                              size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No resumes yet',
                              style: GoogleFonts.inter(
                                fontSize: 20, fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + to create your first resume',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final resumes = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: resumes.length,
                    itemBuilder: (context, index) {
                      final resume = resumes[index];

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResumeEditorScreen(resumeId: resume.id),
                                ),
                              ).then((_) => _fetchResumes());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 46, height: 46,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.description, color: Colors.white, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resume.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          resume.summary.isNotEmpty
                                              ? resume.summary
                                              : 'No summary yet',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        if (resume.experiences.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: [
                                                Icon(Icons.work_outline, size: 14,
                                                  color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${resume.experiences.length} experience${resume.experiences.length != 1 ? 's' : ''}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Actions
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, 
                                      color: Colors.red.withValues(alpha: 0.6), size: 20),
                                    onPressed: () => _deleteResume(resume.id),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 14,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                ],
                              ),
                            ),
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
      ),

      // FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: _isCreating
                ? null
                : () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final token = authProvider.currentUser?.token;
                    if (token == null) return;

                    setState(() => _isCreating = true);

                    try {
                      final newResume = await _resumeService.createResume(token, "My New Resume");
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResumeEditorScreen(resumeId: newResume.id),
                          ),
                        ).then((_) => _fetchResumes());
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isCreating = false);
                      }
                    }
                  },
            icon: _isCreating
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add),
            label: Text(_isCreating ? 'Creating...' : 'New Resume'),
          ),
        ),
      ),
    );
  }
}
