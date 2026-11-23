import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'monthly_report_screen.dart';

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.mealRate,
    required this.meals,
    required this.bazar,
    required this.deposit,
    required this.due,
    required this.credit,
    required this.overdue,
  });

  final String month;
  final String mealRate;
  final String meals;
  final String bazar;
  final String deposit;
  final String due;
  final int credit;
  final int overdue;
}

/// "Past Reports" – opened from "View complete monthly report" on the dashboard.
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  static const _reports = [
    MonthlyReport(
      month: 'July 2026',
      mealRate: '52.47',
      meals: '187.5',
      bazar: '৳9.8k',
      deposit: '৳26.3k',
      due: '৳6,089',
      credit: 4,
      overdue: 3,
    ),
    MonthlyReport(
      month: 'June 2026',
      mealRate: '49.34',
      meals: '181',
      bazar: '৳8.9k',
      deposit: '৳32.4k',
      due: '৳56',
      credit: 6,
      overdue: 1,
    ),
    MonthlyReport(
      month: 'May 2026',
      mealRate: '47.95',
      meals: '171',
      bazar: '৳8.2k',
      deposit: '৳30.5k',
      due: '৳384',
      credit: 6,
      overdue: 1,
    ),
  ];

  void _openMonth(BuildContext context, MonthlyReport report) {
    final detail = reportDetailFor(report.month);
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${report.month}: report data not available yet')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MonthlyReportScreen(report: detail)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildMessLifeTheme(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: MessLifeColors.background,
          body: Column(
            children: [
              _ArchiveHeader(monthCount: _reports.length),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(overscroll: false),
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                    children: [
                      _LiveReportCard(
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MonthlyReportScreen(
                              report: sampleNovember2026,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                        child: Text(
                          'মাসওয়ারি রিপোর্ট',
                          style: TextStyle(
                            color: MessLifeColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (final report in _reports) ...[
                        MonthlyReportCard(
                          report: report,
                          onTap: () => _openMonth(context, report),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              DashboardBottomNavigation(
                selectedIndex: 0,
                onSelected: (index) {
                  if (index == 0) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveHeader extends StatelessWidget {
  const _ArchiveHeader({required this.monthCount});

  final int monthCount;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: MessLifeColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      clipBehavior: Clip.antiAlias,
      child: RingsOverlay(
        alignment: const Alignment(0.95, 0.1),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top + 16, 16, 20),
          child: Row(
            children: [
              Material(
                color: const Color(0x1FFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(color: Color(0x24FFFFFF)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARCHIVE',
                      style: TextStyle(
                        color: Color(0x8CFFFFFF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Past Reports',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: Text(
                  '$monthCount months',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Link back to the current month's live report (the dashboard).
class _LiveReportCard extends StatelessWidget {
  const _LiveReportCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MessLifeColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: MessLifeColors.mintTint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: MessLifeColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'November 2026',
                        style: TextStyle(
                          color: MessLifeColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Current month · still open',
                        style: TextStyle(
                          color: MessLifeColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: onOpen,
            child: const SizedBox(
              width: double.infinity,
              height: 40,
              child: Center(
                child: Text(
                  'Open live report ›',
                  style: TextStyle(
                    color: MessLifeColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyReportCard extends StatelessWidget {
  const MonthlyReportCard({
    required this.report,
    required this.onTap,
    super.key,
  });

  final MonthlyReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _card(),
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MessLifeColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x17073847),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: MessLifeColors.headerGradient,
            ),
            child: RingsOverlay(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x24FFFFFF)),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 21,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.month,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Meal rate ৳${report.mealRate} · ${report.meals} meals',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _ClosedPill(),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _ReportMetric(
                label: 'Bazar',
                value: report.bazar,
                color: MessLifeColors.success,
              ),
              const _MetricDivider(),
              _ReportMetric(
                label: 'Deposit',
                value: report.deposit,
                color: MessLifeColors.success,
              ),
              const _MetricDivider(),
              _ReportMetric(
                label: 'বকেয়া',
                value: report.due,
                color: MessLifeColors.danger,
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                const _InitialChips(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${report.credit} credit · ${report.overdue} overdue',
                    style: const TextStyle(
                      color: MessLifeColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: MessLifeColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedPill extends StatelessWidget {
  const _ClosedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x3311CE7E),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x4D9FE6C5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 12, color: MessLifeColors.mint),
          SizedBox(width: 4),
          Text(
            'Closed',
            style: TextStyle(
              color: MessLifeColors.mint,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: MessLifeColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 46,
      child: ColoredBox(color: MessLifeColors.border),
    );
  }
}

/// Overlapping initials of the first members (A R S S S).
class _InitialChips extends StatelessWidget {
  const _InitialChips();

  static const _letters = ['A', 'R', 'S', 'S', 'S'];
  static const _background = [
    Color(0xFFE4EFEA),
    Color(0xFFD7EEF6),
    Color(0xFFECDFF6),
    Color(0xFFFFE4D6),
    Color(0xFFDDEFE2),
  ];
  static const _foreground = [
    Color(0xFF2E4A44),
    Color(0xFF16708C),
    Color(0xFF7B3FA8),
    Color(0xFFD9622B),
    Color(0xFF1E8E5A),
  ];

  static const double _size = 24;
  static const double _step = 17;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size + _step * (_letters.length - 1),
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < _letters.length; i++)
            Positioned(
              left: i * _step,
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _background[i],
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: _foreground[i].withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _letters[i],
                  style: TextStyle(
                    color: _foreground[i],
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}