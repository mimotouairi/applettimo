import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'posts': 0,
    'followers': 0,
    'following': 0,
    'likes': 0,
    'comments': 0,
    'saved': 0,
    'engagementRate': '0.0',
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      final userId = authProvider.user!['id'].toString();
      final result = await postProvider.getUserStats(userId);

      if (mounted && result['success']) {
        setState(() {
          _stats = result['data'];
          // Calculate engagement rate if not provided by backend
          double totalInteractions = (double.tryParse(_stats['likes'].toString()) ?? 0) +
                                     (double.tryParse(_stats['comments'].toString()) ?? 0);
          int totalPosts = int.tryParse(_stats['posts'].toString()) ?? 0;
          _stats['engagementRate'] = totalPosts > 0 ? (totalInteractions / totalPosts).toStringAsFixed(1) : '0.0';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getLevel(int score) {
    if (score >= 1000) return {'level': 'الأسطورة', 'icon': Icons.emoji_events, 'color': Colors.amber, 'progress': 1.0};
    if (score >= 500) return {'level': 'المحترف', 'icon': Icons.star, 'color': Colors.grey, 'progress': 0.75};
    if (score >= 100) return {'level': 'المتقدم', 'icon': Icons.local_fire_department, 'color': Colors.orange, 'progress': 0.5};
    if (score >= 50) return {'level': 'النشط', 'icon': Icons.rocket_launch, 'color': Colors.green, 'progress': 0.25};
    return {'level': 'المبتدئ', 'icon': Icons.eco, 'color': Colors.blue, 'progress': 0.1};
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    
    int score = (int.tryParse(_stats['likes'].toString()) ?? 0) + 
                (int.tryParse(_stats['comments'].toString()) ?? 0) + 
                (int.tryParse(_stats['posts'].toString()) ?? 0) * 10;
    final levelInfo = _getLevel(score);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('إحصائياتي', style: TextStyle(color: colors.text, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Level Card
                _buildLevelCard(levelInfo, colors),
                const SizedBox(height: 16),
                
                // Stats Grid
                _buildStatsGrid(colors),
                const SizedBox(height: 16),
                
                // Engagement Card
                _buildEngagementCard(colors),
                const SizedBox(height: 16),
                
                // Activity Chart
                _buildActivityChart(colors),
                const SizedBox(height: 16),
                
                // Distribution Chart
                _buildDistributionChart(colors),
                const SizedBox(height: 24),
                
                // Tips
                _buildTipsSection(colors),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> levelInfo, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: levelInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: levelInfo['color'].withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: levelInfo['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(levelInfo['icon'] as IconData, size: 36, color: levelInfo['color']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مستواك الحالي', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(levelInfo['level'], style: TextStyle(color: levelInfo['color'], fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: levelInfo['progress'] as double,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(levelInfo['color'] as Color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${(levelInfo['progress'] * 100).toInt()}% إلى المستوى التالي',
              style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatGridItem('منشورات', _stats['posts'].toString(), Icons.insert_drive_file_outlined, colors.primary, colors),
          _buildStatGridItem('إعجابات', _stats['likes'].toString(), Icons.favorite_border, Colors.red, colors),
          _buildStatGridItem('تعليقات', _stats['comments'].toString(), Icons.chat_bubble_outline, Colors.orange, colors),
        ],
      ),
    );
  }

  Widget _buildStatGridItem(String label, String value, IconData icon, Color color, dynamic colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEngagementCard(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('معدل التفاعل', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${_stats['engagementRate']}%', style: TextStyle(color: colors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (double.tryParse(_stats['engagementRate'].toString()) ?? 0) / 100,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('النشاط الأسبوعي', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 3),
                      FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.primary.withValues(alpha: 0.1),
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

  Widget _buildDistributionChart(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 250,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('توزيع المحتوى', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: colors.primary,
                    value: 40,
                    title: 'صور',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: colors.accent,
                    value: 30,
                    title: 'فيديو',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: 30,
                    title: 'نصوص',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary.withValues(alpha: 0.1), colors.secondary.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: colors.primary),
              const SizedBox(width: 8),
              Text('نصائح لزيادة التفاعل', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('انشر في أوقات الذروة (8-10 مساءً)', colors),
          _buildTipItem('أضف صوراً وفيديوهات جذابة', colors),
          _buildTipItem('تفاعل مع تعليقات متابعيك', colors),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
