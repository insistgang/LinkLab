import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../bloc/report_bloc.dart';
import '../constants/app_constants.dart';
import '../constants/theme.dart';
import '../models/report_model.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportBloc()
        ..add(const ReportLoadRequested())
        ..add(ReportLoadStatistics()),
      child: const _ReportsContent(),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('举报处理'),
        actions: [
          // Filter
          PopupMenuButton<ReportStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选状态',
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              ...ReportStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(_getStatusText(status)),
                ),
              ),
            ],
            onSelected: (value) {
              context.read<ReportBloc>().add(
                ReportFilterChanged(status: value),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is ReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Statistics Cards
              if (state is ReportLoaded && state.statistics != null)
                _buildStatisticsCards(state.statistics!, isMobile),

              // Reports List
              Expanded(child: _buildReportsList(context, state, isMobile)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards(ReportStatistics stats, bool isMobile) {
    final cards = [
      _StatCard(
        title: '待处理',
        value: stats.pendingReports.toString(),
        color: AppTheme.warningColor,
        icon: Icons.pending_actions,
      ),
      _StatCard(
        title: '处理中',
        value: stats.processingReports.toString(),
        color: AppTheme.infoColor,
        icon: Icons.sync,
      ),
      _StatCard(
        title: '已解决',
        value: stats.resolvedReports.toString(),
        color: AppTheme.successColor,
        icon: Icons.check_circle,
      ),
      _StatCard(
        title: '平均处理时间',
        value: '${stats.avgProcessTime.toStringAsFixed(1)}h',
        color: AppTheme.primaryColor,
        icon: Icons.timer,
      ),
    ];

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: card,
                ),
              )
              .toList(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: card,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildReportsList(
    BuildContext context,
    ReportState state,
    bool isMobile,
  ) {
    if (state is ReportLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ReportLoaded) {
      if (state.reports.isEmpty) {
        return const Center(child: Text('暂无举报数据'));
      }

      if (isMobile) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.reports.length,
          itemBuilder: (context, index) {
            return _ReportCard(
              report: state.reports[index],
              onProcess: () =>
                  _showProcessDialog(context, state.reports[index]),
            );
          },
        );
      }

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: PaginatedDataTable2(
            header: Text('共 ${state.reports.length} 条举报'),
            columns: const [
              DataColumn2(label: Text('举报类型'), size: ColumnSize.S),
              DataColumn2(label: Text('举报内容'), size: ColumnSize.L),
              DataColumn2(label: Text('被举报对象'), size: ColumnSize.M),
              DataColumn2(label: Text('状态'), size: ColumnSize.S),
              DataColumn2(label: Text('举报时间'), size: ColumnSize.M),
              DataColumn2(label: Text('操作'), size: ColumnSize.S),
            ],
            source: _ReportDataSource(
              reports: state.reports,
              onProcess: (report) => _showProcessDialog(context, report),
            ),
            rowsPerPage: 20,
            showFirstLastButtons: true,
            showCheckboxColumn: false,
          ),
        ),
      );
    }

    if (state is ReportError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ReportBloc>()
                  ..add(const ReportLoadRequested())
                  ..add(ReportLoadStatistics());
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  void _showProcessDialog(BuildContext parentContext, ReportModel report) {
    final resultController = TextEditingController();
    String? selectedAction;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('处理举报'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Info
                _buildInfoRow('举报类型', report.typeText),
                _buildInfoRow('举报原因', report.reason),
                if (report.description != null)
                  _buildInfoRow('详细描述', report.description!),
                _buildInfoRow(
                  '被举报对象',
                  '${report.targetTypeText}: ${report.targetUserName ?? '未知'}',
                ),
                if (report.targetContent != null)
                  _buildInfoRow('举报内容', report.targetContent!),
                const Divider(height: 32),
                // Action Selection
                const Text(
                  '处理操作：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setState) => RadioGroup<String>(
                    groupValue: selectedAction,
                    onChanged: (value) =>
                        setState(() => selectedAction = value),
                    child: const Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('警告用户'),
                          value: 'warn',
                        ),
                        RadioListTile<String>(
                          title: Text('封禁用户'),
                          value: 'ban',
                        ),
                        RadioListTile<String>(
                          title: Text('删除内容'),
                          value: 'delete',
                        ),
                        RadioListTile<String>(
                          title: Text('驳回举报'),
                          value: 'dismiss',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Result Input
                TextField(
                  controller: resultController,
                  decoration: const InputDecoration(
                    labelText: '处理结果说明',
                    hintText: '请输入处理结果说明',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: selectedAction == null
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    final status = selectedAction == 'dismiss'
                        ? ReportStatus.dismissed
                        : ReportStatus.resolved;
                    parentContext.read<ReportBloc>().add(
                      ReportProcessRequested(
                        reportId: report.id,
                        status: status,
                        result: resultController.text,
                        action: selectedAction,
                      ),
                    );
                  },
            child: const Text('确认处理'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return '待处理';
      case ReportStatus.processing:
        return '处理中';
      case ReportStatus.resolved:
        return '已解决';
      case ReportStatus.dismissed:
        return '已驳回';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onProcess;

  const _ReportCard({required this.report, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeChip(report.type),
                const SizedBox(width: 8),
                _buildStatusChip(report.status),
                const Spacer(),
                Text(
                  report.createdAt.toString().substring(0, 16),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '举报原因: ${report.reason}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (report.description != null) ...[
              const SizedBox(height: 4),
              Text(
                report.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '被举报对象: ${report.targetTypeText} - ${report.targetUserName ?? '未知'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (report.targetContent != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.targetContent!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (report.status == ReportStatus.pending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onProcess,
                  child: const Text('处理举报'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(ReportType type) {
    Color color;
    switch (type) {
      case ReportType.spam:
        color = Colors.grey;
        break;
      case ReportType.harassment:
        color = AppTheme.errorColor;
        break;
      case ReportType.inappropriate:
        color = AppTheme.warningColor;
        break;
      case ReportType.fraud:
        color = AppTheme.errorColor;
        break;
      case ReportType.other:
        color = AppTheme.infoColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        report.typeText,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = AppTheme.warningColor;
        break;
      case ReportStatus.processing:
        color = AppTheme.infoColor;
        break;
      case ReportStatus.resolved:
        color = AppTheme.successColor;
        break;
      case ReportStatus.dismissed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        report.statusText,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ReportDataSource extends DataTableSource {
  final List<ReportModel> reports;
  final Function(ReportModel) onProcess;

  _ReportDataSource({required this.reports, required this.onProcess});

  @override
  DataRow getRow(int index) {
    final report = reports[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(report.typeText)),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                report.reason,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (report.targetContent != null)
                Text(
                  report.targetContent!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        DataCell(Text(report.targetUserName ?? '未知')),
        DataCell(_buildStatusChip(report.status)),
        DataCell(Text(report.createdAt.toString().substring(0, 16))),
        DataCell(
          report.status == ReportStatus.pending
              ? TextButton(
                  onPressed: () => onProcess(report),
                  child: const Text('处理'),
                )
              : const Text('已处理'),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = AppTheme.warningColor;
        break;
      case ReportStatus.processing:
        color = AppTheme.infoColor;
        break;
      case ReportStatus.resolved:
        color = AppTheme.successColor;
        break;
      case ReportStatus.dismissed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => reports.length;

  @override
  int get selectedRowCount => 0;
}
