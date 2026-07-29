import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../bloc/user_bloc.dart';
import '../constants/app_constants.dart';
import '../constants/theme.dart';
import '../models/user_model.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc()..add(const UserLoadRequested()),
      child: const _UsersContent(),
    );
  }
}

class _UsersContent extends StatefulWidget {
  const _UsersContent();

  @override
  State<_UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<_UsersContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: [
          // Search
          if (!isMobile)
            SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索用户...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<UserBloc>().add(
                                const UserSearchChanged(''),
                              );
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    context.read<UserBloc>().add(UserSearchChanged(value));
                  },
                ),
              ),
            ),
          const SizedBox(width: 16),
          // Filters
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选',
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部用户')),
              const PopupMenuItem(value: 'disabled', child: Text('残障用户')),
              const PopupMenuItem(value: 'volunteer', child: Text('志愿者')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'active', child: Text('正常用户')),
              const PopupMenuItem(value: 'banned', child: Text('已封禁')),
              const PopupMenuItem(value: 'pending', child: Text('待审核')),
            ],
            onSelected: (value) {
              switch (value) {
                case 'disabled':
                  context.read<UserBloc>().add(
                    const UserFilterChanged(userType: 'disabled'),
                  );
                  break;
                case 'volunteer':
                  context.read<UserBloc>().add(
                    const UserFilterChanged(userType: 'volunteer'),
                  );
                  break;
                case 'active':
                  context.read<UserBloc>().add(
                    const UserFilterChanged(status: UserStatus.active),
                  );
                  break;
                case 'banned':
                  context.read<UserBloc>().add(
                    const UserFilterChanged(status: UserStatus.banned),
                  );
                  break;
                case 'pending':
                  context.read<UserBloc>().add(
                    const UserFilterChanged(status: UserStatus.pending),
                  );
                  break;
                default:
                  context.read<UserBloc>().add(const UserFilterChanged());
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserLoaded) {
            if (isMobile) {
              return _buildMobileList(state);
            }
            return _buildDataTable(state);
          }

          if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UserBloc>().add(const UserLoadRequested());
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDataTable(UserLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: PaginatedDataTable2(
          header: Row(
            children: [
              Text('共 ${state.total} 位用户'),
              const Spacer(),
              if (state.search != null)
                Chip(
                  label: Text('搜索: ${state.search}'),
                  onDeleted: () {
                    _searchController.clear();
                    context.read<UserBloc>().add(const UserSearchChanged(''));
                  },
                ),
              if (state.status != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Chip(
                    label: Text('状态: ${state.status!.name}'),
                    onDeleted: () {
                      context.read<UserBloc>().add(const UserFilterChanged());
                    },
                  ),
                ),
            ],
          ),
          columns: const [
            DataColumn2(label: Text('用户'), size: ColumnSize.L),
            DataColumn2(label: Text('类型'), size: ColumnSize.S),
            DataColumn2(label: Text('状态'), size: ColumnSize.S),
            DataColumn2(label: Text('认证'), size: ColumnSize.S),
            DataColumn2(label: Text('注册时间'), size: ColumnSize.M),
            DataColumn2(label: Text('操作'), size: ColumnSize.S),
          ],
          source: _UserDataSource(
            users: state.users,
            onViewDetail: (user) => _showUserDetail(context, user),
            onBan: (user) => _showBanDialog(context, user),
            onUnban: (user) => _showUnbanDialog(context, user),
            onVerify: (user) => _showVerifyDialog(context, user),
          ),
          rowsPerPage: state.pageSize,
          availableRowsPerPage: const [10, 20, 50],
          onRowsPerPageChanged: (value) {
            if (value != null) {
              context.read<UserBloc>().add(
                UserLoadRequested(
                  page: 1,
                  pageSize: value,
                  search: state.search,
                  status: state.status,
                  role: state.role,
                  userType: state.userType,
                ),
              );
            }
          },
          showFirstLastButtons: true,
          showCheckboxColumn: false,
          initialFirstRowIndex: (state.page - 1) * state.pageSize,
          onPageChanged: (firstRowIndex) {
            final page = (firstRowIndex ~/ state.pageSize) + 1;
            context.read<UserBloc>().add(
              UserLoadRequested(
                page: page,
                pageSize: state.pageSize,
                search: state.search,
                status: state.status,
                role: state.role,
                userType: state.userType,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileList(UserLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return _UserListTile(
          user: user,
          onTap: () => _showUserDetail(context, user),
        );
      },
    );
  }

  void _showUserDetail(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户详情'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID', user.id),
                _buildDetailRow('邮箱', user.email),
                _buildDetailRow('昵称', user.displayName ?? '未设置'),
                _buildDetailRow('角色', user.roleText),
                _buildDetailRow('状态', user.statusText),
                if (user.disabilityType != null) ...[
                  _buildDetailRow('残障类型', user.disabilityType!),
                  _buildDetailRow('认证状态', user.verificationText),
                ],
                if (user.volunteerLevel != null) ...[
                  _buildDetailRow('志愿者等级', user.volunteerLevel!),
                  _buildDetailRow(
                    '积分',
                    user.volunteerPoints?.toString() ?? '0',
                  ),
                  _buildDetailRow(
                    '评分',
                    user.rating?.toStringAsFixed(1) ?? '0.0',
                  ),
                  _buildDetailRow('总通话', user.totalCalls?.toString() ?? '0'),
                ],
                _buildDetailRow(
                  '注册时间',
                  user.createdAt.toString().substring(0, 19),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          if (user.status == UserStatus.active)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBanDialog(context, user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('封禁'),
            )
          else if (user.status == UserStatus.banned)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showUnbanDialog(context, user);
              },
              child: const Text('解封'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context, UserModel user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('封禁用户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要封禁用户 ${user.displayName ?? user.email} 吗？'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '封禁原因（可选）',
                hintText: '请输入封禁原因',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserBloc>().add(
                UserBanRequested(user.id, reason: reasonController.text),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('确认封禁'),
          ),
        ],
      ),
    );
  }

  void _showUnbanDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解封用户'),
        content: Text('确定要解封用户 ${user.displayName ?? user.email} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserBloc>().add(UserUnbanRequested(user.id));
            },
            child: const Text('确认解封'),
          ),
        ],
      ),
    );
  }

  void _showVerifyDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('认证审核'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('用户: ${user.displayName ?? user.email}'),
            if (user.disabilityCertificateUrl != null) ...[
              const SizedBox(height: 16),
              const Text('残障证明:'),
              const SizedBox(height: 8),
              Image.network(
                user.disabilityCertificateUrl!,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: Text('无法加载图片')),
                  );
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserBloc>().add(
                UserVerifyRequested(user.id, VerificationStatus.rejected),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('拒绝'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserBloc>().add(
                UserVerifyRequested(user.id, VerificationStatus.approved),
              );
            },
            child: const Text('通过'),
          ),
        ],
      ),
    );
  }
}

