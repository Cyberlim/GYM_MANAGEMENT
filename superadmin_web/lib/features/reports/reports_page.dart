import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../data/providers/superadmin_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedDateRange = 'Last 30 Days';

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'title': 'Financial Summary',
      'description': 'Aggregated MRR, payouts, and platform fees.',
      'icon': LucideIcons.dollarSign,
      'color': Colors.green,
    },
    {
      'title': 'Gym Growth & Signups',
      'description': 'Onboarding metrics and new gym registrations.',
      'icon': LucideIcons.trendingUp,
      'color': const Color(0xFF3B82F6), // Blue
    },
    {
      'title': 'Subscription Plan Churn',
      'description': 'Downgrades, cancellations, and upgrade statistics.',
      'icon': LucideIcons.pieChart,
      'color': Colors.orange,
    },
    {
      'title': 'Payouts & Settlements',
      'description': 'Detailed breakdown of payouts sent to gym owners.',
      'icon': LucideIcons.wallet,
      'color': const Color(0xFF4338CA), // Indigo
    }
  ];

  List<Map<String, dynamic>> _recentReports = [];

  Future<void> generateAndDownloadCsv(String title) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Generating $title CSV...'),
      backgroundColor: AppTheme.primaryColor,
      duration: const Duration(seconds: 1),
    ));

    try {
      final data = await SuperadminActions.fetchReportData(title, _selectedDateRange);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No data found for $title in $_selectedDateRange'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // Convert json array to CSV
      final keys = (data.first as Map<String, dynamic>).keys.toList();
      final StringBuffer csv = StringBuffer();
      csv.writeln(keys.join(','));
      for (final row in data) {
        final Map<String, dynamic> rowData = row;
        csv.writeln(keys.map((k) => '"${rowData[k]?.toString().replaceAll('"', '""') ?? ''}"').join(','));
      }

      final bytes = utf8.encode(csv.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final filename = '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      // Add to recent reports
      setState(() {
        _recentReports.insert(0, {
          'name': '$title - $_selectedDateRange',
          'type': title.split(' ').first,
          'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
          'size': '${(bytes.length / 1024).toStringAsFixed(1)} KB',
        });
        if (_recentReports.length > 10) {
          _recentReports.removeLast();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Downloaded $title successfully'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error generating report: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('Generate and download platform data reports.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Generate Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDateRange,
                          icon: const Icon(LucideIcons.chevronDown, size: 16),
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDateRange = val);
                          },
                          items: ['Last 7 Days', 'Last 30 Days', 'This Month', 'Last Month', 'This Year']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: _reportTypes.length,
                  itemBuilder: (context, index) {
                    final report = _reportTypes[index];
                    return _buildReportCard(
                      report['title'],
                      report['description'],
                      report['icon'],
                      report['color'],
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                Text('Recent Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 24),
                
                _recentReports.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('No reports generated yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        ),
                      )
                    : DataTableWidget(
                        columns: const ['Report Name', 'Type', 'Date Generated', 'File Size', 'Actions'],
                        rows: _recentReports.map((report) {
                          Color typeColor;
                          switch (report['type']) {
                            case 'Financial': typeColor = Colors.green; break;
                            case 'Gym': typeColor = const Color(0xFF3B82F6); break; // Blue
                            case 'Subscription': typeColor = Colors.orange; break;
                            case 'Payouts': typeColor = const Color(0xFF4338CA); break; // Indigo
                            default: typeColor = Colors.grey; break;
                          }
                          return [
                            Text(report['name'], style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(report['type'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: typeColor)),
                            ),
                            Text(report['date'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                            Text(report['size'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(LucideIcons.download, size: 16),
                              label: const Text('Downloaded'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ];
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, Color color) {
    return HoverCard(
      child: Container(
        padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => generateAndDownloadCsv(title),
            icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
            label: const Text('Generate CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: Theme.of(context).brightness == Brightness.dark ? 8 : 2,
              shadowColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.primaryColor.withValues(alpha: 0.6) : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  final Widget child;
  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
