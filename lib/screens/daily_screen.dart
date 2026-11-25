// File: lib/screens/daily_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dashboard_screen.dart';

// ───────── Model ─────────

class _MealPlan {
  _MealPlan({
    required this.name,
    required this.shortName,
    required this.time,
    required this.emoji,
    required this.members,
    required this.items,
    required this.accent,
    required this.tint,
  });

  final String name;
  final String shortName;
  final String time;
  final String emoji;
  final int members; // other members eating (sample data)
  final List<String> items;
  final Color accent;
  final Color tint;

  /// Permanent plan ("Always").
  bool always = true;

  /// One-day override ("Today only"). null = no override.
  bool? today;

  /// Value the user asked for (opposite of the current state), applied only
  /// after they pick "Today only" or "Always". Until then nothing changes.
  bool pendingValue = true;

  /// Mini drop-down (Today only / Always) is open.
  bool pickerOpen = false;

  bool get effective => today ?? always;
  bool get isToday => today != null;
}

// ───────── Screen ─────────

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  static const _maxGuests = 20;

  final List<_MealPlan> _meals = [
    _MealPlan(
      name: 'Breakfast',
      shortName: 'BRE',
      time: '7:00 – 9:00 AM',
      emoji: '☕',
      members: 8,
      items: const ['পরোটা', 'ডিম ভাজি', 'চা', 'আলু ভাজি'],
      accent: const Color(0xFFF59E0B),
      tint: const Color(0xFFFFF8E1),
    ),
    _MealPlan(
      name: 'Lunch',
      shortName: 'LUN',
      time: '12:30 – 2:30 PM',
      emoji: '🍲',
      members: 10,
      items: const ['ভাত', 'ডাল', 'মুরগির ঝোল', 'সবজি'],
      accent: const Color(0xFF0B7A50),
      tint: const Color(0xFFEAF9F2),
    ),
    _MealPlan(
      name: 'Dinner',
      shortName: 'DIN',
      time: '8:00 – 10:00 PM',
      emoji: '🌙',
      members: 9,
      items: const ['ভাত', 'মাছ ভাজা', 'ডাল'],
      accent: const Color(0xFF5B5BD6),
      tint: const Color(0xFFEEEEFC),
    ),
  ];

  final List<int> _guests = [0, 0, 0];

  bool _paused = false;
  bool _guestOpen = true;
  int _tab = 0;

  int get _active => _paused ? 0 : _meals.where((m) => m.effective).length;

  // ── Actions ──

  void _togglePause(bool value) {
    setState(() {
      _paused = value;
      // Individual states are kept untouched, so turning pause off brings
      // the previous breakfast / lunch / dinner states straight back.
      for (final m in _meals) {
        m.pickerOpen = false;
      }
    });
  }

  void _toggleMeal(_MealPlan m, bool value) {
    if (_paused) return;
    setState(() {
      if (m.pickerOpen) {
        // Tapping the switch again cancels: the state was never changed.
        m.pickerOpen = false;
        return;
      }
      // Do NOT change the meal yet. Remember what was asked for and let the
      // user choose the scope first.
      m.pendingValue = !m.effective;
      m.pickerOpen = true;
    });
  }

  void _chooseScope(_MealPlan m, {required bool todayOnly}) {
    setState(() {
      if (todayOnly) {
        // One-day override; the permanent plan stays as it was.
        m.today = m.pendingValue == m.always ? null : m.pendingValue;
      } else {
        // Permanent change; clears any one-day override.
        m.always = m.pendingValue;
        m.today = null;
      }
      m.pickerOpen = false;
    });
  }

  void _changeGuests(int index, int delta) {
    setState(() {
      _guests[index] = (_guests[index] + delta).clamp(0, _maxGuests);
    });
  }

  void _onNav(int index) {
    if (index == 0) {
      Navigator.of(context).pop();
    } else if (index != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon')),
      );
    }
  }

  // ── Build ──

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
              const _DailyHeader(),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(overscroll: false),
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
                    children: [
                      _buildPlanCard(),
                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 10),
                        child: Text(
                          "TODAY'S MENU",
                          style: TextStyle(
                            color: MessLifeColors.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      _buildMenuCard(),
                    ],
                  ),
                ),
              ),
              DashboardBottomNavigation(selectedIndex: 1, onSelected: _onNav),
            ],
          ),
        ),
      ),
    );
  }

  // ── Meal plan card ──

  Widget _buildPlanCard() {
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
          _planHeader(),
          _pauseRow(),
          const Divider(height: 1, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            child: Column(
              children: [
                for (final m in _meals) ...[
                  _MealRow(
                    meal: m,
                    paused: _paused,
                    onChanged: (v) => _toggleMeal(m, v),
                    onScope: (todayOnly) =>
                        _chooseScope(m, todayOnly: todayOnly),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: _guestSection(),
          ),
        ],
      ),
    );
  }

  Widget _planHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: MessLifeColors.headerGradient),
      child: RingsOverlay(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 20,
                  color: MessLifeColors.mint,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY CONTROLS',
                      style: TextStyle(
                        color: Color(0x8CFFFFFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      "Today's Meal Plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: Text(
                  '$_active active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
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

  Widget _pauseRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pause all meals',
                  style: TextStyle(
                    color: MessLifeColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _paused
                      ? 'Meals are paused until resumed'
                      : 'Your normal meal plan is active',
                  style: const TextStyle(
                    color: MessLifeColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          _PillSwitch(value: _paused, onChanged: _togglePause),
        ],
      ),
    );
  }

  // ── Guest meals ──

  Widget _guestSection() {
    return Container(
      decoration: BoxDecoration(
        color: MessLifeColors.mintTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MessLifeColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _guestOpen = !_guestOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 20,
                    color: MessLifeColors.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Guest meals',
                      style: TextStyle(
                        color: MessLifeColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Text(
                    'Add',
                    style: TextStyle(
                      color: MessLifeColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _guestOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: MessLifeColors.primary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _guestOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MessLifeColors.border),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _meals.length; i++)
                      Expanded(
                        child: _GuestCounter(
                          label: _meals[i].shortName,
                          count: _guests[i],
                          onMinus: () => _changeGuests(i, -1),
                          onPlus: () => _changeGuests(i, 1),
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

  // ── Today's menu ──

  Widget _buildMenuCard() {
    final m = _meals[_tab];
    final eating = !_paused && m.effective;
    final total = m.members + _guests[_tab];

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
          // Tabs
          Row(
            children: [
              for (var i = 0; i < _meals.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: i == _tab ? _meals[i].tint : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: i == _tab
                                ? _meals[i].accent
                                : MessLifeColors.border,
                            width: i == _tab ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _meals[i].emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _meals[i].name,
                            style: TextStyle(
                              color: i == _tab
                                  ? _meals[i].accent
                                  : MessLifeColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Body
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: m.tint,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: m.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'MEALS',
                            style: TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${m.members} members eating',
                            style: const TextStyle(
                              color: MessLifeColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.alarm, size: 13, color: m.accent),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  m.time,
                                  style: const TextStyle(
                                    color: MessLifeColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_guests[_tab] > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '+ ${_guests[_tab]} guest'
                                    '${_guests[_tab] == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: m.accent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(eating: eating),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0x33000000)),
                const SizedBox(height: 12),
                Text(
                  'ITEMS TO COOK — ${m.items.length}',
                  style: const TextStyle(
                    color: MessLifeColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < m.items.length; i++)
                      _ItemChip(
                        index: i + 1,
                        name: m.items[i],
                        accent: m.accent,
                      ),
                  ],
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

class _DailyHeader extends StatelessWidget {
  const _DailyHeader();

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
                      'DAILY',
                      style: TextStyle(
                        color: Color(0x8CFFFFFF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      "Today's Overview",
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
            ],
          ),
        ),
      ),
    );
  }
}

// ───────── Meal row + mini drop-down ─────────

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.paused,
    required this.onChanged,
    required this.onScope,
  });

  final _MealPlan meal;
  final bool paused;
  final ValueChanged<bool> onChanged;
  final ValueChanged<bool> onScope; // true = today only

  @override
  Widget build(BuildContext context) {
    final on = !paused && meal.effective;
    final open = meal.pickerOpen && !paused;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: paused ? 0.5 : 1,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
            decoration: BoxDecoration(
              color: MessLifeColors.mintTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: open ? MessLifeColors.primary : MessLifeColors.border,
                width: open ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MessLifeColors.border),
                  ),
                  child: Text(
                    meal.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            meal.name,
                            style: const TextStyle(
                              color: MessLifeColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ScopeTag(todayOnly: meal.isToday),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meal.time,
                        style: const TextStyle(
                          color: MessLifeColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _PillSwitch(
                  value: on,
                  enabled: !paused,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ScopeOption(
                      icon: Icons.today_rounded,
                      iconColor: MessLifeColors.information,
                      title: 'Today only',
                      subtitle: meal.pendingValue
                          ? 'On for today'
                          : 'Off for today',
                      selected: false,
                      onTap: () => onScope(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScopeOption(
                      icon: Icons.event_repeat_rounded,
                      iconColor: MessLifeColors.information,
                      title: 'Always',
                      subtitle: meal.pendingValue
                          ? 'On until changed'
                          : 'Off until changed',
                      selected: false,
                      onTap: () => onScope(false),
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ScopeTag extends StatelessWidget {
  const _ScopeTag({required this.todayOnly});

  final bool todayOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: todayOnly ? MessLifeColors.informationBackground : Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        todayOnly ? 'TODAY' : 'ALWAYS',
        style: TextStyle(
          color: todayOnly ? MessLifeColors.information : MessLifeColors.primary,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? MessLifeColors.mintTint : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? MessLifeColors.mint : MessLifeColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MessLifeColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MessLifeColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────── Small widgets ─────────

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onChanged(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? MessLifeColors.primary : const Color(0xFFD3E7DD),
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestCounter extends StatelessWidget {
  const _GuestCounter({
    required this.label,
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int count;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MessLifeColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepButton(icon: Icons.remove, filled: false, onTap: onMinus),
            SizedBox(
              width: 26,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MessLifeColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _StepButton(icon: Icons.add, filled: true, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? MessLifeColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: filled ? MessLifeColors.primary : MessLifeColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: filled ? Colors.white : MessLifeColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.eating});

  final bool eating;

  @override
  Widget build(BuildContext context) {
    final color = eating ? MessLifeColors.success : MessLifeColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: eating
            ? MessLifeColors.successBackground
            : MessLifeColors.dangerBackground,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            eating ? "I'm eating" : 'Skipping',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({
    required this.index,
    required this.name,
    required this.accent,
  });

  final int index;
  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$index',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              color: MessLifeColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}