class _UserDataSource extends DataTableSource {
  final List<UserModel> users;
  final Function(UserModel) onViewDetail;
  final Function(UserModel) onBan;
  final Function(UserModel) onUnban;
  final Function(UserModel) onVerify;

  _UserDataSource({
    required this.users,
    required this.onViewDetail,
    required this.onBan,
    required this.onUnban,
    required this.onVerify,
  });

  @override
  DataRow getRow(int index) {
    final user = users[index];
    return DataRow.byIndex(
      index: index,
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
                    ? Text(
                        user.displayName?.substring(0, 1).toUpperCase() ??
                            user.email.substring(0, 1).toUpperCase(),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.displayName ?? '未设置昵称',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Chip(
            label: Text(
              user.disabilityType != null
                  ? '残障用户'
                  : user.volunteerLevel != null
                  ? '志愿者'
                  : '普通用户',
              style: const TextStyle(fontSize: 12),
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(user.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.statusText,
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(user.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          user.verificationStatus != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getVerificationColor(
                      user.verificationStatus!,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.verificationText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getVerificationColor(user.verificationStatus!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const Text('-'),
        ),
        DataCell(Text(user.createdAt.toString().substring(0, 10))),
        DataCell(
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'view':
                  onViewDetail(user);
                  break;
                case 'ban':
                  onBan(user);
                  break;
                case 'unban':
                  onUnban(user);
                  break;
                case 'verify':
                  onVerify(user);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18),
                    SizedBox(width: 8),
                    Text('查看详情'),
                  ],
                ),
              ),
              if (user.verificationStatus == VerificationStatus.pending)
                const PopupMenuItem(
                  value: 'verify',
                  child: Row(
                    children: [
                      Icon(Icons.verified, size: 18),
                      SizedBox(width: 8),
                      Text('审核认证'),
                    ],
                  ),
                ),
              if (user.status == UserStatus.active)
                PopupMenuItem(
                  value: 'ban',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      const Text('封禁用户'),
                    ],
                  ),
                )
              else if (user.status == UserStatus.banned)
                const PopupMenuItem(
                  value: 'unban',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      SizedBox(width: 8),
                      Text('解封用户'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return AppTheme.successColor;
      case UserStatus.banned:
        return AppTheme.errorColor;
      case UserStatus.pending:
        return AppTheme.warningColor;
    }
  }

  Color _getVerificationColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return AppTheme.warningColor;
      case VerificationStatus.approved:
        return AppTheme.successColor;
      case VerificationStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}

class _UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserListTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.displayName?.substring(0, 1).toUpperCase() ??
                      user.email.substring(0, 1).toUpperCase(),
                )
              : null,
        ),
        title: Text(user.displayName ?? '未设置昵称'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(user.status),
                const SizedBox(width: 8),
                if (user.verificationStatus != null)
                  _buildVerificationChip(user.verificationStatus!),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusChip(UserStatus status) {
    Color color;
    switch (status) {
      case UserStatus.active:
        color = AppTheme.successColor;
        break;
      case UserStatus.banned:
        color = AppTheme.errorColor;
        break;
      case UserStatus.pending:
        color = AppTheme.warningColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        user.statusText,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVerificationChip(VerificationStatus status) {
    Color color;
    switch (status) {
      case VerificationStatus.pending:
        color = AppTheme.warningColor;
        break;
      case VerificationStatus.approved:
        color = AppTheme.successColor;
        break;
      case VerificationStatus.rejected:
        color = AppTheme.errorColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        user.verificationText,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
