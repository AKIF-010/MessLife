// File: lib/widgets/phone_field.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import 'common_widgets.dart';

// ---------------------------------------------------------------------------
// Countries
// ---------------------------------------------------------------------------

/// One country: dial code + how many digits a mobile number has AFTER the
/// country code (and without the leading trunk "0").
class Country {
  const Country(
      this.iso,
      this.name,
      this.dial,
      this.minDigits,
      this.maxDigits,
      this.example, {
        this.trunkZero = true,
        this.pattern,
      });

  final String iso; // ISO 3166-1 alpha-2, e.g. "BD"
  final String name;
  final String dial; // without "+", e.g. "880"
  final int minDigits;
  final int maxDigits;
  final String example; // placeholder shown in the field
  final bool trunkZero; // numbers may be written with a leading 0
  final String? pattern; // optional extra regex on the national digits

  String get dialText => '+$dial';

  /// Flag emoji built from the ISO code.
  String get flag => String.fromCharCodes(
    iso.codeUnits.map((c) => 0x1F1E6 + c - 0x41),
  );
}

const kBangladesh = Country(
  'BD',
  'Bangladesh',
  '880',
  10,
  10,
  '1712345678',
  pattern: r'^1[3-9]\d{8}$', // 01[3-9]XXXXXXXX
);

/// Digit lengths are for mobile numbers. Review them for any country you
/// rely on heavily; add or edit entries freely.
const List<Country> kCountries = [
  kBangladesh,
  Country('IN', 'India', '91', 10, 10, '9876543210',
      pattern: r'^[6-9]\d{9}$'),
  Country('PK', 'Pakistan', '92', 10, 10, '3012345678'),
  Country('NP', 'Nepal', '977', 10, 10, '9841234567'),
  Country('LK', 'Sri Lanka', '94', 9, 9, '712345678'),
  Country('BT', 'Bhutan', '975', 8, 8, '17123456'),
  Country('MV', 'Maldives', '960', 7, 7, '7712345', trunkZero: false),
  Country('AF', 'Afghanistan', '93', 9, 9, '701234567'),
  Country('AE', 'United Arab Emirates', '971', 9, 9, '501234567'),
  Country('SA', 'Saudi Arabia', '966', 9, 9, '512345678'),
  Country('QA', 'Qatar', '974', 8, 8, '33123456', trunkZero: false),
  Country('KW', 'Kuwait', '965', 8, 8, '50012345', trunkZero: false),
  Country('OM', 'Oman', '968', 8, 8, '92123456', trunkZero: false),
  Country('BH', 'Bahrain', '973', 8, 8, '36001234', trunkZero: false),
  Country('MY', 'Malaysia', '60', 9, 10, '123456789'),
  Country('SG', 'Singapore', '65', 8, 8, '81234567', trunkZero: false),
  Country('ID', 'Indonesia', '62', 9, 12, '812345678'),
  Country('TH', 'Thailand', '66', 9, 9, '812345678'),
  Country('MM', 'Myanmar', '95', 8, 10, '912345678'),
  Country('CN', 'China', '86', 11, 11, '13123456789', trunkZero: false),
  Country('JP', 'Japan', '81', 10, 10, '9012345678'),
  Country('KR', 'South Korea', '82', 9, 10, '1012345678'),
  Country('AU', 'Australia', '61', 9, 9, '412345678'),
  Country('GB', 'United Kingdom', '44', 10, 10, '7123456789'),
  Country('DE', 'Germany', '49', 10, 11, '15123456789'),
  Country('FR', 'France', '33', 9, 9, '612345678'),
  Country('IT', 'Italy', '39', 9, 10, '3123456789', trunkZero: false),
  Country('TR', 'Turkey', '90', 10, 10, '5012345678'),
  Country('RU', 'Russia', '7', 10, 10, '9123456789'),
  Country('US', 'United States', '1', 10, 10, '2015550123',
      trunkZero: false),
  Country('CA', 'Canada', '1', 10, 10, '4165550123', trunkZero: false),
  Country('BR', 'Brazil', '55', 10, 11, '11912345678'),
  Country('EG', 'Egypt', '20', 10, 10, '1012345678'),
  Country('ZA', 'South Africa', '27', 9, 9, '712345678'),
  Country('NG', 'Nigeria', '234', 10, 10, '8012345678'),
];

// ---------------------------------------------------------------------------
// Rules
// ---------------------------------------------------------------------------

