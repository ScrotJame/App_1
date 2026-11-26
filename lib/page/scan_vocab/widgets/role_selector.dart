import 'package:flutter/material.dart';

import '../../../commons/enums.dart';
import 'scan_role_style.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.activeRole,
    required this.onChanged,
  });

  final TokenRole activeRole;
  final ValueChanged<TokenRole> onChanged;

  static const _roles = [
    TokenRole.word,
    TokenRole.pronunciation,
    TokenRole.meaning,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        children: [
          for (final role in _roles)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChip(role),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(TokenRole role) {
    final isActive = role == activeRole;
    final color = scanRoleColor(role);
    return GestureDetector(
      onTap: () => onChanged(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          scanRoleLabel(role),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
