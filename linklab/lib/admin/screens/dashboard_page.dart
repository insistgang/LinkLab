import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

/// 數據看板頁面
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _dataService = AdminDataService();
  DashboardStats? _stats;
  List<TrendDataPoint> _trendData = [];
  List<DistributionItem> _helpTypeDistribution = [];
  List<DistributionItem> _userTypeDistribution = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataService.initializeDemoData();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _dataService.getDashboardStats();
    final trendData = await _dataService.getTrendData('dau', 14);
    final helpTypeDist = await _dataService.getDistributionData('help_type');
    final userTypeDist = await _dataService.getDistributionData('user_type');

    setState(() {
      _stats = stats;
      _trendData = trendData;
      _helpTypeDistribution = helpTypeDist;
      _userTypeDistribution = userTypeDist;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 關鍵指標卡片
          _buildStatsCards(),
          const SizedBox(height: 24),

          // 圖表區域
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 趨勢圖
              Expanded(
                flex: 2,
                child: _buildTrendChart(),
              ),
              const SizedBox(width: 24),
              // 分佈圖
              Expanded(
                child: _buildDistributionCharts(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 待處理事項
          _buildPendingTasks(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final cards = [
      _StatCardData(
        title: '總用戶數',
        value: _stats?.totalUsers.toString() ?? '0',
        subtitle: '今日新增: ${_stats?.newUsersToday ?? 0}',
        icon: Icons.people,
        color: Colors.blue,
        trend: '+${_stats?.mauGrowthRate != null ? (_stats!.mauGrowthRate * 100).toStringAsFixed(1) : 0}%',
      ),
      _StatCardData(
        title: '日活躍用戶 (DAU)',
        value: _stats?.dau.toString() ?? '0',
        subtitle: '月活躍用戶: ${_stats?.mau ?? 0}',
        icon: Icons.trending_up,
        color: Colors.green,
        trend: '+${_stats?.dauGrowthRate != null ? (_stats!.dauGrowthRate * 100).toStringAsFixed(1) : 0}%',
      ),
      _StatCardData(
        title: '求助響應率',
        value: '${((_stats?.responseRate ?? 0) * 100).toStringAsFixed(1)}%',
        subtitle: '今日求助: ${_stats?.helpRequestsToday ?? 0}',
        icon: Icons.support_agent,
        color: Colors.orange,
      ),
      _StatCardData(
        title: 'AI解決率',
        value: '${((_stats?.aiResolutionRate ?? 0) * 100).toStringAsFixed(1)}%',
        subtitle: '平均通話: ${_stats?.avgCallDuration ?? 0}分鐘',
        icon: Icons.psychology,
        color: Colors.purple,
      ),
      _StatCardData(
        title: '用戶滿意度',
        value: '${_stats?.satisfactionRate ?? 0}',
        subtitle: '滿分5分',
        icon: Icons.star,
        color: Colors.amber,
      ),
      _StatCardData(
        title: '志願者留存率',
        value: '${((_stats?.volunteerRetentionRate ?? 0) * 100).toStringAsFixed(1)}%',
        subtitle: '上月數據',
        icon: Icons.favorite,
        color: Colors.red,
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((card) => _buildStatCard(card)).toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, color: data.color, size: 32),
              if (data.trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.trend!,
                    style: TextStyle(
                      color: data.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '活躍用戶趨勢 (14天)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildLegend('DAU', Colors.blue),
                  const SizedBox(width: 16),
                  _buildLegend('MAU', Colors.green),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
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
                            fontSize: 12,
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
                        if (index >= 0 && index < _trendData.length) {
                          final date = _trendData[index].date;
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
                lineBarsData: [
                  // DAU 線
                  LineChartBarData(
                    spots: _trendData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                  // MAU 線
                  LineChartBarData(
                    spots: _trendData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value.secondaryValue ?? 0).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildDistributionCharts() {
    return Column(
      children: [
        _buildPieChart('求助類型分佈', _helpTypeDistribution),
        const SizedBox(height: 24),
        _buildPieChart('用戶類型分佈', _userTypeDistribution),
      ],
    );
  }

  Widget _buildPieChart(String title, List<DistributionItem> data) {
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
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.map((item) {
                  return PieChartSectionData(
                    value: item.value.toDouble(),
                    title: '${item.value}',
                    color: Color(item.colorValue),
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
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
            spacing: 12,
            runSpacing: 8,
            children: data.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
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
                      fontSize: 11,
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

  Widget _buildPendingTasks() {
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
          const Text(
            '待處理事項',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTaskCard(
                '待審覈認證',
                _stats?.pendingVerifications ?? 0,
                Icons.verified_user,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildTaskCard(
                '待處理舉報',
                _stats?.pendingReports ?? 0,
                Icons.report_problem,
                Colors.red,
              ),
              const SizedBox(width: 16),
              _buildTaskCard(
                '待審覈內容',
                5,
                Icons.article,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? trend;

  _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
  });
}
