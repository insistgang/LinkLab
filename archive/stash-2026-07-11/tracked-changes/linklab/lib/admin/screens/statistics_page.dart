import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

/// 数据统计页面
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _dataService = AdminDataService();

  String _selectedPeriod = 'week';
  String _selectedReportType = 'overview';
  bool _isLoading = false;

  List<TrendDataPoint> _userGrowthData = [];
  List<TrendDataPoint> _helpRequestData = [];
  List<DistributionItem> _helpTypeDistribution = [];
  List<DistributionItem> _volunteerActivityData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final days = _selectedPeriod == 'day' ? 1 : (_selectedPeriod == 'week' ? 7 : 30);

    final userGrowth = await _dataService.getTrendData('user_growth', days);
    final helpRequests = await _dataService.getTrendData('help_requests', days);
    final helpTypeDist = await _dataService.getDistributionData('help_type');
    final disabilityDist = await _dataService.getDistributionData('disability_type');

    setState(() {
      _userGrowthData = userGrowth;
      _helpRequestData = helpRequests;
      _helpTypeDistribution = helpTypeDist;
      _volunteerActivityData = disabilityDist;
      _isLoading = false;
    });
  }

  Future<void> _exportReport(String format) async {
    // 模拟导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在导出$format格式报表...')),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$format报表导出成功')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和工具栏
          Row(
            children: [
              const Text(
                '数据统计报表',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 报表类型选择
              DropdownButton<String>(
                value: _selectedReportType,
                items: const [
                  DropdownMenuItem(value: 'overview', child: Text('综合概览')),
                  DropdownMenuItem(value: 'users', child: Text('用户分析')),
                  DropdownMenuItem(value: 'help', child: Text('求助分析')),
                  DropdownMenuItem(value: 'volunteer', child: Text('志愿者分析')),
                ],
                onChanged: (value) {
                  setState(() => _selectedReportType = value!);
                  _loadData();
                },
              ),
              const SizedBox(width: 12),
              // 时间周期选择
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'day', label: Text('日')),
                  ButtonSegment(value: 'week', label: Text('周')),
                  ButtonSegment(value: 'month', label: Text('月')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (value) {
                  setState(() => _selectedPeriod = value.first);
                  _loadData();
                },
              ),
              const SizedBox(width: 12),
              // 导出按钮
              PopupMenuButton<String>(
                icon: const Icon(Icons.download),
                tooltip: '导出报表',
                onSelected: _exportReport,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, size: 18),
                        SizedBox(width: 8),
                        Text('导出 Excel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'PDF',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 18),
                        SizedBox(width: 8),
                        Text('导出 PDF'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 报表内容
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'users':
        return _buildUserReport();
      case 'help':
        return _buildHelpReport();
      case 'volunteer':
        return _buildVolunteerReport();
      default:
        return _buildOverviewReport();
    }
  }

  Widget _buildOverviewReport() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 关键指标卡片
          _buildOverviewCards(),
          const SizedBox(height: 24),

          // 图表行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBarChart(
                  '用户增长趋势',
                  _userGrowthData,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildBarChart(
                  '求助请求趋势',
                  _helpRequestData,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 分布图行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDistributionChart(
                  '求助类型分布',
                  _helpTypeDistribution,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDistributionChart(
                  '残障类型分布',
                  _volunteerActivityData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserReport() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBarChart(
                  '新用户注册趋势',
                  _userGrowthData,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDistributionChart(
                  '用户角色分布',
                  _volunteerActivityData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDataTable(
            '用户增长明细',
            ['日期', '新注册用户', '活跃用户', '留存率'],
            _generateUserTableData(),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpReport() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBarChart(
                  '求助请求趋势',
                  _helpRequestData,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDistributionChart(
                  '求助类型分布',
                  _helpTypeDistribution,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDataTable(
            '求助处理明细',
            ['日期', '总求助数', 'AI解决', '人工解决', '平均响应时间'],
            _generateHelpTableData(),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerReport() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBarChart(
                  '志愿者活跃度',
                  _userGrowthData,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDistributionChart(
                  '志愿者等级分布',
                  _helpTypeDistribution,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDataTable(
            '志愿者绩效排行',
            ['排名', '志愿者', '帮助次数', '满意度', '响应时间'],
            _generateVolunteerTableData(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final cards = [
      _buildOverviewCard('总用户数', '1,234', '+56', Colors.blue, Icons.people),
      _buildOverviewCard('活跃用户', '856', '+12%', Colors.green, Icons.trending_up),
      _buildOverviewCard('求助总数', '3,456', '+89', Colors.orange, Icons.support_agent),
      _buildOverviewCard('志愿者数', '567', '+23', Colors.purple, Icons.volunteer_activism),
    ];

    return Row(
      children: cards.map((card) => Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: card,
      ))).toList(),
    );
  }

  Widget _buildOverviewCard(String title, String value, String change, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(String title, List<TrendDataPoint> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.isEmpty
                    ? 100
                    : data.map((d) => d.value).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.grey[800]!,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(0),
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final date = data[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        color: color,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(String title, List<DistributionItem> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: data.map((item) {
                  return PieChartSectionData(
                    value: item.value.toDouble(),
                    title: '${item.value}',
                    color: Color(item.colorValue),
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: data.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(item.colorValue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(String title, List<String> headers, List<List<String>> rows) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
              rows: rows.map((row) {
                return DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<List<String>> _generateUserTableData() {
    return _userGrowthData.map((d) => [
      '${d.date.month}/${d.date.day}',
      d.value.toString(),
      (d.secondaryValue ?? 0).toString(),
      '${(75 + (d.value % 20)).toStringAsFixed(1)}%',
    ]).toList();
  }

  List<List<String>> _generateHelpTableData() {
    return _helpRequestData.map((d) => [
      '${d.date.month}/${d.date.day}',
      d.value.toString(),
      (d.value ~/ 3).toString(),
      (d.value * 2 ~/ 3).toString(),
      '${(30 + (d.value % 60))}秒',
    ]).toList();
  }

  List<List<String>> _generateVolunteerTableData() {
    return [
      ['1', '志愿者A', '156', '4.9', '15秒'],
      ['2', '志愿者B', '142', '4.8', '18秒'],
      ['3', '志愿者C', '128', '4.9', '20秒'],
      ['4', '志愿者D', '115', '4.7', '22秒'],
      ['5', '志愿者E', '98', '4.8', '25秒'],
    ];
  }
}
