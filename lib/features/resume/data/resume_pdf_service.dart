import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/errors/app_failure.dart';
import '../../profile/domain/profile_entries.dart';
import '../domain/resume_config.dart';
import '../domain/resume_document.dart';

class ResumePdfService implements ResumePdfGenerator {
  ResumePdfService({Future<ByteData> Function(String)? loadFont})
    : _loadFont = loadFont ?? rootBundle.load;
  final Future<ByteData> Function(String) _loadFont;
  @override
  Future<Uint8List> generate(ResumeDocument document) async {
    final error = document.validate();
    if (error != null) throw AppFailure(error);
    final regular = pw.Font.ttf(
      await _loadFont('assets/fonts/NotoSans-Regular.ttf'),
    );
    final bold = pw.Font.ttf(await _loadFont('assets/fonts/NotoSans-Bold.ttf'));
    final pdf = pw.Document(
      title: '${document.profile.fullName} - ${document.config.position}',
      author: document.profile.fullName,
    );
    final accent = PdfColor.fromHex('#FA4D2B'),
        muted = PdfColor.fromHex('#625C5D');
    final profile = document.profile, config = document.config;
    final content = <pw.Widget>[];
    pw.Widget heading(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1)),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
            color: accent,
          ),
        ),
      ),
    );
    void paragraphs(String value) {
      if (value.trim().isEmpty) return;
      final words = value.trim().split(RegExp(r'\s+'));
      var chunk = '';
      for (final word in words) {
        if (chunk.length + word.length > 650 && chunk.isNotEmpty) {
          content.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text(chunk),
            ),
          );
          chunk = '';
        }
        chunk += '$word ';
      }
      if (chunk.isNotEmpty) {
        content.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Text(chunk.trim()),
          ),
        );
      }
    }

    String month(DateTime date) =>
        '${const ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'][date.month - 1]} ${date.year}';
    content.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (config.showPhoto &&
              config.includedSections.contains(ResumeSection.photo) &&
              document.photo != null) ...[
            pw.ClipRRect(
              horizontalRadius: 10,
              verticalRadius: 10,
              child: pw.Image(
                pw.MemoryImage(document.photo!),
                width: 64,
                height: 64,
                fit: pw.BoxFit.cover,
              ),
            ),
            pw.SizedBox(width: 18),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  profile.fullName,
                  style: pw.TextStyle(
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  config.position,
                  style: pw.TextStyle(fontSize: 14, color: accent),
                ),
                if (profile.city.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 6),
                    child: pw.Text(
                      profile.city,
                      style: pw.TextStyle(color: muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    content.add(pw.SizedBox(height: 14));
    final contacts = profile.contacts.selected(profile.email);
    final ordered = [
      ...contacts.entries.where(
        (e) => profile.contacts.preferred.contains(e.key),
      ),
      ...contacts.entries.where(
        (e) => !profile.contacts.preferred.contains(e.key),
      ),
    ];
    for (final contact in ordered) {
      content.add(
        pw.Text(
          '${contact.key.label}: ${contact.value}',
          style: const pw.TextStyle(fontSize: 9),
        ),
      );
    }
    if (config.includedSections.contains(ResumeSection.about) &&
        profile.aboutMe.trim().isNotEmpty) {
      content.add(pw.NewPage(freeSpace: 100));
      content.add(heading('О себе'));
      paragraphs(profile.aboutMe);
    }
    if (config.includedSections.contains(ResumeSection.preferences) ||
        config.showSalary) {
      final pref = profile.preferences;
      final lines = <String>[];
      if (config.includedSections.contains(ResumeSection.preferences) &&
          pref.isFilled) {
        lines.add('Формат: ${pref.workModes.map((e) => e.label).join(', ')}');
        lines.add(
          'Занятость: ${pref.employmentTypes.map((e) => e.label).join(', ')}',
        );
        lines.add(
          'Переезд: ${pref.relocation ? 'готов' : 'не готов'} · Командировки: ${pref.businessTrips.label}',
        );
      }
      if (config.showSalary &&
          pref.salaryEnabled &&
          pref.minimumSalary != null) {
        lines.add(
          'Ожидаемая зарплата: от ${pref.minimumSalary} ${pref.currency} на руки',
        );
      }
      if (lines.isNotEmpty) {
        content.add(pw.NewPage(freeSpace: 100));
        content.add(heading('Предпочтения'));
        for (final line in lines) {
          paragraphs(line);
        }
      }
    }
    for (final kind in [
      EntryKind.experience,
      EntryKind.project,
      EntryKind.skill,
      EntryKind.education,
      EntryKind.certificate,
      EntryKind.language,
    ]) {
      final entries = document.selected(kind);
      if (entries.isEmpty) continue;
      content.add(pw.NewPage(freeSpace: 100));
      content.add(heading(kind.label));
      if (kind == EntryKind.skill) {
        for (final category in SkillCategory.values) {
          final names = entries
              .whereType<Skill>()
              .where((e) => e.category == category)
              .map((e) => e.name)
              .toList();
          if (names.isNotEmpty) {
            paragraphs('${category.label}: ${names.join(', ')}');
          }
        }
        continue;
      }
      for (final entry in entries) {
        content.add(pw.NewPage(freeSpace: 60));
        content.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
            child: pw.Text(
              entry.title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
        );
        switch (entry) {
          case WorkExperience e:
            paragraphs(e.company);
            paragraphs('${e.periodLabel} · ${e.durationLabel()}');
            if (e.responsibilities.isNotEmpty) {
              paragraphs('Обязанности');
              paragraphs(e.responsibilities);
            }
            if (e.achievements.isNotEmpty) {
              paragraphs('Достижения');
              paragraphs(e.achievements);
            }
          case Project e:
            paragraphs(e.description);
            if (e.technologies.isNotEmpty) {
              paragraphs(e.technologies.join(', '));
            }
            paragraphs(e.resourceUrl);
            if (e.projectType == ProjectType.work) {
              final linked = (document.entries[EntryKind.experience] ?? [])
                  .whereType<WorkExperience>()
                  .where((x) => x.id == e.experienceId);
              if (linked.isNotEmpty) paragraphs(linked.first.company);
            }
          case Education e:
            paragraphs(
              '${e.degree}${e.fieldOfStudy.isEmpty ? '' : ' · ${e.fieldOfStudy}'}',
            );
            paragraphs(
              '${e.startYear} - ${e.isCurrent ? 'настоящее время' : e.endYear ?? ''}',
            );
          case Certificate e:
            paragraphs('${e.issuer} · ${month(e.issueDate)}');
            paragraphs(e.credentialUrl);
          case Language e:
            paragraphs(e.level.label);
          case Skill _:
            break;
        }
      }
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        maxPages: 200,
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
          defaultTextStyle: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ),
        ),
        build: (context) => content,
      ),
    );
    return pdf.save();
  }
}
