import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../database/app_db.dart';
import '../../../generated/l10n.dart';

/// Bọc lựa chọn để phân biệt "Không thuộc Unit" với đóng bảng.
typedef UnitChoice = ({int? unitId});

Future<UnitChoice?> showUnitPickerSheet(
  BuildContext context, {
  required List<UnitsEntry> units,
  int? selected,
}) {
  return showModalBottomSheet<UnitChoice>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      Widget option(int? unitId, String title) {
        return ListTile(
          dense: true,
          title: Text(title),
          trailing: unitId == selected
              ? const Icon(Icons.check_rounded,
                  color: AppColors.vocabIndigo, size: 18)
              : null,
          onTap: () => Navigator.pop(sheetContext, (unitId: unitId)),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                S.of(sheetContext).scan_review_choose_unit,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  option(null, S.of(sheetContext).scan_review_no_unit),
                  for (final unit in units) option(unit.id, unit.title),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
