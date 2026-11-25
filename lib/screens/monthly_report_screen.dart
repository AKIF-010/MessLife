// File: lib/screens/monthly_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dashboard_screen.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class ReportMember {
  const ReportMember({
    required this.fullName,
    required this.meals,
    required this.paid,
    this.isYou = false,
  });

  final String fullName;
  final double meals;
  final int paid;
  final bool isYou;

  String get shortName => fullName.trim().split(' ').first;
}

class MonthReportData {
  const MonthReportData({
    required this.year,
    required this.month,
    required this.bazar,
    required this.totalMeals,
    required this.mealRate,
    required this.isLive,
    required this.members,
  });

  final int year;
  final int month; // 1..12
  final int bazar;
  final double totalMeals;
  final double mealRate;
  final bool isLive; // true = current month, false = closed
  final List<ReportMember> members;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  String get title => '${_months[month - 1]} $year';

  int costOf(ReportMember m) => (m.meals * mealRate).round();
  int balanceOf(ReportMember m) => m.paid - costOf(m);

  int get totalDeposit => members.fold(0, (s, m) => s + m.paid);
  int get extraCredit =>
      members.fold(0, (s, m) => s + (balanceOf(m) > 0 ? balanceOf(m) : 0));
  int get overdue =>
      members.fold(0, (s, m) => s + (balanceOf(m) < 0 ? -balanceOf(m) : 0));
  int get netBalance => extraCredit - overdue;

  List<ReportMember> get overdueMembers =>
      members.where((m) => balanceOf(m) < 0).toList();
  List<ReportMember> get creditMembers =>
      members.where((m) => balanceOf(m) > 0).toList();
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

const _taka = '৳';

String _commas(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _money(int n) => '${n < 0 ? '-' : ''}$_taka${_commas(n)}';
String _signed(int n) => '${n < 0 ? '-' : '+'}$_taka${_commas(n)}';
String _plain(int n) => '$_taka${n.abs()}';
String _signedPlain(int n) => '${n < 0 ? '-' : '+'}$_taka${n.abs()}';
String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

// ---------------------------------------------------------------------------
// Colors (local, so this file does not depend on extra AppColors fields)
// ---------------------------------------------------------------------------

const _tealDark = MessLifeColors.navy;
const _tealMid = MessLifeColors.navySecondary;
const _green = MessLifeColors.primary;
const _greenBg = Color(0xFFE3F3EA);
const _greenSoft = Color(0xFFEAF6F0);
const _red = MessLifeColors.danger;
const _redBg = Color(0xFFFDE4E4);
const _redBorder = Color(0xFFF3B5B8);
const _orange = Color(0xFFD9830F);
const _labelMuted = Color(0xFF8AA7A4);
const _line = MessLifeColors.border;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key, required this.report});
  final MonthReportData report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MessLifeColors.background,
      body: Column(
        children: [
          _Header(report: report),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        _OverviewCard(report: report),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: 'EXTRA CREDIT',
                                value: '+$_taka${_commas(report.extraCredit)}',
                                sub: '${report.creditMembers.length} members',
                                icon: Icons.trending_up_rounded,
                                fg: _green,
                                bg: _greenBg,
                                border: const Color(0xFFBFE3CF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryTile(
                                label: 'OVERDUE',
                                value: '$_taka${_commas(report.overdue)}',
                                sub: '${report.overdueMembers.length} members',
                                icon: Icons.error_outline_rounded,
                                fg: _red,
                                bg: _redBg,
                                border: _redBorder,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MemberStatsCard(report: report),
                        const SizedBox(height: 16),
                        _ActionButtons(report: report),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          DashboardBottomNavigation(
            selectedIndex: 0,
            onSelected: (i) {
              if (i == 0) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.report});
  final MonthReportData report;

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 16,
            16,
            20,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MONTHLY REPORT',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: MessLifeColors.mint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(live: report.isLive),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF9CE6C2).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF9CE6C2).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            live ? Icons.trending_up_rounded : Icons.lock_outline_rounded,
            size: 14,
            color: const Color(0xFF9CE6C2),
          ),
          const SizedBox(width: 5),
          Text(
            live ? 'Live' : 'Closed',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CE6C2),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview card
// ---------------------------------------------------------------------------

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.report});
  final MonthReportData report;

  @override
  Widget build(BuildContext context) {
    final negative = report.netBalance < 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: _tealDark,
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REPORT OVERVIEW',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: _labelMuted,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Monthly snapshot',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 20, color: MessLifeColors.mint),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Stat(
                  value: _money(report.bazar),
                  label: 'BAZAR',
                  color: _green,
                ),
                const VerticalDivider(width: 1, color: _line),
                _Stat(
                  value: _num(report.totalMeals),
                  label: 'MEALS',
                  color: MessLifeColors.textPrimary,
                ),
                const VerticalDivider(width: 1, color: _line),
                _Stat(
                  value: '$_taka${report.mealRate.toStringAsFixed(2)}',
                  label: 'MEAL RATE',
                  color: _orange,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BigStat(
                    label: 'TOTAL DEPOSIT',
                    value: _money(report.totalDeposit),
                    color: _green,
                    bg: _greenSoft,
                    labelColor: _green,
                  ),
                ),
                const VerticalDivider(width: 1, color: _line),
                Expanded(
                  child: _BigStat(
                    label: 'NET BALANCE',
                    value: negative
                        ? _money(report.netBalance)
                        : _signed(report.netBalance),
                    color: negative ? _red : _green,
                    bg: negative ? _redBg : _greenSoft,
                    labelColor: negative ? _red : _green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MessLifeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.labelColor,
  });
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extra credit / overdue tiles
// ---------------------------------------------------------------------------

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.border,
  });
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: fg),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11.5, color: fg)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member stats table
// ---------------------------------------------------------------------------

