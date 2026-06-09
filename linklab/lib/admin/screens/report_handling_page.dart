import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/admin_models.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_data_service.dart';

/// 舉報處理頁面
class ReportHandlingPage extends StatefulWidget {
  const ReportHandlingPage({super.key});

  @override
  State<ReportHandlingPage> createState() => _ReportHandlingPageState();
}

class _ReportHandlingPageState extends State<ReportHandlingPage> {
  final _dataService = AdminDataService();
  final _authService = AdminAuthService();

  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  List<ReportRecord> _reports = [];
  bool _isLoading = false;

  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    final result = await _dataService.getReports(
      page: _currentPage,
      pageSize: _pageSize,
      status: _selectedStatus,
    );

    setState(() {
      _reports = result.items;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
  }

  void _resetFilters() {
    _selectedStatus = null;
    _currentPage = 1;
    _loadReports();
  }

  void _showReportDetail(ReportRecord report) {
    final resolutionController = TextEditingController();
    String selectedAction = 'warning';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('舉報詳情'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('舉報ID', report.id),
                _buildDetailRow('舉報人', report.reporterName),
                _buildDetailRow('被舉報對象', report.targetName),
                _buildDetailRow('對象類型', _getTargetTypeText(report.targetType)),
                _buildDetailRow('舉報原因', report.reason),
                _buildDetailRow('狀態', _getStatusText(report.status)),
                const SizedBox(height: 16),
                const Text(
                  '詳細描述：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(report.description ?? '無詳細描述'),
                ),
                if (report.status == 'pending' || report.status == 'processing') ...[
                  const SizedBox(height: 24),
                  const Text(
                    '處理操作：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setState) => Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedAction,
                          decoration: const InputDecoration(
                            labelText: '處理措施',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'warning',
                              child: Text('警告'),
                            ),
                            DropdownMenuItem(
                              value: 'temp_ban',
                              child: Text('臨時封禁'),
                            ),
                            DropdownMenuItem(
                              value: 'permanent_ban',
                              child: Text('永久封禁'),
                            ),
                            DropdownMenuItem(
                              value: 'dismiss',
                              child: Text('駁回舉報'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => selectedAction = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: resolutionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '處理說明',
                            hintText: '請輸入處理說明...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
          if ((report.status == 'pending' || report.status == 'processing') &&
              _authService.hasPermission('reports.handle'))
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleReport(report, selectedAction, resolutionController.text);
              },
              child: const Text('提交處理'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleReport(ReportRecord report, String action, String resolution) async {
    final success = await _dataService.handleReport(
      report.id,
      action,
      resolution: resolution.isNotEmpty ? resolution : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('舉報已處理')),
      );
      _loadReports();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getTargetTypeText(String type) {
    switch (type) {
      case 'user':
        return '用戶';
      case 'content':
        return '內容';
      case 'call':
        return '通話';
      default:
        return type;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待處理';
      case 'processing':
        return '處理中';
      case 'resolved':
        return '已解決';
      case 'dismissed':
        return '已駁回';
      default:
        return status;
    }
  }

  String _getActionText(String? action) {
    switch (action) {
      case 'warning':
        return '警告';
      case 'temp_ban':
        return '臨時封禁';
      case 'permanent_ban':
        return '永久封禁';
      case 'dismiss':
        return '駁回';
      default:
        return action ?? '-';
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = '待處理';
        break;
      case 'processing':
        color = Colors.blue;
        label = '處理中';
        break;
      case 'resolved':
        color = Colors.green;
        label = '已解決';
        break;
      case 'dismissed':
        color = Colors.grey;
        label = '已駁回';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題和篩選欄
          Row(
            children: [
              const Text(
                '舉報處理',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 狀態篩選
              DropdownButton<String>(
                value: _selectedStatus,
                hint: const Text('狀態'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全部狀態')),
                  DropdownMenuItem(value: 'pending', child: Text('待處理')),
                  DropdownMenuItem(value: 'processing', child: Text('處理中')),
                  DropdownMenuItem(value: 'resolved', child: Text('已解決')),
                  DropdownMenuItem(value: 'dismissed', child: Text('已駁回')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _loadReports();
                },
              ),
              const SizedBox(width: 12),
              // 重置按鈕
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 數據表格
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: DataTable2(
                      columns: const [
                        DataColumn2(label: Text('舉報人'), size: ColumnSize.M),
                        DataColumn2(label: Text('被舉報對象'), size: ColumnSize.M),
                        DataColumn2(label: Text('類型'), size: ColumnSize.S),
                        DataColumn2(label: Text('原因'), size: ColumnSize.M),
                        DataColumn2(label: Text('狀態'), size: ColumnSize.S),
                        DataColumn2(label: Text('處理結果'), size: ColumnSize.S),
                        DataColumn2(label: Text('舉報時間'), size: ColumnSize.M),
                        DataColumn2(label: Text('操作'), size: ColumnSize.S),
                      ],
                      rows: _reports.map((report) {
                        return DataRow2(
                          cells: [
                            DataCell(Text(report.reporterName)),
                            DataCell(Text(report.targetName)),
                            DataCell(Text(_getTargetTypeText(report.targetType))),
                            DataCell(
                              Text(
                                report.reason,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(_buildStatusChip(report.status)),
                            DataCell(Text(_getActionText(report.action))),
                            DataCell(Text(_formatDate(report.createdAt))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 20),
                                    tooltip: '查看詳情',
                                    onPressed: () => _showReportDetail(report),
                                  ),
                                  if ((report.status == 'pending' ||
                                          report.status == 'processing') &&
                                      _authService.hasPermission('reports.handle'))
                                    IconButton(
                                      icon: const Icon(
                                        Icons.gavel,
                                        size: 20,
                                        color: Colors.orange,
                                      ),
                                      tooltip: '處理',
                                      onPressed: () => _showReportDetail(report),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),

          // 分頁
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadReports();
                      }
                    : null,
              ),
              Text('第 $_currentPage / $_totalPages 頁'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadReports();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
