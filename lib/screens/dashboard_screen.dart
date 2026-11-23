import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'archive_screen.dart';
import 'daily_screen.dart';

// ───────── Colors ─────────

abstract final class MessLifeColors {
  // Brand
  static const navy = Color(0xFF073847);
  static const navySecondary = Color(0xFF0C4A5C);
  static const brandGreen = Color(0xFF11CE7E);
  static const accent = Color(0xFF0FA670);
  static const primary = Color(0xFF0B7A50);

  // Mint and surfaces
  static const mint = Color(0xFF9FE6C5);
  static const mintTint = Color(0xFFEAF9F2);
  static const paleGreen = Color(0xFFE1F0E8);
  static const background = Color(0xFFF1F9F5);
  static const surface = Color(0xFFFFFFFF);
  static const alternateSurface = Color(0xFFF8FCFA);

  // Text
  static const textPrimary = Color(0xFF0A2B35);
  static const textSecondary = Color(0xFF46646C);

  // Borders
  static const border = Color(0xFFCBE3D8);

  // Semantic
  static const success = Color(0xFF1E8E5A);
  static const warning = Color(0xFFD98A0B);
  static const error = Color(0xFFC62F26);
  static const danger = Color(0xFFAE181F);
  static const information = Color(0xFF2F7FC1);

  // Dashboard-specific backgrounds
  static const successBackground = Color(0xFFE6F4ED);
  static const dangerBackground = Color(0xFFFCE8E9);
  static const warningBackground = Color(0xFFFFF5E5);
  static const informationBackground = Color(0xFFEAF4FC);

  // Header
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF073847), Color(0xFF0C4A5C), Color(0xFF0B6F6B)],
    stops: [0, 0.70, 1],
  );

  static const metricsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A3E52), Color(0xFF0C5D60)],
  );
}

// ───────── Theme ─────────

ThemeData buildMessLifeTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: MessLifeColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MessLifeColors.primary,
      primary: MessLifeColors.primary,
      secondary: MessLifeColors.accent,
      surface: MessLifeColors.surface,
      error: MessLifeColors.danger,
    ),
    textTheme: Typography.material2021().black.apply(
      fontFamily: 'PlusJakartaSans',
      bodyColor: MessLifeColors.textPrimary,
      displayColor: MessLifeColors.textPrimary,
    ),
    dividerColor: MessLifeColors.border,
  );
}

// ───────── Model ─────────

class MemberStat {
  const MemberStat(
      this.name,
      this.meals,
      this.cost,
      this.paid,
      this.balance, {
        this.isCurrentUser = false,
      });

  final String name;
  final double meals;
  final int cost;
  final int paid;
  final int balance;
  final bool isCurrentUser;

  String get mealsText =>
      meals % 1 == 0 ? meals.toInt().toString() : meals.toString();
}

// ───────── Decorative rings (on gradient surfaces) ─────────

class _RingsPainter extends CustomPainter {
  const _RingsPainter(this.alignment);
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0FFFFFFF);
    final center = alignment.alongSize(size);
    for (var i = 1; i <= 8; i++) {
      canvas.drawCircle(center, 34.0 * i, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.alignment != alignment;
}

/// Draws faint concentric rings behind [child]. Put it inside a clipped,
/// gradient container.
class RingsOverlay extends StatelessWidget {
  const RingsOverlay({
    required this.child,
    this.alignment = const Alignment(0.9, -0.2),
    super.key,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _RingsPainter(alignment)),
          ),
        ),
        child,
      ],
    );
  }
}

// ───────── Small cells ─────────