const _avatarPalette = <(Color, Color)>[
  (Color(0xFFDDE6E3), Color(0xFF2F4A46)), // teal-grey
  (Color(0xFFD2F0EE), Color(0xFF127A78)), // aqua
  (Color(0xFFEBDDF7), Color(0xFF7B3FB0)), // purple
  (Color(0xFFFDE3D3), Color(0xFFD2622A)), // orange
  (Color(0xFFDDE9E1), Color(0xFF3E6B52)), // sage
  (Color(0xFFF3DDE8), Color(0xFF9B2F63)), // pink
  (Color(0xFFE4E6E8), Color(0xFF4A5560)), // grey
];

class _MemberStatsCard extends StatelessWidget {
  const _MemberStatsCard({required this.report});
  final MonthReportData report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            color: _tealDark,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: _labelMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Member Meal Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${r.members.length} members',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // column titles
          Container(
            color: const Color(0xFFEFF6F3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: const Row(
              children: [
                Expanded(flex: 50, child: _Th('NAME', TextAlign.left)),
                Expanded(flex: 20, child: _Th('MEALS', TextAlign.right)),
                Expanded(flex: 24, child: _Th('COST', TextAlign.right)),
                Expanded(flex: 24, child: _Th('PAID', TextAlign.right)),
                Expanded(flex: 30, child: _Th('BAL', TextAlign.right)),
              ],
            ),
          ),
          for (var i = 0; i < r.members.length; i++)
            _MemberRow(
              member: r.members[i],
              cost: r.costOf(r.members[i]),
              balance: r.balanceOf(r.members[i]),
              palette: _avatarPalette[i % _avatarPalette.length],
            ),
          if (r.overdueMembers.isNotEmpty)
            _NameList(
              title: 'AMOUNT OVERDUE',
              color: _red,
              entries: [
                for (final m in r.overdueMembers)
                  (m.fullName, _money(-r.balanceOf(m)).replaceFirst('-', '')),
              ],
            ),
          if (r.creditMembers.isNotEmpty)
            _NameList(
              title: 'EXTRA CREDIT',
              color: _green,
              entries: [
                for (final m in r.creditMembers)
                  (m.fullName, _signed(r.balanceOf(m))),
              ],
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text, this.align);
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w800,
      color: Color(0xFF557A75),
    ),
  );
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.cost,
    required this.balance,
    required this.palette,
  });
  final ReportMember member;
  final int cost;
  final int balance;
  final (Color, Color) palette;

  @override
  Widget build(BuildContext context) {
    final neg = balance < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: member.isYou ? _greenSoft : Colors.white,
        border: const Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 50,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.$1,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: palette.$2.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    member.shortName.isEmpty
                        ? '?'
                        : member.shortName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: palette.$2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: member.shortName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: member.isYou
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: MessLifeColors.textPrimary,
                          ),
                        ),
                        if (member.isYou)
                          const TextSpan(
                            text: ' · YOU',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _green,
                            ),
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              _num(member.meals),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B4F5C),
              ),
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              _plain(cost),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: MessLifeColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              _plain(member.paid),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
          Expanded(
            flex: 30,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: neg ? _redBg : _greenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _signedPlain(balance),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: neg ? _red : _green,
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

class _NameList extends StatelessWidget {
  const _NameList({
    required this.title,
    required this.color,
    required this.entries,
  });
  final String title;
  final Color color;
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.$1,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF3B4F5C),
                      ),
                    ),
                  ),
                  Text(
                    e.$2,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Share / Download
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.report});
  final MonthReportData report;

  String _summary() {
    final r = report;
    final b = StringBuffer()
      ..writeln('MessLife BD - ${r.title}')
      ..writeln('Bazar: ${_money(r.bazar)} | Meals: ${_num(r.totalMeals)} '
          '| Rate: $_taka${r.mealRate.toStringAsFixed(2)}')
      ..writeln('Deposit: ${_money(r.totalDeposit)} | '
          'Net: ${r.netBalance < 0 ? _money(r.netBalance) : _signed(r.netBalance)}')
      ..writeln();
    for (final m in r.members) {
      b.writeln('${m.shortName}: ${_num(m.meals)} meals, '
          'cost ${_plain(r.costOf(m))}, paid ${_plain(m.paid)}, '
          'bal ${_signedPlain(r.balanceOf(m))}');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                // TODO: swap for share_plus (Share.share) when added.
                await Clipboard.setData(ClipboardData(text: _summary()));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: _green.withValues(alpha: 0.4),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 10,
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: generate PDF (pdf + printing packages) and save.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download coming soon')),
                );
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _green,
                side: const BorderSide(color: _line, width: 1.4),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sample data (matches the design screenshots). Remove once real data exists.
// ---------------------------------------------------------------------------

final MonthReportData sampleAugust2026 = MonthReportData(
  year: 2026,
  month: 8,
  bazar: 10740,
  totalMeals: 191.5,
  mealRate: 56.12,
  isLive: true,
  members: const [
    ReportMember(fullName: 'Akif Hossain', meals: 33.5, paid: 4500, isYou: true),
    ReportMember(fullName: 'Rakib Hasan', meals: 28, paid: 5000),
    ReportMember(fullName: 'Solikath Islam', meals: 31.5, paid: 0),
    ReportMember(fullName: 'Sourov Ahmed', meals: 25, paid: 4000),
    ReportMember(fullName: 'Saiful Alam', meals: 30, paid: 5500),
    ReportMember(fullName: 'Mushfiq Ullah', meals: 27, paid: 3000),
    ReportMember(fullName: 'Maruf Hossain', meals: 16.5, paid: 5000),
  ],
);

final MonthReportData sampleJuly2026 = MonthReportData(
  year: 2026,
  month: 7,
  bazar: 9840,
  totalMeals: 187.5,
  mealRate: 52.47,
  isLive: false,
  members: const [
    ReportMember(fullName: 'Akif Hossain', meals: 32, paid: 5000, isYou: true),
    ReportMember(fullName: 'Rakib Hasan', meals: 27.5, paid: 4500),
    ReportMember(fullName: 'Solikath Islam', meals: 30, paid: 0),
    ReportMember(fullName: 'Sourov Ahmed', meals: 24, paid: 4000),
    ReportMember(fullName: 'Saiful Alam', meals: 29, paid: 5000),
    ReportMember(fullName: 'Mushfiq Ullah', meals: 26, paid: 3000),
    ReportMember(fullName: 'Maruf Hossain', meals: 19, paid: 4800),
  ],
);

/// Live (current) month sample. Replace with real Firestore data.
final MonthReportData sampleNovember2026 = MonthReportData(
  year: 2026,
  month: 11,
  bazar: sampleAugust2026.bazar,
  totalMeals: sampleAugust2026.totalMeals,
  mealRate: sampleAugust2026.mealRate,
  isLive: true,
  members: sampleAugust2026.members,
);

/// Looks up the detailed report for an archive month title ("July 2026").
/// Returns null when no data exists yet. Replace with a Firestore read.
MonthReportData? reportDetailFor(String monthTitle) {
  for (final r in [sampleJuly2026, sampleAugust2026]) {
    if (r.title == monthTitle) return r;
  }
  return null;
}