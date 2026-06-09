import 'package:flutter/material.dart';

import '../../models/call_models.dart';

/// 通話結束評價頁面
/// 用戶可以對通話進行評分和反饋
class CallRatingScreen extends StatefulWidget {
  final String callId;
  final CallRole role;
  final Duration duration;

  const CallRatingScreen({
    super.key,
    required this.callId,
    required this.role,
    required this.duration,
  });

  @override
  State<CallRatingScreen> createState() => _CallRatingScreenState();
}

class _CallRatingScreenState extends State<CallRatingScreen> {
  int _rating = 0;
  final List<String> _selectedTags = [];
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  // 評價標籤
  final List<String> _positiveTags = ['耐心細緻', '專業高效', '態度友好', '解決問題', '溝通順暢'];

  final List<String> _negativeTags = ['溝通困難', '未能解決', '態度冷淡', '網絡卡頓', '聲音不清'];

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請給出評分')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 提交評價到服務器
      // await Supabase.instance.client.from('call_ratings').insert({
      //   'call_id': widget.callId,
      //   'rating': _rating,
      //   'tags': _selectedTags,
      //   'feedback': _feedbackController.text,
      //   'created_at': DateTime.now().toIso8601String(),
      // });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('感謝您的評價！')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('提交失敗: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _skipRating() {
    Navigator.pop(context);
  }

  String get _title {
    return widget.role == CallRole.seeker ? '評價志願者' : '評價求助者';
  }

  String get _subtitle {
    final minutes = widget.duration.inMinutes;
    return '通話時長: ${minutes > 0 ? '$minutes分' : ''}${widget.duration.inSeconds % 60}秒';
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
            child: const Text('跳過', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 標題
            Text(
              _title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            // 星級評分
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? Colors.amber : Colors.grey[400],
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _rating > 0 ? _getRatingText(_rating) : '點擊星星評分',
              style: TextStyle(
                fontSize: 16,
                color: _rating > 0 ? Colors.amber[700] : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            // 評價標籤
            if (_rating > 0) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '選擇標籤（可多選）',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_rating >= 4 ? _positiveTags : _negativeTags)
                    .map((tag) => _buildTagChip(tag))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            // 文字反饋
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '寫下您的具體反饋（可選）',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 提交按鈕
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
                        '提交評價',
                        style: TextStyle(
                          fontSize: 16,
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
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
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
        return '';
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
