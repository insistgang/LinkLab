import 'package:flutter/material.dart';

import '../home/main_screen.dart';
import '../../services/demo_call_service.dart';

/// 演示版通话评价页面
class DemoCallRatingScreen extends StatefulWidget {
  final DemoVolunteer volunteer;
  final Duration duration;

  const DemoCallRatingScreen({
    super.key,
    required this.volunteer,
    required this.duration,
  });

  @override
  State<DemoCallRatingScreen> createState() => _DemoCallRatingScreenState();
}

class _DemoCallRatingScreenState extends State<DemoCallRatingScreen> {
  final DemoCallService _callService = DemoCallService();
  final TextEditingController _feedbackController = TextEditingController();

  int _rating = 0;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  // 评价标签
  final List<String> _positiveTags = ['耐心细致', '专业高效', '态度友好', '解决问题', '沟通顺畅'];

  final List<String> _negativeTags = ['沟通困难', '未能解决', '态度冷淡', '网络卡顿', '声音不清'];

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请给出评分')));
      return;
    }

    setState(() => _isSubmitting = true);

    await _callService.submitSeekerRating(
      rating: _rating,
      tags: _selectedTags,
      feedback: _feedbackController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _rating >= 4 ? '感谢您的评价，已同步到帮助档案和常用志愿者。' : '感谢您的评价，已同步到帮助档案。',
          ),
        ),
      );
      _returnToMain();
    }
  }

  void _skipRating() {
    _returnToMain();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes分${seconds}秒';
    }
    return '$seconds秒';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _skipRating,
          icon: const Icon(Icons.close, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: _skipRating,
            child: const Text('跳过', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 志愿者信息
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  widget.volunteer.name[0],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.volunteer.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '通话时长: ${_formatDuration(widget.duration)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '4 星及以上会加入“常用志愿者”',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 标题
            const Text(
              '为这次帮助评分',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // 星级评分
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? Colors.amber : Colors.grey[400],
                    size: 48,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              _rating > 0 ? _getRatingText(_rating) : '点击星星评分',
              style: TextStyle(
                fontSize: 18,
                color: _rating > 0 ? Colors.amber[700] : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            // 评价标签
            if (_rating > 0) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '选择标签（可多选）',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: (_rating >= 4 ? _positiveTags : _negativeTags)
                    .map((tag) => _buildTagChip(tag))
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],
            // 文字反馈
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '写下您的具体反馈（可选）',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 40),
            // 提交按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '提交评价',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    return FilterChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.remove(tag);
          }
        });
      },
      selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
      checkmarkColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.grey[700],
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '非常不满意';
      case 2:
        return '不满意';
      case 3:
        return '一般';
      case 4:
        return '满意';
      case 5:
        return '非常满意';
      default:
        return '';
    }
  }

  void _returnToMain() {
    _callService.reset();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
