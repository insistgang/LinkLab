import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'sidebar.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AppLayout({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(title: const Text('LinkLab 運營後臺')),
        drawer: MobileDrawer(currentRoute: currentRoute),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context),
                // Content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          // Breadcrumb could go here
          const Spacer(),
          // Actions
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
    );
  }
}
