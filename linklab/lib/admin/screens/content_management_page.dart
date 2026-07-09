import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/admin_models.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_data_service.dart';

/// 内容管理页面
class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({super.key});

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  final _dataService = AdminDataService();
  final _authService = AdminAuthService();

  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  List<ContentItem> _contents = [];
  bool _isLoading = false;

  String? _selectedStatus;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() => _isLoading = true);

    final result = await _dataService.getContents(
      page: _currentPage,
      pageSize: _pageSize,
      status: _selectedStatus,
      type: _selectedType,
    );

    setState(() {
      _contents = result.items;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
  }

  void _resetFilters() {
    _selectedStatus = null;
    _selectedType = null;
    _currentPage = 1;
    _loadContents();
  }

  Future<void> _toggleContentStatus(ContentItem content) async {
    final action = content.status == 'published' ? '下架' : '发布';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认$action'),
        content: Text('确定要$action "${content.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _dataService.toggleContentStatus(
        content.id,
        content.status != 'published',
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已$action内容')),
        );
        _loadContents();
      }
    }
  }

  Future<void> _deleteContent(ContentItem content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${content.title}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _dataService.deleteContent(content.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除内容')),
        );
        _loadContents();
      }
    }
  }

  void _showContentDetail(ContentItem content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(content.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('作者: ${content.authorName}'),
                  const SizedBox(width: 24),
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${content.viewCount} 阅读'),
                  const SizedBox(width: 24),
                  Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${content.likeCount} 点赞'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(content.content),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                  if (_authService.hasPermission('content.edit')) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _toggleContentStatus(content);
                      },
                      child: Text(content.status == 'published' ? '下架' : '发布'),
                    ),
                  ],
                  if (_authService.hasPermission('content.delete')) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteContent(content);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('删除'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'published':
        color = Colors.green;
        label = '已发布';
        break;
      case 'draft':
        color = Colors.grey;
        label = '草稿';
        break;
      case 'pending':
        color = Colors.orange;
        label = '待审核';
        break;
      case 'rejected':
        color = Colors.red;
        label = '已拒绝';
        break;
      case 'archived':
        color = Colors.blue;
        label = '已归档';
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
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和筛选栏
          Row(
            children: [
              const Text(
                '内容管理',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 类型筛选
              DropdownButton<String>(
                value: _selectedType,
                hint: const Text('类型'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全部类型')),
                  DropdownMenuItem(value: 'story', child: Text('故事')),
                  DropdownMenuItem(value: 'announcement', child: Text('公告')),
                  DropdownMenuItem(value: 'guide', child: Text('指南')),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value);
                  _loadContents();
                },
              ),
              const SizedBox(width: 12),
              // 状态筛选
              DropdownButton<String>(
                value: _selectedStatus,
                hint: const Text('状态'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全部状态')),
                  DropdownMenuItem(value: 'published', child: Text('已发布')),
                  DropdownMenuItem(value: 'draft', child: Text('草稿')),
                  DropdownMenuItem(value: 'pending', child: Text('待审核')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _loadContents();
                },
              ),
              const SizedBox(width: 12),
              // 重置按钮
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('重置'),
              ),
              const SizedBox(width: 12),
              // 新建按钮
              if (_authService.hasPermission('content.edit'))
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 实现新建内容
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新建内容'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 数据表格
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: DataTable2(
                      columns: const [
                        DataColumn2(label: Text('标题'), size: ColumnSize.L),
                        DataColumn2(label: Text('类型'), size: ColumnSize.S),
                        DataColumn2(label: Text('作者'), size: ColumnSize.M),
                        DataColumn2(label: Text('状态'), size: ColumnSize.S),
                        DataColumn2(label: Text('数据'), size: ColumnSize.M),
                        DataColumn2(label: Text('发布时间'), size: ColumnSize.M),
                        DataColumn2(label: Text('操作'), size: ColumnSize.S),
                      ],
                      rows: _contents.map((content) {
                        return DataRow2(
                          cells: [
                            DataCell(
                              Text(
                                content.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(_buildTypeChip(content.type)),
                            DataCell(Text(content.authorName)),
                            DataCell(_buildStatusChip(content.status)),
                            DataCell(
                              Row(
                                children: [
                                  Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('${content.viewCount}'),
                                  const SizedBox(width: 12),
                                  Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('${content.likeCount}'),
                                ],
                              ),
                            ),
                            DataCell(Text(_formatDate(content.publishedAt))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 20),
                                    tooltip: '查看详情',
                                    onPressed: () => _showContentDetail(content),
                                  ),
                                  if (_authService.hasPermission('content.edit'))
                                    IconButton(
                                      icon: Icon(
                                        content.status == 'published'
                                            ? Icons.unpublished
                                            : Icons.publish,
                                        size: 20,
                                      ),
                                      tooltip: content.status == 'published' ? '下架' : '发布',
                                      onPressed: () => _toggleContentStatus(content),
                                    ),
                                  if (_authService.hasPermission('content.delete'))
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      tooltip: '删除',
                                      onPressed: () => _deleteContent(content),
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

          // 分页
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadContents();
                      }
                    : null,
              ),
              Text('第 $_currentPage / $_totalPages 页'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadContents();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    String label;
    Color color;

    switch (type) {
      case 'story':
        label = '故事';
        color = Colors.purple;
        break;
      case 'announcement':
        label = '公告';
        color = Colors.blue;
        break;
      case 'guide':
        label = '指南';
        color = Colors.green;
        break;
      default:
        label = type;
        color = Colors.grey;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontSize: 11),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
