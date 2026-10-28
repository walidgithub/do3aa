
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/share_helper.dart';
import '../../domain/entities/dua.dart';

class DuaCard extends StatelessWidget {
  final Dua dua;
  final int number;
  final int dragIndex;
  final bool isLastRead;
  final bool canReorder;

  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DuaCard({
    super.key,
    required this.dua,
    required this.number,
    required this.dragIndex,
    required this.isLastRead,
    this.canReorder = true,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'الدعاء $number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (canReorder)
                    ReorderableDragStartListener(
                      index: dragIndex,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                ],
              ),
              if (isLastRead) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 18,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'آخر مكان توقفت عنده',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                dua.text,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: dua.text),
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ الدعاء'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'نسخ',
                    icon: const Icon(Icons.copy_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      ShareHelper.shareDua(dua.text);
                    },
                    tooltip: 'مشاركة',
                    icon: const Icon(Icons.share_outlined),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'تعديل',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
