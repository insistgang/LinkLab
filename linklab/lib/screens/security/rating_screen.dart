import 'package:flutter/material.dart';
import '../../models/security/credit_score_model.dart';
import '../../services/security/rating_service.dart';
import '../../widgets/accessible/accessible_scaffold.dart';
import '../../widgets/accessible/accessible_button.dart';

/// 評價頁面
class RatingScreen extends StatefulWidget {
  final String helpRequestId;
  final String callId;
  final String fromUserId;
  final String toUserId;
  final String? toUserName;
  final bool isSeekerToVolunteer;

  const RatingScreen({
    super.key,
    required this.helpRequestId,
    required this.callId,
    required this.fromUserId,
    required this.toUserId,
    this.toUserName,
    this.isSeekerToVolunteer = true,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final RatingService _ratingService = RatingService();
  final _commentController = TextEditingController();

  int _rating = 0;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _positiveTags = [
    {'label': '耐心細緻', 'icon': Icons.favorite},
    {'label': '專業高效', 'icon': Icons.star},
    {'label': '態度友好', 'icon': Icons.emoji_emotions},
    {'label': '溝通清晰', 'icon': Icons.record_voice_over},
    {'label': '幫助很大', 'icon': Icons.thumb_up},
  ];

  final List<Map<String, dynamic>> _negativeTags = [
    {'label': '態度冷淡', 'icon': Icons.sentiment_dissatisfied},
    {'label': '溝通困難', 'icon': Icons.hearing_disabled},
    {'label': '不夠耐心', 'icon': Icons.timer_off},
    {'label': '未解決問題', 'icon': Icons.help_outline},
    {'label': '提前掛斷', 'icon': Icons.call_end},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇評分')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final record = await _ratingService.submitRating(
        helpRequestId: widget.helpRequestId,
        callId: widget.callId,
        fromUserId: widget.fromUserId,
        toUserId: widget.toUserId,
        rating: _rating,
        comment: _commentController.text.isEmpty
            ? null
            : _commentController.text,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        isSeekerToVolunteer: widget.isSeekerToVolunteer,
      );

      if (mounted && record != null) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('評價失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('評價成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '感謝您的評價！',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _rating >= 4
                  ? '您的好評將幫助對方獲得更多匹配機會'
                  : '您的反饋將幫助我們改進服務質量',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '評價',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildStarRating(),
            const SizedBox(height: 32),
            if (_rating > 0) _buildTagsSelection(),
            const SizedBox(height: 24),
            _buildCommentInput(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.toUserName ?? '對方用戶',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isSeekerToVolunteer
                ? '本次通話體驗如何？'
                : '請對本次求助進行評價',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = starIndex;
                    _selectedTags.clear();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    size: 48,
                    color: starIndex <= _rating ? Colors.amber : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _getRatingText(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _rating > 0 ? _getRatingColor() : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return '非常不滿意';
      case 2:
        return '不滿意';
      case 3:
        return '一般';
      case 4:
        return '滿意';
      case 5:
        return '非常滿意';
      default:
        return '點擊星星評分';
    }
  }

  Color _getRatingColor() {
    if (_rating <= 2) return Colors.red;
    if (_rating == 3) return Colors.orange;
    return Colors.green;
  }

  Widget _buildTagsSelection() {
    final tags = _rating >= 4 ? _positiveTags : _negativeTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _rating >= 4 ? '優點標籤（可多選）' : '問題標籤（可多選）',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = _selectedTags.contains(tag['label']);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tag['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(tag['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag['label'] as String);
                  } else {
                    _selectedTags.remove(tag['label'] as String);
                  }
                });
              },
              selectedColor: _rating >= 4 ? Colors.green : Colors.red,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '詳細評價（可選）',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '請輸入您的評價內容...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AccessibleButton(
        onPressed: _isSubmitting ? null : _submitRating,
        label: _isSubmitting ? '提交中...' : '提交評價',
        icon: Icons.send,
      ),
    );
  }
}

/// 評價詳情頁面
class RatingDetailScreen extends StatefulWidget {
  final String userId;

  const RatingDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<RatingDetailScreen> createState() => _RatingDetailScreenState();
}

class _RatingDetailScreenState extends State<RatingDetailScreen> {
  final RatingService _ratingService = RatingService();
  RatingStatistics? _statistics;
  List<RatingRecord> _ratings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _ratingService.getRatingStatistics(widget.userId);
      final ratings = await _ratingService.getUserRatings(widget.userId);

      setState(() {
        _statistics = stats;
        _ratings = ratings;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '評價詳情',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatisticsCard(),
                    const SizedBox(height: 24),
                    _buildRatingsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _statistics;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.deepPurple.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      stats.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < stats.averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${stats.totalRatings}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '總評價數',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRatingBar(5, stats.fiveStarCount, stats.totalRatings),
          _buildRatingBar(4, stats.fourStarCount, stats.totalRatings),
          _buildRatingBar(3, stats.threeStarCount, stats.totalRatings),
          _buildRatingBar(2, stats.twoStarCount, stats.totalRatings),
          _buildRatingBar(1, stats.oneStarCount, stats.totalRatings),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$star星',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsList() {
    if (_ratings.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '暫無評價',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最新評價',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._ratings.map((rating) => _buildRatingItem(rating)),
      ],
    );
  }

  Widget _buildRatingItem(RatingRecord rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.rating ? Icons.star : Icons.star_border,
                      color: index < rating.rating ? Colors.amber : Colors.grey[300],
                      size: 16,
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  _formatDate(rating.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            if (rating.comment != null) ...[
              const SizedBox(height: 12),
              Text(
                rating.comment!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (rating.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rating.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
