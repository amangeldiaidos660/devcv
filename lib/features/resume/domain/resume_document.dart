import 'dart:typed_data';

import '../../profile/domain/developer_profile.dart';
import '../../profile/domain/profile_entries.dart';
import 'resume_config.dart';

class ResumeDocument {
  const ResumeDocument({
    required this.profile,
    required this.config,
    required this.entries,
    this.photo,
  });
  final DeveloperProfile profile;
  final ResumeConfig config;
  final Map<EntryKind, List<ProfileEntry>> entries;
  final Uint8List? photo;
  List<ProfileEntry> selected(EntryKind kind) {
    if (!config.includedSections.any((e) => e.kind == kind)) return [];
    final ids = config.selectedIds[kind] ?? {};
    return (entries[kind] ?? []).where((e) => ids.contains(e.id)).toList();
  }

  String? validate() =>
      config.validate() ??
      (profile.fullName.trim().isEmpty
          ? 'Сначала укажите ФИО в профиле'
          : null) ??
      (profile.contacts.selected(profile.email).isEmpty
          ? 'Включите хотя бы один контакт для резюме'
          : null);
  String get fileName {
    String clean(String value) => value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '');
    final name = clean(profile.fullName), position = clean(config.position);
    final title = 'DevCV_${name}_$position';
    return '${title.substring(0, title.length > 160 ? 160 : title.length)}.pdf';
  }
}

abstract interface class ResumePdfGenerator {
  Future<Uint8List> generate(ResumeDocument document);
}

abstract interface class ResumeExporter {
  Future<Uri?> save(Uint8List bytes, String fileName);
}
