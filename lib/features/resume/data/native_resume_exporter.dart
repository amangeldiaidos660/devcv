import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/resume_document.dart';

class NativeResumeExporter implements ResumeExporter {
  @override
  Future<Uri?> save(Uint8List bytes, String fileName) async {
    try {
      return await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
        dialogTitle: 'Сохранить резюме',
      );
    } catch (_) {
      throw const AppFailure(
        'Не удалось сохранить PDF. Выберите доступную папку и попробуйте ещё раз',
      );
    }
  }
}
