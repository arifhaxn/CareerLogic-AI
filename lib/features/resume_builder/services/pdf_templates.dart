import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/resume_model.dart';

/// Generates PDF resumes in different template styles.
class PdfTemplates {
  /// Template metadata for the selection screen.
  static List<TemplateInfo> get templates => [
    TemplateInfo(
      id: 'classic',
      name: 'Classic',
      description: 'Traditional professional layout',
      accentColor: const PdfColor.fromInt(0xFF2D3436),
      previewIcon: 'classic',
    ),
    TemplateInfo(
      id: 'modern',
      name: 'Modern',
      description: 'Clean minimalist design',
      accentColor: const PdfColor.fromInt(0xFF6C63FF),
      previewIcon: 'modern',
    ),
    TemplateInfo(
      id: 'creative',
      name: 'Creative',
      description: 'Bold colors with sidebar',
      accentColor: const PdfColor.fromInt(0xFF00B894),
      previewIcon: 'creative',
    ),
    TemplateInfo(
      id: 'executive',
      name: 'Executive',
      description: 'Elegant premium style',
      accentColor: const PdfColor.fromInt(0xFF0C2340),
      previewIcon: 'executive',
    ),
  ];

  /// Generate a PDF document for the given resume and template.
  static pw.Document generate(ResumeModel resume, String templateId) {
    switch (templateId) {
      case 'modern':
        return _buildModern(resume);
      case 'creative':
        return _buildCreative(resume);
      case 'executive':
        return _buildExecutive(resume);
      case 'classic':
      default:
        return _buildClassic(resume);
    }
  }

  // ─────────────────────────────────────────────
  // CLASSIC TEMPLATE
  // ─────────────────────────────────────────────
  static pw.Document _buildClassic(ResumeModel resume) {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF2D3436);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        // Header
        pw.Center(
          child: pw.Text(
            resume.title,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: accent),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 2, color: accent),
        pw.SizedBox(height: 16),

