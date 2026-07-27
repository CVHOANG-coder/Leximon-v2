import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/topic.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';
import '../topic_detail/topic_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _showAllTopics = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final filter = ref.watch(selectedTopicFilterProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(child: _LearningHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            sliver: SliverToBoxAdapter(child: _DailyCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
            sliver: SliverToBoxAdapter(
              child: LeximonSurface(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
                child: Column(
                  children: [
                    const SectionHeader(
                      kicker: 'Thư viện từ vựng',
                      title: 'Chọn chủ đề để học',
                    ),
                    const SizedBox(height: 15),
                    _SearchRow(
                      controller: _searchController,
                      onChanged: (value) => setState(() {
                        _search = value.trim().toLowerCase();
                        _showAllTopics = false;
                      }),
                    ),
                    const SizedBox(height: 13),
                    _FilterChips(
                      selected: filter,
                      onSelected: (_) => setState(() => _showAllTopics = false),
                    ),
                    const SizedBox(height: 15),
                    topicsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Không thể tải chủ đề.'),
                      ),
                      data: (topics) {
                        final matchingTopics = _filterTopics(
                          topics,
                          filter,
                          _search,
                        );
                        final visibleTopics = _showAllTopics
                            ? matchingTopics
                            : matchingTopics.take(10).toList();
                        return Column(
                          children: [
                            _TopicGrid(topics: visibleTopics),
                            if (matchingTopics.length > 10) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => setState(
                                  () => _showAllTopics = !_showAllTopics,
                                ),
                                icon: Icon(
                                  _showAllTopics
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  _showAllTopics
                                      ? 'Thu gọn'
                                      : 'Xem tất cả ${filter == 'Tất cả' && _search.isEmpty ? 48 : matchingTopics.length} chủ đề',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                  padding: EdgeInsets.zero,
                                  foregroundColor: AppColors.primary,
                                  backgroundColor: AppColors.surfaceBlue,
                                  side: BorderSide.none,
                                  textStyle: const TextStyle(
                                    inherit: false,
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 28),
            sliver: SliverToBoxAdapter(child: _QuickPractice()),
          ),
        ],
      ),
    );
  }

  List<Topic> _filterTopics(List<Topic> topics, String filter, String search) {
    final filteredTopics = topics.where((topic) {
      final matchesSearch =
          search.isEmpty ||
          topic.translated.toLowerCase().contains(search) ||
          topic.original.toLowerCase().contains(search);
      final progress = topicProgress(topic);
      final matchesFilter =
          filter == 'Tất cả' ||
          (filter == 'Đang học' && progress > 0) ||
          (filter == 'Cơ bản' && topic.order <= 10) ||
          (filter == 'Giao tiếp' &&
              topic.original.toLowerCase().contains('communication')) ||
          (filter == 'Công việc' &&
              topic.original.toLowerCase().contains('work'));
      return matchesSearch && matchesFilter;
    }).toList();
    return filteredTopics;
  }
}

class _LearningHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const OwlAvatar(size: 46, radius: 15),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XIN CHÀO, HỌC GIẢ!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Leximon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEEF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2426448B),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3BF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    '🔥  Chuỗi 7 ngày',
                    style: TextStyle(
                      color: Color(0xFF8B5B00),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'MỤC TIÊU HÔM NAY',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '8 / 12 từ',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 11),
                const ProgressLine(value: .67),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 153,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x361558FF),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiếp tục',
                        style: TextStyle(
                          color: Color(0xFFA9D9FF),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Du lịch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              hintText: 'Tìm chủ đề hoặc từ vựng',
              hintStyle: TextStyle(fontSize: 11),
              contentPadding: EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.selected, this.onSelected});
  final String selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const labels = ['Tất cả', 'Đang học', 'Cơ bản', 'Giao tiếp', 'Công việc'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels
            .map(
              (label) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected == label,
                  onSelected: (_) {
                    ref.read(selectedTopicFilterProvider.notifier).state =
                        label;
                    onSelected?.call(label);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceSoft,
                  labelStyle: TextStyle(
                    color: selected == label
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide.none,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.topics});
  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Không có chủ đề phù hợp.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 74,
      ),
      itemBuilder: (context, index) => TopicCard(
        topic: topics[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TopicDetailScreen(topic: topics[index]),
          ),
        ),
      ),
    );
  }
}

class _QuickPractice extends StatelessWidget {
  const _QuickPractice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x19155CFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF9EF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.sync_rounded, color: Color(0xFF137E68)),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ôn nhanh hôm nay',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '4 từ sắp quên • khoảng 2 phút',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