class PhoneRules {
  PhoneRules._();

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Digits after the country code, without the trunk "0".
  static String national(Country c, String raw) {
    var d = _digits(raw);
    if (c.trunkZero) d = d.replaceFirst(RegExp(r'^0+'), '');
    return d;
  }

  static bool isValid(Country c, String raw) {
    final d = national(c, raw);
    if (d.length < c.minDigits || d.length > c.maxDigits) return false;
    final p = c.pattern;
    return p == null || RegExp(p).hasMatch(d);
  }

  /// "+8801712345678" or null when invalid.
  static String? toE164(Country c, String raw) =>
      isValid(c, raw) ? '+${c.dial}${national(c, raw)}' : null;

  /// Splits a stored "+880..." number back into country + national digits.
  static (Country, String)? fromE164(String e164) {
    if (!e164.startsWith('+')) return null;
    final digits = e164.substring(1);
    Country? best;
    for (final c in kCountries) {
      if (digits.startsWith(c.dial) &&
          (best == null || c.dial.length > best.dial.length)) {
        best = c;
      }
    }
    if (best == null) return null;
    return (best, digits.substring(best.dial.length));
  }
}

/// Keeps only digits, drops the trunk "0", removes a pasted country code,
/// and stops typing once the country's maximum length is reached.
class _NationalDigitsFormatter extends TextInputFormatter {
  _NationalDigitsFormatter(this.country);
  final Country country;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limit = country.maxDigits + (country.trunkZero ? 1 : 0);
    if (d.length > limit && d.startsWith(country.dial)) {
      d = d.substring(country.dial.length);
    }
    if (country.trunkZero) d = d.replaceFirst(RegExp(r'^0+'), '');
    if (d.length > country.maxDigits) d = d.substring(0, country.maxDigits);
    return TextEditingValue(
      text: d,
      selection: TextSelection.collapsed(
        offset: math.min(newValue.selection.end, d.length),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.label,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.enabled = true,
    this.isRequired,
    this.requiredKey = 'phoneRequired',
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final Country country;
  final ValueChanged<Country> onCountryChanged;
  final bool enabled;

  /// Return false to make an empty field valid. Defaults to required.
  final bool Function()? isRequired;
  final String requiredKey;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  OutlineInputBorder _border(Color color, [double width = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  Future<void> _pickCountry() async {
    if (!widget.enabled) return;
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CountrySheet(selected: widget.country),
    );
    if (picked == null || !mounted) return;

    widget.onCountryChanged(picked);
    // Re-apply the new country's limits to what is already typed.
    final fixed = _NationalDigitsFormatter(picked)
        .formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: widget.controller.text),
    )
        .text;
    widget.controller.text = fixed;
    if (fixed.isNotEmpty) _fieldKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.country;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label),
        const SizedBox(height: 6),
        TextFormField(
          key: _fieldKey,
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.phone,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
          inputFormatters: [_NationalDigitsFormatter(c)],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
          validator: (v) {
            final t = (v ?? '').trim();
            final required = widget.isRequired?.call() ?? true;
            if (t.isEmpty) {
              return required ? context.tr(widget.requiredKey) : null;
            }
            return PhoneRules.isValid(c, t)
                ? null
                : context.tr('phoneInvalid');
          },
          decoration: InputDecoration(
            hintText: c.example,
            hintStyle: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.fieldFill,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            prefixIcon: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickCountry,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      c.dialText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.muted,
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      margin: const EdgeInsets.only(left: 2),
                      color: AppColors.mintBorder,
                    ),
                  ],
                ),
              ),
            ),
            enabledBorder: _border(AppColors.mintBorder),
            disabledBorder: _border(AppColors.mintBorder),
            focusedBorder: _border(AppColors.primary, 1.6),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error, 1.6),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Country picker sheet
// ---------------------------------------------------------------------------

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected});
  final Country selected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = kCountries
        .where((c) =>
    q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        c.dial.contains(q.replaceAll('+', '')) ||
        c.iso.toLowerCase() == q)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mintBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.mintBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.mintBorder),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  final on = c.iso == widget.selected.iso;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                        color: AppColors.dark,
                      ),
                    ),
                    subtitle: Text(
                      '${c.minDigits == c.maxDigits ? c.maxDigits : '${c.minDigits}-${c.maxDigits}'} digits',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.dialText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        if (on) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}