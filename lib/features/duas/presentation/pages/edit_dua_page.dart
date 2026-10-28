import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dua.dart';
import '../cubit/dua_cubit.dart';

class EditDuaPage extends StatefulWidget {
  final Dua? dua;

  const EditDuaPage({
    super.key,
    this.dua,
  });

  bool get isEditing => dua != null;

  @override
  State<EditDuaPage> createState() => _EditDuaPageState();
}

class _EditDuaPageState extends State<EditDuaPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.dua?.text ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اكتب الدعاء أولًا',
          ),
        ),
      );

      return;
    }

    final cubit = context.read<DuaCubit>();

    if (widget.isEditing) {
      final oldDua = widget.dua!;

      final updatedDua = Dua(
        id: oldDua.id,
        text: text,
        sortOrder: oldDua.sortOrder,
        isDefault: oldDua.isDefault,
        createdAt: oldDua.createdAt,
        updatedAt: DateTime.now(),
      );

      await cubit.updateDua(updatedDua);
    } else {
      await cubit.addDua(
        text: text,
      );
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'تعديل الدعاء'
              : 'إضافة دعاء',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'اكتب الدعاء هنا',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(
                  widget.isEditing
                      ? 'حفظ التعديل'
                      : 'إضافة الدعاء',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}