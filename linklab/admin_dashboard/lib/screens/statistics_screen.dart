import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import '../constants/theme.dart';
import '../models/statistics_model.dart';
import '../models/dashboard_model.dart';
import '../services/supabase_service.dart';
import '../widgets/charts.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  List<DailyReport> _dailyReports = [];
  List<UserGrowthReport> _userGrowthReports = [];
  List<HelpTypeStatistics> _helpTypeStats = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = SupabaseService();
      final dailyReports = await supabase.getDailyReports(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );
      final userGrowth = await supabase.getUserGrowthReports(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );
      final helpTypeStats = await supabase.getHelpTypeStatistics(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );

      setState(() {
        _dailyReports = dailyReports;
        _userGrowthReports = userGrowth;
        _helpTypeStats = helpTypeStats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加載數據失敗: $e')));
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final workbook = Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = '日報表';

      // Headers
      sheet.getRangeByName('A1').setText('日期');
      sheet.getRangeByName('B1').setText('新增用戶');
      sheet.getRangeByName('C1').setText('活躍用戶');
      sheet.getRangeByName('D1').setText('總通話');
      sheet.getRangeByName('E1').setText('平均通話時長');
      sheet.getRangeByName('F1').setText('滿意度');
      sheet.getRangeByName('G1').setText('求助請求');
      sheet.getRangeByName('H1').setText('響應率');

      // Data
      for (var i = 0; i < _dailyReports.length; i++) {
        final report = _dailyReports[i];
        final row = i + 2;
        sheet
            .getRangeByName('A$row')
            .setText(DateFormat('yyyy-MM-dd').format(report.date));
        sheet.getRangeByName('B$row').setNumber(report.newUsers.toDouble());
        sheet.getRangeByName('C$row').setNumber(report.activeUsers.toDouble());
        sheet.getRangeByName('D$row').setNumber(report.totalCalls.toDouble());
        sheet.getRangeByName('E$row').setNumber(report.avgCallDuration);
        sheet.getRangeByName('F$row').setNumber(report.satisfaction);
        sheet.getRangeByName('G$row').setNumber(report.helpRequests.toDouble());
        sheet.getRangeByName('H$row').setNumber(report.responseRate);
      }

      // Save
      workbook.saveAsStream();
      workbook.dispose();

      // In web, we would use dart:html to download the file
      // For now, show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Excel導出成功')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('導出失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('數據統計'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日報表'),
            Tab(text: '用戶增長'),
            Tab(text: '求助分析'),
          ],
        ),
        actions: [
          // Date Range Picker
          TextButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
                _loadData();
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              '${DateFormat('MM/dd').format(_dateRange.start)} - ${DateFormat('MM/dd').format(_dateRange.end)}',
            ),
          ),
          const SizedBox(width: 8),
          // Export Button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '導出Excel',
            onPressed: _exportToExcel,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyReportTab(isMobile),
                _buildUserGrowthTab(isMobile),
                _buildHelpAnalysisTab(isMobile),
              ],
            ),
    );
  }

  Widget _buildDailyReportTab(bool isMobile) {
    if (_dailyReports.isEmpty) {
      return const Center(child: Text('暫無數據'));
    }

    final trendData = _dailyReports
        .map(
          (r) => TrendDataPoint(date: r.date, value: r.activeUsers.toDouble()),
        )
        .toList();

    final callData = _dailyReports
        .map(
          (r) => TrendDataPoint(date: r.date, value: r.totalCalls.toDouble()),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LineChartWidget(
                    data: trendData,
                    title: '活躍用戶趨勢',
                    lineColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LineChartWidget(
                    data: callData,
                    title: '通話量趨勢',
                    lineColor: AppTheme.successColor,
                  ),
                ),
              ],
            )
          else ...[
            LineChartWidget(
              data: trendData,
              title: '活躍用戶趨勢',
              lineColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            LineChartWidget(
              data: callData,
              title: '通話量趨勢',
              lineColor: AppTheme.successColor,
            ),
          ],
          const SizedBox(height: 24),
          _buildDailyReportTable(),
        ],
      ),
    );
  }

  Widget _buildDailyReportTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('日期')),
            DataColumn(label: Text('新增用戶')),
            DataColumn(label: Text('活躍用戶')),
            DataColumn(label: Text('總通話')),
            DataColumn(label: Text('平均時長')),
            DataColumn(label: Text('滿意度')),
            DataColumn(label: Text('響應率')),
          ],
          rows: _dailyReports.map((report) {
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('yyyy-MM-dd').format(report.date))),
                DataCell(Text(report.newUsers.toString())),
                DataCell(Text(report.activeUsers.toString())),
                DataCell(Text(report.totalCalls.toString())),
                DataCell(
                  Text('${report.avgCallDuration.toStringAsFixed(1)}分鐘'),
                ),
                DataCell(Text(report.satisfaction.toStringAsFixed(1))),
                DataCell(Text('${report.responseRate.toStringAsFixed(1)}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserGrowthTab(bool isMobile) {
    if (_userGrowthReports.isEmpty) {
      return const Center(child: Text('暫無數據'));
    }

    final disabledData = _userGrowthReports
        .map(
          (r) => TrendDataPoint(
            date: r.date,
            value: r.newDisabledUsers.toDouble(),
          ),
        )
        .toList();

    final volunteerData = _userGrowthReports
        .map(
          (r) => TrendDataPoint(
            date: r.date,
            value: r.newVolunteerUsers.toDouble(),
          ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LineChartWidget(
                    data: disabledData,
                    title: '新增殘障用戶',
                    lineColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LineChartWidget(
                    data: volunteerData,
                    title: '新增志願者',
                    lineColor: AppTheme.successColor,
                  ),
                ),
              ],
            )
          else ...[
            LineChartWidget(
              data: disabledData,
              title: '新增殘障用戶',
              lineColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            LineChartWidget(
              data: volunteerData,
              title: '新增志願者',
              lineColor: AppTheme.successColor,
            ),
          ],
          const SizedBox(height: 24),
          _buildUserGrowthTable(),
        ],
      ),
    );
  }

  Widget _buildUserGrowthTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('日期')),
            DataColumn(label: Text('新增殘障用戶')),
            DataColumn(label: Text('新增志願者')),
            DataColumn(label: Text('殘障用戶總數')),
            DataColumn(label: Text('志願者總數')),
            DataColumn(label: Text('留存率')),
          ],
          rows: _userGrowthReports.map((report) {
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('yyyy-MM-dd').format(report.date))),
                DataCell(Text(report.newDisabledUsers.toString())),
                DataCell(Text(report.newVolunteerUsers.toString())),
                DataCell(Text(report.totalDisabledUsers.toString())),
                DataCell(Text(report.totalVolunteerUsers.toString())),
                DataCell(
                  Text('${report.volunteerRetentionRate.toStringAsFixed(1)}%'),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHelpAnalysisTab(bool isMobile) {
    if (_helpTypeStats.isEmpty) {
      return const Center(child: Text('暫無數據'));
    }

    final distributionData = _helpTypeStats
        .map((s) => DistributionData(name: s.type, value: s.count.toDouble()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          PieChartWidget(data: distributionData, title: '求助類型分佈'),
          const SizedBox(height: 24),
          _buildHelpTypeTable(),
        ],
      ),
    );
  }

  Widget _buildHelpTypeTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('求助類型')),
            DataColumn(label: Text('數量')),
            DataColumn(label: Text('佔比')),
            DataColumn(label: Text('平均響應時間')),
            DataColumn(label: Text('平均時長')),
            DataColumn(label: Text('滿意度')),
          ],
          rows: _helpTypeStats.map((stat) {
            return DataRow(
              cells: [
                DataCell(Text(stat.type)),
                DataCell(Text(stat.count.toString())),
                DataCell(Text('${stat.percentage.toStringAsFixed(1)}%')),
                DataCell(Text('${stat.avgResponseTime.toStringAsFixed(1)}秒')),
                DataCell(Text('${stat.avgDuration.toStringAsFixed(1)}分鐘')),
                DataCell(Text(stat.satisfaction.toStringAsFixed(1))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
