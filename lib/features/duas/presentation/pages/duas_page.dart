
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dua.dart';
import '../cubit/dua_cubit.dart';
import '../cubit/dua_state.dart';
import '../widgets/dua_card.dart';
import 'edit_dua_page.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController =
  TextEditingController();

  final Map<int, GlobalKey> _duaKeys = {};

  int? lastReadDuaId;
  String _searchQuery = '';

  // سرعة التمرير بوحدة بكسل في الثانية.
  double _scrollSpeed = 20;

  bool _isAutoScrolling = false;
  bool _isScrollLoopRunning = false;

  @override
  void initState() {
    super.initState();
    _loadLastReadDua();
  }

  @override
  void dispose() {
    _isAutoScrolling = false;
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLastReadDua() async {
    final id =
    await context.read<DuaCubit>().getLastReadDuaId();

    if (!mounted) return;

    setState(() {
      lastReadDuaId = id;
    });
  }

  List<Dua> _filterDuas(List<Dua> duas) {
    final query = _searchQuery.trim();

    if (query.isEmpty) return duas;

    return duas
        .where(
          (dua) => dua.text.toLowerCase().contains(
        query.toLowerCase(),
      ),
    )
        .toList();
  }

  void _cleanDuaKeys(List<Dua> duas) {
    final ids = duas
        .where((dua) => dua.id != null)
        .map((dua) => dua.id!)
        .toSet();

    _duaKeys.removeWhere(
          (id, key) => !ids.contains(id),
    );
  }

  Future<void> _scrollToLastReadDua() async {
    if (lastReadDuaId == null) return;

    // نزيل البحث مؤقتًا حتى يظهر الدعاء المحفوظ.
    if (_searchQuery.isNotEmpty) {
      _searchController.clear();

      setState(() {
        _searchQuery = '';
      });

      await WidgetsBinding.instance.endOfFrame;
    }

    final key = _duaKeys[lastReadDuaId!];
    final targetContext = key?.currentContext;

    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
      return;
    }

    // إذا لم يكن العنصر مبنيًا بعد، نمرر القائمة تدريجيًا
    // حتى يظهر، ثم ننتقل إليه بدقة.
    if (!_scrollController.hasClients) return;

    final state = context.read<DuaCubit>().state;
    if (state is! DuaLoaded) return;

    final allDuas = state.duas;
    final targetIndex = allDuas.indexWhere(
          (dua) => dua.id == lastReadDuaId,
    );

    if (targetIndex < 0) return;

    final estimatedItemHeight =
        MediaQuery.sizeOf(context).height * 0.65;

    final estimatedOffset =
    (targetIndex * estimatedItemHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      estimatedOffset,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );

    await WidgetsBinding.instance.endOfFrame;

    final newContext =
        _duaKeys[lastReadDuaId!]?.currentContext;

    if (newContext != null) {
      await Scrollable.ensureVisible(
        newContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  Future<void> _startAutoScroll() async {
    if (_isAutoScrolling || _isScrollLoopRunning) return;
    if (!_scrollController.hasClients) return;

    setState(() {
      _isAutoScrolling = true;
      _isScrollLoopRunning = true;
    });

    const frameDuration = Duration(milliseconds: 16);

    try {
      while (mounted && _isAutoScrolling) {
        await Future.delayed(frameDuration);

        if (!mounted ||
            !_isAutoScrolling ||
            !_scrollController.hasClients) {
          break;
        }

        final position = _scrollController.position;

        if (position.pixels >= position.maxScrollExtent) {
          _isAutoScrolling = false;
          break;
        }

        final distance =
            _scrollSpeed * frameDuration.inMilliseconds / 1000;

        final nextOffset = (position.pixels + distance).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );

        _scrollController.jumpTo(nextOffset);
      }
    } catch (_) {
      // قد يتغير موضع القائمة أثناء تحديث نتائج البحث.
      // نوقف التمرير بأمان إذا لم يعد موضع التمرير متاحًا.
    } finally {
      _isScrollLoopRunning = false;

      if (mounted) {
        setState(() {
          _isAutoScrolling = false;
        });
      }
    }
  }

  void _pauseAutoScroll() {
    setState(() {
      _isAutoScrolling = false;
    });
  }

  void _stopAutoScroll() {
    _isAutoScrolling = false;

    if (mounted) {
      setState(() {});
    }

    if (_scrollController.hasClients) {
      // يوقف الحركة عند موضعها الحالي دون الرجوع إلى البداية.
      _scrollController.jumpTo(
        _scrollController.position.pixels,
      );
    }
  }

  Future<void> _openAddDua() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditDuaPage(),
      ),
    );
  }

  Future<void> _openEditDua(Dua dua) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditDuaPage(dua: dua),
      ),
    );
  }

  Future<void> _deleteDua(Dua dua) async {
    if (dua.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف الدعاء'),
          content: const Text('هل تريد حذف هذا الدعاء؟'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await context.read<DuaCubit>().deleteDua(dua.id!);

    if (!mounted) return;

    if (lastReadDuaId == dua.id) {
      await context.read<DuaCubit>().clearLastReadDua();

      if (!mounted) return;

      setState(() {
        lastReadDuaId = null;
      });
    }
  }

  Future<void> _markAsLastRead(Dua dua) async {
    if (dua.id == null) return;

    await context.read<DuaCubit>().saveLastReadDua(dua.id!);

    if (!mounted) return;

    setState(() {
      lastReadDuaId = dua.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأدعية'),
        centerTitle: true,
        actions: [
          if (lastReadDuaId != null)
            IconButton(
              onPressed: _scrollToLastReadDua,
              tooltip: 'آخر مكان توقفت عنده',
              icon: const Icon(Icons.bookmark),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDua,
        tooltip: 'إضافة دعاء',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<DuaCubit, DuaState>(
        builder: (context, state) {
          if (state is DuaLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is DuaError) {
            return Center(child: Text(state.message));
          }

          if (state is! DuaLoaded) {
            return const SizedBox.shrink();
          }

          final allDuas = state.duas;
          final filteredDuas = _filterDuas(allDuas);

          _cleanDuaKeys(allDuas);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن دعاء...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _pauseAutoScroll();
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.slow_motion_video),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('سرعة التمرير'),
                        ),
                        Text(
                          '${_scrollSpeed.round()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: 5,
                      max: 80,
                      divisions: 15,
                      value: _scrollSpeed,
                      label: '${_scrollSpeed.round()}',
                      onChanged: (value) {
                        setState(() {
                          _scrollSpeed = value;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _isAutoScrolling
                              ? _pauseAutoScroll
                              : _startAutoScroll,
                          icon: Icon(
                            _isAutoScrolling
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            _isAutoScrolling
                                ? 'إيقاف مؤقت'
                                : 'تشغيل التمرير',
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _stopAutoScroll,
                          icon: const Icon(Icons.stop),
                          label: const Text('إيقاف'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_searchQuery.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'النتائج: ${filteredDuas.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: filteredDuas.isEmpty
                    ? const Center(
                  child: Text('لا توجد أدعية مطابقة للبحث'),
                )
                    : ReorderableListView.builder(
                  scrollController: _scrollController,
                  padding: const EdgeInsets.all(12),
                  buildDefaultDragHandles: false,
                  itemCount: filteredDuas.length,
                  onReorder: (oldIndex, newIndex) {
                    // لا نعيد ترتيب القائمة الأصلية باستخدام
                    // مؤشرات نتائج البحث.
                    if (_searchQuery.trim().isNotEmpty) {
                      return;
                    }

                    context.read<DuaCubit>().reorderDuas(
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final dua = filteredDuas[index];

                    if (dua.id == null) {
                      return const SizedBox.shrink(
                        key: ValueKey('invalid-dua'),
                      );
                    }

                    final originalIndex =
                    allDuas.indexWhere(
                          (item) => item.id == dua.id,
                    );

                    final duaKey = _duaKeys.putIfAbsent(
                      dua.id!,
                          () => GlobalKey(),
                    );

                    return Container(
                      key: duaKey,
                      child: DuaCard(
                        key: ValueKey(dua.id),
                        dua: dua,
                        number: originalIndex + 1,
                        dragIndex: index,
                        canReorder:
                        _searchQuery.trim().isEmpty,
                        isLastRead:
                        dua.id == lastReadDuaId,
                        onTap: () => _markAsLastRead(dua),
                        onEdit: () => _openEditDua(dua),
                        onDelete: () => _deleteDua(dua),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
