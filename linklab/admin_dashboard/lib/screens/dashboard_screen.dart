import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../bloc/dashboard_bloc.dart';
import '../constants/theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/charts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(DashboardLoadRequested()),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('數據看板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(DashboardRefreshRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return _buildSkeleton(isMobile);
          }

          if (state is DashboardLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metrics Grid
                  _buildMetricsGrid(state, isMobile),
                  const SizedBox(height: 24),
                  // Charts
                  _buildChartsSection(state, isMobile),
                ],
              ),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DashboardBloc>().add(
                        DashboardLoadRequested(),
                      );
                    },
                    child: const Text('重試'),
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

  Widget _buildMetricsGrid(DashboardLoaded state, bool isMobile) {
    final metrics = state.metrics;

    final cards = [
      MetricCard(
        title: '日活躍用戶 (DAU)',
        value: metrics.dau.toString(),
        change: metrics.dauChange,
        icon: Icons.people_outline,
        color: AppTheme.primaryColor,
      ),
      MetricCard(
        title: '月活躍用戶 (MAU)',
        value: metrics.mau.toString(),
        change: metrics.mauChange,
        icon: Icons.groups_outlined,
        color: AppTheme.infoColor,
      ),
      MetricCard(
        title: '求助響應率',
        value: '${metrics.responseRate.toStringAsFixed(1)}%',
        change: metrics.responseRateChange,
        icon: Icons.speed_outlined,
        color: AppTheme.successColor,
      ),
      MetricCard(
        title: '志願者留存率',
        value: '${metrics.volunteerRetention.toStringAsFixed(1)}%',
        change: metrics.volunteerRetentionChange,
        icon: Icons.favorite_outline,
        color: AppTheme.warningColor,
      ),
      MetricCard(
        title: 'AI解決率',
        value: '${metrics.aiResolutionRate.toStringAsFixed(1)}%',
        change: metrics.aiResolutionRateChange,
        icon: Icons.smart_toy_outlined,
        color: AppTheme.primaryDark,
      ),
      MetricCard(
        title: '平均通話時長',
        value: '${metrics.avgCallDuration.toStringAsFixed(1)}分鐘',
        change: metrics.avgCallDurationChange,
        icon: Icons.timer_outlined,
        color: AppTheme.infoColor,
      ),
      MetricCard(
        title: '用戶滿意度',
        value: metrics.satisfaction.toStringAsFixed(1),
        change: metrics.satisfactionChange,
        subtitle: '滿分5分',
        icon: Icons.star_outline,
        color: AppTheme.warningColor,
      ),
      MetricCard(
        title: '總通話數',
        value: metrics.totalCalls.toString(),
        change: metrics.totalCallsChange.toDouble(),
        icon: Icons.call_outlined,
        color: AppTheme.successColor,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildChartsSection(DashboardLoaded state, bool isMobile) {
    final trendData = state.trendData;
    final distribution = state.distribution;

    if (isMobile) {
      return Column(
        children: [
          if (trendData != null) ...[
            LineChartWidget(
              data: trendData.dau,
              title: 'DAU趨勢（最近7天）',
              lineColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            LineChartWidget(
              data: trendData.calls,
              title: '通話量趨勢（最近7天）',
              lineColor: AppTheme.successColor,
            ),
          ],
          if (distribution != null) ...[
            const SizedBox(height: 16),
            PieChartWidget(data: distribution.userType, title: '用戶類型分佈'),
            const SizedBox(height: 16),
            PieChartWidget(data: distribution.disabilityType, title: '殘障類型分佈'),
          ],
        ],
      );
    }

    return Column(
      children: [
        if (trendData != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LineChartWidget(
                  data: trendData.dau,
                  title: 'DAU趨勢（最近7天）',
                  lineColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LineChartWidget(
                  data: trendData.calls,
                  title: '通話量趨勢（最近7天）',
                  lineColor: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
        if (distribution != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PieChartWidget(
                  data: distribution.userType,
                  title: '用戶類型分佈',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PieChartWidget(
                  data: distribution.disabilityType,
                  title: '殘障類型分佈',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PieChartWidget(
                  data: distribution.skillDistribution,
                  title: '志願者技能分佈',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSkeleton(bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: List.generate(
            8,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: MetricCardSkeleton(),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => const MetricCardSkeleton(),
      ),
    );
  }
}