class MetricCell extends StatelessWidget {
  const MetricCell({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x8CFFFFFF),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerticalDividerCell extends StatelessWidget {
  const VerticalDividerCell({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 44,
      child: ColoredBox(color: Color(0x1AFFFFFF)),
    );
  }
}

class QuickActionCell extends StatelessWidget {
  const QuickActionCell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MessLifeColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MessLifeColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MessLifeColors.textSecondary,
                    fontSize: 9.5,
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

class BalanceSummaryCell extends StatelessWidget {
  const BalanceSummaryCell({
    required this.label,
    required this.amount,
    required this.memberText,
    required this.icon,
    required this.foreground,
    required this.background,
    super.key,
  });

  final String label;
  final String amount;
  final String memberText;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
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
                    color: foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: foreground.withValues(alpha: 0.15)),
                ),
                child: Icon(icon, size: 15, color: foreground),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: foreground,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            memberText,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceCell extends StatelessWidget {
  const FinanceCell({
    required this.label,
    required this.amount,
    required this.caption,
    required this.background,
    required this.amountColor,
    this.borderColor = MessLifeColors.border,
    super.key,
  });

  final String label;
  final String amount;
  final String caption;
  final Color background;
  final Color amountColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MessLifeColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              color: MessLifeColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CostLine extends StatelessWidget {
  const CostLine({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.trailingIcon,
    super.key,
  });

  final String title;
  final String subtitle;
  final String amount;

  /// Shown right after the title (e.g. the expand arrow on Utility).
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: MessLifeColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        trailingIcon,
                        size: 18,
                        color: MessLifeColors.textSecondary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: MessLifeColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: MessLifeColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class UtilityBreakdown extends StatelessWidget {
  const UtilityBreakdown({super.key});

  static const _items = [
    ('Electricity', '৳180'),
    ('Wi-Fi', '৳120'),
    ('Gas', '৳100'),
    ('Cleaning', '৳80'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MessLifeColors.alternateSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MessLifeColors.border),
      ),
      child: Column(
        children: [
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: MessLifeColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      color: MessLifeColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

// ───────── Header ─────────

class HeaderIcon extends StatelessWidget {
  const HeaderIcon({
    required this.icon,
    this.showNotification = false,
    super.key,
  });

  final IconData icon;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.white),
          if (showNotification)
            Positioned(
              top: 9,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                  border: Border.all(color: MessLifeColors.navySecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HeaderPill extends StatelessWidget {
  const HeaderPill({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: child,
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: MessLifeColors.brandGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x6611CE7E), blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }
}

/// Gradient header with the Mess Cost card floating over its bottom edge.
/// The card is part of the layout, so its height never has to be guessed:
/// the gradient simply stops [_overlap] pixels above the bottom of the card.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  static const double _overlap = 46;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: _overlap,
          child: Container(
            decoration: const BoxDecoration(
              gradient: MessLifeColors.headerGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: const RingsOverlay(
              alignment: Alignment(0.95, 0.1),
              child: SizedBox.expand(),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 16, 16, 0),
          child: const Column(
            children: [
              Row(
                children: [
                  HeaderIcon(icon: Icons.menu_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MESSLIFE BD',
                          style: TextStyle(
                            color: Color(0x8CFFFFFF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Welcome, Akif!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sun, 22 November 2026',
                          style: TextStyle(
                            color: Color(0x8CFFFFFF),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HeaderIcon(
                    icon: Icons.notifications_none_rounded,
                    showNotification: true,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Flexible(
                    child: HeaderPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusDot(),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Al-Amin Mess',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: MessLifeColors.mint,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  HeaderPill(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Color(0xB3FFFFFF),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '12 Members',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              MessCostCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class MessCostCard extends StatelessWidget {
  const MessCostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: MessLifeColors.metricsGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x24FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x57051928),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: const RingsOverlay(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Text(
                    'MESS COST',
                    style: TextStyle(
                      color: MessLifeColors.mint,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'THIS MONTH',
                    style: TextStyle(
                      color: Color(0x6BFFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Color(0x1AFFFFFF)),
            Row(
              children: [
                MetricCell(
                  label: 'BAZAR',
                  value: '৳10,740',
                  valueColor: Color(0xFFFF6B6B),
                ),
                VerticalDividerCell(),
                MetricCell(label: 'MEALS', value: '171.5'),
                VerticalDividerCell(),
                MetricCell(label: 'MEAL RATE', value: '৳53.47'),
              ],
            ),
            Divider(height: 1, color: Color(0x1AFFFFFF)),
            Row(
              children: [
                MetricCell(label: 'TOTAL DEPOSIT', value: '৳11,100'),
                VerticalDividerCell(),
                MetricCell(
                  label: 'NET BALANCE',
                  value: '+৳1,930',
                  valueColor: MessLifeColors.mint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────── Member stats ─────────

class MemberStatsCard extends StatelessWidget {
  const MemberStatsCard({
    required this.members,
    this.onViewReport,
    super.key,
  });

  final List<MemberStat> members;
  final VoidCallback? onViewReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MessLifeColors.border),
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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THIS MONTH',
                            style: TextStyle(
                              color: Color(0x8CFFFFFF),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Member Meal Stats',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MemberCountChip(count: members.length),
                  ],
                ),
              ),
            ),
          ),
          const MemberTableHeader(),
          for (var i = 0; i < members.length; i++)
            MemberTableRow(members[i], tinted: i.isOdd),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: GestureDetector(
              onTap: onViewReport,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: MessLifeColors.mintTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MessLifeColors.border),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEMBER FINANCES',
                            style: TextStyle(
                              color: MessLifeColors.textSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'View complete monthly report',
                            style: TextStyle(
                              color: MessLifeColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: MessLifeColors.primary,
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCountChip extends StatelessWidget {
  const _MemberCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Text(
        '$count members',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TableHeading extends StatelessWidget {
  const TableHeading(this.text, {this.right = false, super.key});

  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: MessLifeColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class RightCell extends StatelessWidget {
  const RightCell(
      this.text, {
        this.color,
        this.weight = FontWeight.w700,
        super.key,
      });

  final String text;
  final Color? color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? MessLifeColors.textPrimary,
        fontSize: 12,
        fontWeight: weight,
      ),
    );
  }
}

class MemberTableHeader extends StatelessWidget {
  const MemberTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: MessLifeColors.paleGreen,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 2, child: TableHeading('NAME')),
            Expanded(child: TableHeading('MEALS', right: true)),
            Expanded(child: TableHeading('COST', right: true)),
            Expanded(child: TableHeading('PAID', right: true)),
            Expanded(child: TableHeading('BAL', right: true)),
          ],
        ),
      ),
    );
  }
}

class MemberTableRow extends StatelessWidget {
  const MemberTableRow(this.member, {this.tinted = false, super.key});

  final MemberStat member;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final positive = member.balance >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      color: member.isCurrentUser
          ? MessLifeColors.mintTint
          : tinted
          ? MessLifeColors.alternateSurface
          : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: member.isCurrentUser
                        ? MessLifeColors.primary
                        : positive
                        ? MessLifeColors.mintTint
                        : MessLifeColors.dangerBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member.name.substring(0, 1),
                    style: TextStyle(
                      color: member.isCurrentUser
                          ? Colors.white
                          : positive
                          ? MessLifeColors.primary
                          : MessLifeColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: member.name,
                      style: TextStyle(
                        color: MessLifeColors.textPrimary,
                        fontSize: 13,
                        fontWeight: member.isCurrentUser
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                      children: [
                        if (member.isCurrentUser)
                          const TextSpan(
                            text: ' · YOU',
                            style: TextStyle(
                              color: MessLifeColors.textSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RightCell(member.mealsText, weight: FontWeight.w500),
          ),
          Expanded(child: RightCell('৳${member.cost}')),
          Expanded(
            child: RightCell('৳${member.paid}', color: MessLifeColors.primary),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: positive
                      ? MessLifeColors.successBackground
                      : MessLifeColors.dangerBackground,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${positive ? '+' : '−'}৳${member.balance.abs()}',
                  style: TextStyle(
                    color: positive
                        ? MessLifeColors.success
                        : MessLifeColors.danger,
                    fontSize: 10.5,
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

// ───────── Bottom navigation ─────────

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
}

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.restaurant_menu, Icons.restaurant_menu, 'Daily', badge: 5),
    _NavItem(Icons.inbox_outlined, Icons.inbox_rounded, 'Request', badge: 4),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'Chat'),
    _NavItem(
      Icons.shopping_basket_outlined,
      Icons.shopping_basket_rounded,
      'Bazar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
        decoration: const BoxDecoration(
          color: Color(0xFAFFFFFF),
          border: Border(top: BorderSide(color: MessLifeColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x170A2B35),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final active = index == selectedIndex;
            final item = _items[index];
            final color = active
                ? MessLifeColors.primary
                : MessLifeColors.textSecondary;

            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 30,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: active ? 46 : 32,
                            height: 30,
                            decoration: BoxDecoration(
                              color: active
                                  ? MessLifeColors.mintTint
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              active ? item.activeIcon : item.icon,
                              size: 21,
                              color: color,
                            ),
                          ),
                          if (item.badge > 0)
                            Positioned(
                              top: -4,
                              right: 2,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 17,
                                  minHeight: 17,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5483B),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  '${item.badge}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ───────── Screen ─────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedNavigationIndex = 0;
  bool utilityExpanded = false;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  final members = const [
    MemberStat('Solikath', 33.5, 1791, 1919, 128),
    MemberStat('Sourov', 7, 374, 248, -239),
    MemberStat('Saiful', 31.5, 1684, 1500, 184),
    MemberStat('Mushfiq', 32.5, 1737, 1868, 190),
    MemberStat('Akif', 33.5, 1791, 1992, 201, isCurrentUser: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildMessLifeTheme(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // Android
          statusBarBrightness: Brightness.dark, // iOS
        ),
        child: Scaffold(
          backgroundColor: MessLifeColors.background,
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ScrollConfiguration(
                      // No bounce / stretch at the top and bottom.
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(overscroll: false),
                      child: SingleChildScrollView(
                        controller: _scroll,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            const DashboardHeader(),
                            const SizedBox(height: 18),
                            _sectionHeader(
                              title: 'QUICK ACTIONS',
                              action: 'Recent activity',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: QuickActionCell(
                                      icon: Icons.shopping_basket_outlined,
                                      title: 'Bazar',
                                      subtitle: 'Add expense',
                                      iconColor: Color(0xFFB56B0A),
                                      iconBackground:
                                      MessLifeColors.warningBackground,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: QuickActionCell(
                                      icon: Icons.account_balance_wallet_outlined,
                                      title: 'Payment',
                                      subtitle: 'Record money',
                                      iconColor: MessLifeColors.information,
                                      iconBackground:
                                      MessLifeColors.informationBackground,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: QuickActionCell(
                                      icon: Icons.bar_chart_rounded,
                                      title: 'Summary',
                                      subtitle: 'View month',
                                      iconColor: MessLifeColors.primary,
                                      iconBackground: MessLifeColors.mintTint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: BalanceSummaryCell(
                                      label: 'EXTRA CREDIT',
                                      amount: '+৳18,021',
                                      memberText: '6 members',
                                      icon: Icons.trending_up_rounded,
                                      foreground: MessLifeColors.success,
                                      background: MessLifeColors.successBackground,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: BalanceSummaryCell(
                                      label: 'OVERDUE',
                                      amount: '৳1,768',
                                      memberText: '1 member',
                                      icon: Icons.error_outline_rounded,
                                      foreground: MessLifeColors.danger,
                                      background: MessLifeColors.dangerBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: MemberStatsCard(
                                members: members,
                                onViewReport: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ArchiveScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                              child: _buildMyCostCard(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Status bar area: transparent at the top (header shows through),
                    // solid once scrolled, so content never mixes with the clock.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _scroll,
                          builder: (context, _) {
                            final offset =
                            _scroll.hasClients ? _scroll.offset : 0.0;
                            final t = (offset / 24).clamp(0.0, 1.0);
                            return Container(
                              height: MediaQuery.paddingOf(context).top,
                              color: MessLifeColors.navy.withValues(alpha: t),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DashboardBottomNavigation(
                selectedIndex: selectedNavigationIndex,
                onSelected: (index) {
                  // Daily tab opens its own screen; Home stays highlighted here.
                  if (index == 1) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DailyScreen()),
                    );
                    return;
                  }
                  setState(() => selectedNavigationIndex = index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({required String title, required String action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MessLifeColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Text(
            action,
            style: const TextStyle(
              color: MessLifeColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCostCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MessLifeColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x17073847),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: MessLifeColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: SizedBox(width: 4, height: 16),
              ),
              SizedBox(width: 8),
              Text(
                'MY COST — NOVEMBER 2026',
                style: TextStyle(
                  color: MessLifeColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: FinanceCell(
                  label: 'MY DEPOSIT',
                  amount: '৳5,000',
                  caption: 'Paid this month',
                  background: MessLifeColors.alternateSurface,
                  amountColor: MessLifeColors.navy,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FinanceCell(
                  label: 'MY CURRENT BALANCE',
                  amount: '+৳229',
                  caption: 'Credit available',
                  background: MessLifeColors.mintTint,
                  amountColor: MessLifeColors.primary,
                  borderColor: MessLifeColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const CostLine(
            title: 'Seat Rent',
            subtitle: 'fixed monthly rent',
            amount: '৳2,500',
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => setState(() => utilityExpanded = !utilityExpanded),
            child: CostLine(
              title: 'Utility',
              subtitle: 'per head share',
              amount: '৳480',
              trailingIcon: utilityExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: utilityExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: const UtilityBreakdown(),
          ),
          const Divider(height: 1),
          const CostLine(
            title: 'Meal Cost',
            subtitle: '33.5 meals × ৳53.47',
            amount: '৳1,791',
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: MessLifeColors.headerGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38073847),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: const RingsOverlay(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL COST THIS MONTH',
                            style: TextStyle(
                              color: Color(0xA6FFFFFF),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Rent + Utility + Meals',
                            style: TextStyle(
                              color: Color(0x8CFFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '৳4,771',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}