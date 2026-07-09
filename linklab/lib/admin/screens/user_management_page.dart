import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/admin_models.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_data_service.dart';

/// 用户管理页面
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _dataService = AdminDataService();
  final _authService = AdminAuthService();

  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  List<UserListItem> _users = [];
  bool _isLoading = false;

  // 筛选条件
  final _searchController = TextEditingController();
  String? _selectedRole;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final filter = UserFilter(
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      roles: _selectedRole != null ? [_selectedRole!] : null,
      status: _selectedStatus,
    );

    final result = await _dataService.getUsers(
      page: _currentPage,
      pageSize: _pageSize,
      filter: filter,
    );

    setState(() {
      _users = result.items;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _selectedRole = null;
    _selectedStatus = null;
    _currentPage = 1;
    _loadUsers();
  }

  Future<void> _toggleUserBan(UserListItem user) async {
    final action = user.status == 'banned' ? '解封' : '封禁';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认$action用户'),
        content: Text('确定要$action用户 "${user.name ?? user.phone}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.status == 'banned' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _dataService.toggleUserBan(user.id, user.status != 'banned');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已$action用户')),
        );
        _loadUsers();
      }
    }
  }

  void _showUserDetail(UserListItem user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(user.name?.substring(0, 1) ?? user.phone.substring(0, 1))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? '未设置昵称',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${user.id}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '手机号: ${user.phone}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(user.status),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // 用户信息详情
              _buildDetailRow('角色', _getRolesText(user.roles)),
              _buildDetailRow('残障类型', _getDisabilityText(user.disabilityTypes)),
              _buildDetailRow('注册时间', _formatDate(user.createdAt)),
              _buildDetailRow('最后登录', _formatDate(user.lastLoginAt)),
              _buildDetailRow('求助次数', user.helpRequestCount.toString()),
              _buildDetailRow('帮助次数', user.volunteerCount.toString()),
              _buildDetailRow('残障认证', user.isDisabilityVerified == true ? '已认证' : '未认证'),
              _buildDetailRow('志愿者认证', user.isVolunteerVerified == true ? '已认证' : '未认证'),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                  if (_authService.hasPermission('users.ban')) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _toggleUserBan(user);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.status == 'banned' ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(user.status == 'banned' ? '解封用户' : '封禁用户'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = '正常';
        break;
      case 'banned':
        color = Colors.red;
        label = '已封禁';
        break;
      case 'pending_verification':
        color = Colors.orange;
        label = '待认证';
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

  String _getRolesText(List<String> roles) {
    return roles.map((r) {
      switch (r) {
        case 'seeker':
          return '求助者';
        case 'volunteer':
          return '志愿者';
        default:
          return r;
      }
    }).join('、');
  }

  String _getDisabilityText(List<String> types) {
    if (types.isEmpty) return '无';
    return types.map((t) {
      switch (t) {
        case 'visual':
          return '视障';
        case 'hearing':
          return '听障';
        case 'physical':
          return '肢体障碍';
        default:
          return t;
      }
    }).join('、');
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
                '用户列表',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 搜索框
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索用户...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
              ),
              const SizedBox(width: 12),
              // 角色筛选
              DropdownButton<String>(
                value: _selectedRole,
                hint: const Text('角色'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部角色')),
                  const DropdownMenuItem(value: 'seeker', child: Text('求助者')),
                  const DropdownMenuItem(value: 'volunteer', child: Text('志愿者')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                  _loadUsers();
                },
              ),
              const SizedBox(width: 12),
              // 状态筛选
              DropdownButton<String>(
                value: _selectedStatus,
                hint: const Text('状态'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部状态')),
                  const DropdownMenuItem(value: 'active', child: Text('正常')),
                  const DropdownMenuItem(value: 'banned', child: Text('已封禁')),
                  const DropdownMenuItem(value: 'pending_verification', child: Text('待认证')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _loadUsers();
                },
              ),
              const SizedBox(width: 12),
              // 重置按钮
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('重置'),
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
                        DataColumn2(label: Text('用户'), size: ColumnSize.L),
                        DataColumn2(label: Text('角色'), size: ColumnSize.M),
                        DataColumn2(label: Text('状态'), size: ColumnSize.S),
                        DataColumn2(label: Text('注册时间'), size: ColumnSize.M),
                        DataColumn2(label: Text('最后登录'), size: ColumnSize.M),
                        DataColumn2(label: Text('操作'), size: ColumnSize.S),
                      ],
                      rows: _users.map((user) {
                        return DataRow2(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: user.avatarUrl != null
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    child: user.avatarUrl == null
                                        ? Text(user.name?.substring(0, 1) ?? '?')
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          user.name ?? '未设置昵称',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          user.phone,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(_getRolesText(user.roles))),
                            DataCell(_buildStatusChip(user.status)),
                            DataCell(Text(_formatDate(user.createdAt))),
                            DataCell(Text(_formatDate(user.lastLoginAt))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 20),
                                    tooltip: '查看详情',
                                    onPressed: () => _showUserDetail(user),
                                  ),
                                  if (_authService.hasPermission('users.ban'))
                                    IconButton(
                                      icon: Icon(
                                        user.status == 'banned'
                                            ? Icons.lock_open
                                            : Icons.block,
                                        size: 20,
                                        color: user.status == 'banned' ? Colors.green : Colors.red,
                                      ),
                                      tooltip: user.status == 'banned' ? '解封' : '封禁',
                                      onPressed: () => _toggleUserBan(user),
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
                        _loadUsers();
                      }
                    : null,
              ),
              Text('第 $_currentPage / $_totalPages 页'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadUsers();
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
