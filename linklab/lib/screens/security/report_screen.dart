import 'package:flutter/material.dart';
import '../../models/security/report_model.dart';
import '../../services/security/report_service.dart';
import '../../widgets/accessible/accessible_scaffold.dart';
import '../../widgets/accessible/accessible_button.dart';

/// 举报页面
class ReportScreen extends StatefulWidget {
  final String reporterId;
  final String reportedId;
  final String? callId;
  final String? helpRequestId;
  final String? reportedName;

  const ReportScreen({
    super.key,
    required this.reporterId,
    required this.reportedId,
    this.callId,
    this.helpRequestId,
    this.reportedName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  final _descriptionController = TextEditingController();

  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _reasonOptions = [
    {
      'value': ReportReason.harassment,
      'icon': Icons.record_voice_over,
      'color': Colors.orange,
    },
    {
      'value': ReportReason.abuse,
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.red,
    },
    {
      'value': ReportReason.fraud,
      'icon': Icons.warning,
      'color': Colors.deepOrange,
    },
    {
      'value': ReportReason.inappropriate,
      'icon': Icons.block,
      'color': Colors.purple,
    },
    {
      'value': ReportReason.noShow,
      'icon': Icons.event_busy,
      'color': Colors.blueGrey,
    },
    {
      'value': ReportReason.other,
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择举报原因')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final report = await _reportService.submitReport(
        reporterId: widget.reporterId,
        reportedId: widget.reportedId,
        reason: _selectedReason!,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        callId: widget.callId,
        helpRequestId: widget.helpRequestId,
      );

      if (mounted && report != null) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('举报失败: $e')),
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
        title: const Text('举报已提交'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              '感谢您的举报，我们会在48小时内进行审核处理。',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '在审核期间，双方将暂时无法进行匹配。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '举报',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildReasonSelection(),
            const SizedBox(height: 24),
            _buildDescriptionInput(),
            const SizedBox(height: 24),
            _buildWarningCard(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.report_problem,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '举报用户',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.reportedName != null)
                  Text(
                    widget.reportedName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '举报原因',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._reasonOptions.map((option) => _buildReasonItem(option)),
      ],
    );
  }

  Widget _buildReasonItem(Map<String, dynamic> option) {
    final reason = option['value'] as ReportReason;
    final icon = option['icon'] as IconData;
    final color = option['color'] as Color;
    final isSelected = _selectedReason == reason;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(reason.label),
        subtitle: Text(
          reason.description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.circle_outlined, color: Colors.grey),
        onTap: () {
          setState(() {
            _selectedReason = reason;
          });
        },
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '详细描述（可选）',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '请简要描述您遇到的问题，有助于我们更快处理',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '请输入详细描述...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                '温馨提示',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '1. 我们会严格保护您的隐私，被举报人不会知道您的身份\n'
            '2. 恶意举报会被记录并影响您的信用分\n'
            '3. 举报后双方将在24小时内无法进行匹配',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AccessibleButton(
        onPressed: _isSubmitting ? null : _submitReport,
        label: _isSubmitting ? '提交中...' : '提交举报',
        icon: Icons.send,
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// 举报记录页面
class ReportHistoryScreen extends StatefulWidget {
  final String userId;

  const ReportHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final ReportService _reportService = ReportService();
  List<Report> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _reportService.getUserReports(widget.userId);
      setState(() => _reports = reports);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '举报记录',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(_reports[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无举报记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    Color statusColor;
    String statusText;

    switch (report.status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        statusText = '待处理';
      case ReportStatus.processing:
        statusColor = Colors.blue;
        statusText = '处理中';
      case ReportStatus.resolved:
        if (report.decision == ReportDecision.valid) {
          statusColor = Colors.green;
          statusText = '举报成立';
        } else if (report.decision == ReportDecision.invalid) {
          statusColor = Colors.red;
          statusText = '举报不成立';
        } else {
          statusColor = Colors.grey;
          statusText = '无法确定';
        }
    }

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
                Expanded(
                  child: Text(
                    ReportReason.values
                        .firstWhere(
                          (r) => r.name == report.reason,
                          orElse: () => ReportReason.other,
                        )
                        .label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text(
                report.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(report.submittedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            if (report.reviewNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.feedback,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '处理反馈: ${report.reviewNote}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
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
