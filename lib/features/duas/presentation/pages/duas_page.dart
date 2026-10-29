
import 'dart:async';
import 'dart:math' as math;

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

  double _scrollSpeed = 20;

  bool _isAutoScrolling = false;
  bool _isScrollLoopRunning = false;

  // الأدوات مخفية افتراضيًا.
  bool _showSearch = false;
  bool _showScrollControls = false;

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

  void _toggleSearch() {
    if (_showSearch) {
      _searchController.clear();
      _pauseAutoScroll();

      setState(() {
        _showSearch = false;
        _searchQuery = '';
      });
    } else {
      setState(() {
        _showSearch = true;
      });
    }
  }

  void _toggleScrollControls() {
    setState(() {
      _showScrollControls = !_showScrollControls;
    });
  }


  Future<void> _scrollToLastReadDua() async {
    if (lastReadDuaId == null) return;

    final state = context.read<DuaCubit>().state;
    if (state is! DuaLoaded) return;

    if (_searchQuery.isNotEmpty) {
      _searchController.clear();

      setState(() {
        _searchQuery = '';
      });

      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted || !_scrollController.hasClients) return;

    final duas = state.duas;

    final targetIndex = duas.indexWhere(
          (dua) => dua.id == lastReadDuaId,
    );

    if (targetIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الدعاء المحفوظ غير موجود في القائمة.'),
        ),
      );
      return;
    }

    // إذا كان الدعاء موجودًا بالفعل ضمن العناصر المبنية.
    final targetContext = _duaKeys[lastReadDuaId!]?.currentContext;

    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
      return;
    }

    // البحث عن الدعاء في الاتجاه الصحيح:
    // للأعلى إذا كان قبل موضع القراءة، وللأسفل إذا كان بعده.
    for (int attempt = 0; attempt < 300; attempt++) {
      if (!mounted || !_scrollController.hasClients) return;

      final itemContext =
          _duaKeys[lastReadDuaId!]?.currentContext;

      if (itemContext != null) {
        await Scrollable.ensureVisible(
          itemContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
        return;
      }

      // تحديد العناصر التي تم بناؤها حاليًا.
      final builtIndices = <int>[];

      for (final entry in _duaKeys.entries) {
        if (entry.value.currentContext == null) continue;

        final index = duas.indexWhere(
              (dua) => dua.id == entry.key,
        );

        if (index >= 0) {
          builtIndices.add(index);
        }
      }

      if (builtIndices.isEmpty) {
        // لا توجد عناصر مبنية يمكن الاستدلال منها؛ نبدأ من الأعلى.
        final position = _scrollController.position;

        if (position.pixels > position.minScrollExtent) {
          await _scrollController.animateTo(
            position.minScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
          await WidgetsBinding.instance.endOfFrame;
          continue;
        }

        await WidgetsBinding.instance.endOfFrame;
        continue;
      }

      builtIndices.sort();

      final firstBuiltIndex = builtIndices.first;
      final lastBuiltIndex = builtIndices.last;

      final position = _scrollController.position;
      final step = math.max(
        100.0,
        position.viewportDimension * 0.6,
      );

      double nextOffset;

      if (targetIndex < firstBuiltIndex) {
        // الدعاء المطلوب أعلى العناصر المبنية؛ نتحرك للأعلى.
        nextOffset = math.max(
          position.minScrollExtent,
          position.pixels - step,
        );
      } else if (targetIndex > lastBuiltIndex) {
        // الدعاء المطلوب أسفل العناصر المبنية؛ نتحرك للأسفل.
        nextOffset = math.min(
          position.maxScrollExtent,
          position.pixels + step,
        );
      } else {
        // إذا كان الهدف بين العناصر المبنية، نتحرك حسب أقرب عنصر.
        final nearestIndex = builtIndices.reduce(
              (a, b) =>
          (a - targetIndex).abs() <= (b - targetIndex).abs()
              ? a
              : b,
        );

        if (targetIndex < nearestIndex) {
          nextOffset = math.max(
            position.minScrollExtent,
            position.pixels - step,
          );
        } else {
          nextOffset = math.min(
            position.maxScrollExtent,
            position.pixels + step,
          );
        }
      }

      if ((nextOffset - position.pixels).abs() < 1) {
        // وصلنا إلى طرف القائمة؛ نعطي Flutter فرصة لبناء العناصر.
        await WidgetsBinding.instance.endOfFrame;

        final finalContext =
            _duaKeys[lastReadDuaId!]?.currentContext;

        if (finalContext != null) {
          await Scrollable.ensureVisible(
            finalContext,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.15,
          );
          return;
        }

        break;
      }

      await _scrollController.animateTo(
        nextOffset,
        duration: const Duration(milliseconds: 120),
        curve: Curves.linear,
      );

      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted) return;

    // محاولة أخيرة إذا أصبح العنصر متاحًا.
    final finalContext =
        _duaKeys[lastReadDuaId!]?.currentContext;

    if (finalContext != null) {
      await Scrollable.ensureVisible(
        finalContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تعذر الوصول إلى الدعاء المحفوظ. حاول مرة أخرى.',
        ),
      ),
    );
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
      // إيقاف آمن إذا تغير موضع التمرير أثناء الحركة.
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
          IconButton(
            onPressed: _toggleSearch,
            tooltip: _showSearch ? 'إخفاء البحث' : 'البحث',
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
            ),
          ),
          IconButton(
            onPressed: _toggleScrollControls,
            tooltip: _showScrollControls
                ? 'إخفاء أدوات التمرير'
                : 'أدوات التمرير',
            icon: Icon(
              _showScrollControls
                  ? Icons.slow_motion_video
                  : Icons.play_circle_outline,
            ),
          ),
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
              // البحث لا يظهر إلا عند الضغط على أيقونته.
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
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

              // أدوات التمرير مخفية افتراضيًا.
              if (_showScrollControls)
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

                    final originalIndex = allDuas.indexWhere(
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
                        isLastRead: dua.id == lastReadDuaId,
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