        // Summary
        if (resume.summary.isNotEmpty) ...[
          _sectionTitle('PROFESSIONAL SUMMARY', accent),
          pw.SizedBox(height: 6),
          pw.Text(resume.summary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 4)),
          pw.SizedBox(height: 16),
        ],

        // Skills
        if (resume.skills.isNotEmpty) ...[
          _sectionTitle('SKILLS', accent),
          pw.SizedBox(height: 6),
          pw.Text(resume.skills.join('  •  '), style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 16),
        ],

        // Experience
        if (resume.experiences.isNotEmpty) ...[
          _sectionTitle('WORK EXPERIENCE', accent),
          pw.SizedBox(height: 6),
          ...resume.experiences.map((exp) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(exp.company, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text(exp.position, style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                ],
              ),
              pw.SizedBox(height: 4),
              ...exp.bullets.map((b) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
                    pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 11, lineSpacing: 3))),
                  ],
                ),
              )),
              pw.SizedBox(height: 10),
            ],
          )),
        ],

        // Education
        if (resume.education.isNotEmpty) ...[
          _sectionTitle('EDUCATION', accent),
          pw.SizedBox(height: 6),
          ...resume.education.map((edu) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                edu['institution']?.toString() ?? edu['degree']?.toString() ?? 'Institution',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              if (edu['degree'] != null)
                pw.Text(edu['degree'].toString(), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 6),
            ],
          )),
        ],

        // Projects
        if (resume.projects.isNotEmpty) ...[
          _sectionTitle('PROJECTS', accent),
          pw.SizedBox(height: 6),
          ...resume.projects.map((proj) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                proj['name']?.toString() ?? 'Project',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              if (proj['description'] != null)
                pw.Text(proj['description'].toString(), style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
              pw.SizedBox(height: 6),
            ],
          )),
        ],
      ],
    ));

    return doc;
  }

  // ─────────────────────────────────────────────
  // MODERN TEMPLATE
  // ─────────────────────────────────────────────
  static pw.Document _buildModern(ResumeModel resume) {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF6C63FF);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        // Header with accent bar
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                resume.title,
                style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              if (resume.summary.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(resume.summary,
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.white, lineSpacing: 3),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Skills chips
        if (resume.skills.isNotEmpty) ...[
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: resume.skills.map((skill) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: accent),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(skill, style: pw.TextStyle(fontSize: 10, color: accent)),
            )).toList(),
          ),
          pw.SizedBox(height: 20),
        ],

        // Experience
        if (resume.experiences.isNotEmpty) ...[
          _modernSectionTitle('Experience', accent),
          ...resume.experiences.map((exp) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(exp.company, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text(exp.position, style: pw.TextStyle(fontSize: 11, color: accent)),
                pw.SizedBox(height: 6),
                ...exp.bullets.map((b) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 5, height: 5,
                        margin: const pw.EdgeInsets.only(top: 4, right: 8),
                        decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: accent),
                      ),
                      pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10, lineSpacing: 3))),
                    ],
                  ),
                )),
              ],
            ),
          )),
        ],

        // Education
        if (resume.education.isNotEmpty) ...[
          _modernSectionTitle('Education', accent),
          ...resume.education.map((edu) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.Container(width: 3, height: 30, color: accent),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      edu['institution']?.toString() ?? 'Institution',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    if (edu['degree'] != null)
                      pw.Text(edu['degree'].toString(), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          )),
        ],

        // Projects
        if (resume.projects.isNotEmpty) ...[
          _modernSectionTitle('Projects', accent),
          ...resume.projects.map((proj) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(proj['name']?.toString() ?? 'Project',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (proj['description'] != null)
                  pw.Text(proj['description'].toString(), style: const pw.TextStyle(fontSize: 10, lineSpacing: 3)),
              ],
            ),
          )),
        ],
      ],
    ));

    return doc;
  }

  // ─────────────────────────────────────────────
  // CREATIVE TEMPLATE
  // ─────────────────────────────────────────────
  static pw.Document _buildCreative(ResumeModel resume) {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF00B894);
    const sidebar = PdfColor.fromInt(0xFF2D3436);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sidebar
          pw.Container(
            width: 180,
            height: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            color: sidebar,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(resume.title.split(' ').first,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
                if (resume.title.split(' ').length > 1)
                  pw.Text(resume.title.split(' ').skip(1).join(' '),
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.white)),
                pw.SizedBox(height: 24),
                pw.Divider(color: accent, thickness: 2),
                pw.SizedBox(height: 16),

                // Skills
                if (resume.skills.isNotEmpty) ...[
                  pw.Text('SKILLS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent)),
                  pw.SizedBox(height: 8),
                  ...resume.skills.map((s) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(children: [
                      pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: accent)),
                      pw.SizedBox(width: 8),
                      pw.Expanded(child: pw.Text(s, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey400))),
                    ]),
                  )),
                  pw.SizedBox(height: 16),
                ],

                // Education
                if (resume.education.isNotEmpty) ...[
                  pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent)),
                  pw.SizedBox(height: 8),
                  ...resume.education.map((edu) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(edu['institution']?.toString() ?? '',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        if (edu['degree'] != null)
                          pw.Text(edu['degree'].toString(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),

          // Main Content
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(28),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Summary
                  if (resume.summary.isNotEmpty) ...[
                    pw.Text('ABOUT ME', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accent)),
                    pw.SizedBox(height: 6),
                    pw.Text(resume.summary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 4)),
                    pw.SizedBox(height: 20),
                  ],

                  // Experience
                  if (resume.experiences.isNotEmpty) ...[
                    pw.Text('EXPERIENCE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accent)),
                    pw.SizedBox(height: 8),
                    ...resume.experiences.map((exp) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(exp.company, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        pw.Text(exp.position, style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: accent)),
                        pw.SizedBox(height: 4),
                        ...exp.bullets.map((b) => pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('▸ ', style: pw.TextStyle(fontSize: 10, color: accent)),
                              pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10, lineSpacing: 3))),
                            ],
                          ),
                        )),
                        pw.SizedBox(height: 10),
                      ],
                    )),
                  ],

                  // Projects
                  if (resume.projects.isNotEmpty) ...[
                    pw.Text('PROJECTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accent)),
                    pw.SizedBox(height: 6),
                    ...resume.projects.map((proj) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(proj['name']?.toString() ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          if (proj['description'] != null)
                            pw.Text(proj['description'].toString(), style: const pw.TextStyle(fontSize: 10, lineSpacing: 3)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ));

    return doc;
  }

  // ─────────────────────────────────────────────
  // EXECUTIVE TEMPLATE
  // ─────────────────────────────────────────────
  static pw.Document _buildExecutive(ResumeModel resume) {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF0C2340);
    const gold = PdfColor.fromInt(0xFFB8860B);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => [
        // Elegant header
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 16),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: gold, width: 3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(resume.title,
                style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 2)),
              pw.SizedBox(height: 4),
              pw.Container(width: 40, height: 2, color: gold),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Summary
        if (resume.summary.isNotEmpty) ...[
          pw.Text(resume.summary,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, lineSpacing: 4, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
        ],

        // Skills
        if (resume.skills.isNotEmpty) ...[
          _executiveSectionTitle('Core Competencies', accent, gold),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(resume.skills.join('  |  '),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          ),
          pw.SizedBox(height: 20),
        ],

        // Experience
        if (resume.experiences.isNotEmpty) ...[
          _executiveSectionTitle('Professional Experience', accent, gold),
          pw.SizedBox(height: 8),
          ...resume.experiences.map((exp) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(exp.company.toUpperCase(),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 1)),
              pw.Text(exp.position, style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: gold)),
              pw.SizedBox(height: 4),
              ...exp.bullets.map((b) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('— ', style: const pw.TextStyle(fontSize: 10, color: gold)),
                    pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10, lineSpacing: 3))),
                  ],
                ),
              )),
              pw.SizedBox(height: 12),
            ],
          )),
        ],

        // Education
        if (resume.education.isNotEmpty) ...[
          _executiveSectionTitle('Education', accent, gold),
          pw.SizedBox(height: 8),
          ...resume.education.map((edu) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(edu['institution']?.toString() ?? '',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent)),
                if (edu['degree'] != null)
                  pw.Text(edu['degree'].toString(), style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          )),
        ],
      ],
    ));

    return doc;
  }

  // ── Helpers ──

  static pw.Widget _sectionTitle(String text, PdfColor color) {
    return pw.Column(children: [
      pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color, letterSpacing: 1)),
      pw.SizedBox(height: 2),
      pw.Divider(color: color, thickness: 1),
    ]);
  }

  static pw.Widget _modernSectionTitle(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(children: [
        pw.Container(width: 4, height: 18, decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(2))),
        pw.SizedBox(width: 10),
        pw.Text(text, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  static pw.Widget _executiveSectionTitle(String text, PdfColor accent, PdfColor gold) {
    return pw.Column(children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: gold, width: 1),
            bottom: pw.BorderSide(color: gold, width: 1),
          ),
        ),
        child: pw.Center(
          child: pw.Text(text.toUpperCase(),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 2)),
        ),
      ),
    ]);
  }
}

/// Metadata for a template.
class TemplateInfo {
  final String id;
  final String name;
  final String description;
  final PdfColor accentColor;
  final String previewIcon;

  const TemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
    required this.previewIcon,
  });
}
