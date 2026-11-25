import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../generated/l10n.dart';
import '../../../models/model_local/support_language_local.dart';

/// Giá trị trả về khi chọn "Tự động".
const kAutoLanguage = 'auto';

/// Cờ + tên ngôn ngữ; mã lạ thì hiện chính mã đó.
String languageLabelOf(String code) {
  for (final language in kSupportedLanguages) {
    if (language.code == code) return '${language.flag} ${language.label}';
  }
  return code;
}

/// Trả mã ngôn ngữ, [kAutoLanguage], hoặc null khi đóng mà không chọn.
Future<String?> showLanguagePickerSheet(
  BuildContext context, {
  String? selected,
  bool showAuto = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                S.of(sheetContext).scan_choose_language,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: showAuto
                  ? TextButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, kAutoLanguage),
                      child: Text(S.of(sheetContext).scan_language_auto),
                    )
                  : null,
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final language in kSupportedLanguages)
                    ListTile(
                      dense: true,
                      title: Text('${language.flag} ${language.label}'),
                      trailing: language.code == selected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.vocabIndigo, size: 18)
                          : null,
                      onTap: () =>
                          Navigator.pop(sheetContext, language.code),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
