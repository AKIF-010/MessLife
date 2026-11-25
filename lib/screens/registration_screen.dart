// File: lib/screens/registration_screen.dart
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../core/validators.dart';
import '../services/auth_flow.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/phone_field.dart';

/// Post-login registration, 3 steps:
///   1) Personal info   2) Contact & identity   3) Occupation & emergency
/// Shown after login/sign-up (and after email verification) until
/// users/{uid}.onboarding_complete == true.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _religions = [
    'islam',
    'hinduism',
    'christianity',
    'buddhism',
    'other',
  ];
  static const _bloods = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  static const _occupations = [
    'student',
    'job',
    'business',
    'freelance',
    'other',
  ];
  static const _occupationLabels = {
    'student': 'Student',
    'job': 'Professional',
    'business': 'Business',
    'freelance': 'Freelancer',
    'other': 'Other',
  };
  static const _occupationIcons = {
    'student': Icons.school_outlined,
    'job': Icons.work_outline_rounded,
    'business': Icons.apartment_outlined,
    'freelance': Icons.laptop_mac_outlined,
    'other': Icons.account_circle_outlined,
  };
  static const _relations = [
    'father',
    'mother',
    'sibling',
    'spouse',
    'friend',
    'guardian',
    'other',
  ];

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  final _scroll = ScrollController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  Country _phoneCountry = kBangladesh;
  Country _emCountry = kBangladesh;
  final _emNameCtrl = TextEditingController();
  final _emPhoneCtrl = TextEditingController();

  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String _email = '';

  int _day = 15;
  int _month = 1;
  int _year = 2000;
  String? _gender; // "male" | "female"
  String? _religion;
  String? _blood;
  String? _occupation;
  String? _relation;
  bool _agree = false;

  // Verification document (optional). Uploaded when registration is saved.
  final _picker = ImagePicker();
  Uint8List? _docBytes;
  String _docName = 'id.jpg';

  bool _genderError = false;
  bool _occError = false;
  bool _termsError = false;

  /// Youngest allowed birth year (user must be at least 15).
  int get _maxYear => DateTime.now().year - 15;
  static const int _minYear = 1950;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emNameCtrl.dispose();
    _emPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AuthService.instance.currentUser;
    _email = user?.email ?? '';
    Map<String, dynamic>? d;
    try {
      if (user != null) d = await UserService.instance.getUser(user.uid);
    } catch (_) {}

    if (d != null) {
      final name =
      '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();
      _nameCtrl.text = name.isNotEmpty ? name : (user?.displayName ?? '');
      final g = d['gender'];
      if (g == 'male' || g == 'female') _gender = g as String;
      final p = d['phone'];
      if (p is String) {
        final parts = PhoneRules.fromE164(p);
        if (parts != null) {
          _phoneCountry = parts.$1;
          _phoneCtrl.text = parts.$2;
        }
      }
      final bd = d['birth_day'];
      final bm = d['birth_month'];
      final by = d['birth_year'];
      if (bd is num && bm is num && by is num) {
        _day = bd.toInt();
        _month = bm.toInt();
        _year = by.toInt().clamp(_minYear, _maxYear);
      }
      final bg = d['blood_group'];
      if (bg is String && _bloods.contains(bg)) _blood = bg;
      final rl = d['religion'];
      if (rl is String && _religions.contains(rl)) _religion = rl;
      final ot = d['occupation_type'];
      if (ot is String && _occupations.contains(ot)) _occupation = ot;
    } else {
      _nameCtrl.text = user?.displayName ?? '';
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ---------- navigation ----------

  Future<void> _onBack() async {
    if (_step > 0) {
      setState(() => _step--);
      _scrollTop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('leaveSetupTitle')),
        content: Text(ctx.tr('leaveSetupBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('stay')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('leave')),
          ),
        ],
      ),
    );
    if (leave == true) AuthFlow.cancel();
  }

  void _scrollTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _onNext() {
    FocusScope.of(context).unfocus();
    switch (_step) {
      case 0:
        final ok = _formKeys[0].currentState!.validate();
        setState(() => _genderError = _gender == null);
        if (!ok || _gender == null) return;
        setState(() => _step = 1);
        _scrollTop();
      case 1:
        if (!_formKeys[1].currentState!.validate()) return;
        setState(() => _step = 2);
        _scrollTop();
      default:
        _submit();
    }
  }

  bool get _emergencyStarted =>
      _emNameCtrl.text.trim().isNotEmpty ||
          _emPhoneCtrl.text.trim().isNotEmpty ||
          _relation != null;

  Future<void> _submit() async {
    final ok = _formKeys[2].currentState!.validate();
    setState(() {
      _occError = _occupation == null;
      _termsError = !_agree;
    });
    if (!ok || _occupation == null || !_agree) return;

    final user = AuthService.instance.currentUser;
    if (user == null) return;

    Map<String, String>? emergency;
    if (_emergencyStarted) {
      emergency = {
        'name': _emNameCtrl.text.trim(),
        'phone': PhoneRules.toE164(_emCountry, _emPhoneCtrl.text)!,
        'relation': _relation!,
      };
    }

    setState(() => _saving = true);
    String? docPath;
    if (_docBytes != null) {
      try {
        docPath = await _uploadDoc(user.uid);
      } catch (_) {
        if (!mounted) return;
        setState(() => _saving = false);
        showAppSnack(context, 'Photo upload failed. Check your connection and try again.');
        return;
      }
    }

    final data = RegistrationData(
      fullName: _nameCtrl.text.trim(),
      gender: _gender!,
      phone: PhoneRules.toE164(_phoneCountry, _phoneCtrl.text)!,
      birthDay: _day,
      birthMonth: _month,
      birthYear: _year,
      bloodGroup: _blood,
      religion: _religion,
      occupationType: _occupation!,
      occupationLabel: _occupationLabels[_occupation]!,
      emergency: emergency,
      verificationDocPath: docPath,
    );

    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await UserService.instance.completeRegistration(
        user,
        data,
        locale: LanguageScope.of(context).code,
      );
      await AuthFlow.advance();
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, context.tr('errSave'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- Verification document ----------

  Future<void> _chooseDocSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _pickDoc(source);
  }

  Future<void> _pickDoc(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) showAppSnack(context, 'Image is too large (max 5 MB)');
        return;
      }
      if (!mounted) return;
      setState(() {
        _docBytes = bytes;
        _docName = file.name;
      });
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Could not open the photo. Check app permissions.');
      }
    }
  }

  /// Uploads the picked image and returns its Storage path.
  Future<String> _uploadDoc(String uid) async {
    final isPng = _docName.toLowerCase().endsWith('.png');
    final ext = isPng ? 'png' : 'jpg';
    final ref = FirebaseStorage.instance.ref(
      'verification_docs/$uid/id_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await ref.putData(
      _docBytes!,
      SettableMetadata(contentType: isPng ? 'image/png' : 'image/jpeg'),
    );
    return ref.fullPath;
  }

  Widget _docPicker() {
    final bytes = _docBytes;
    if (bytes == null) {
      return DashedBorderBox(
        color: AppColors.mintBorder,
        fill: AppColors.fieldFill,
        onTap: _chooseDocSource,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.cardMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('tapUpload'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('docTypes'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            bytes,
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            TextButton.icon(
              onPressed: _saving ? null : _chooseDocSource,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Change'),
            ),
            TextButton.icon(
              onPressed: _saving ? null : () => setState(() => _docBytes = null),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  _step == 0 ? 8 : 16,
                  16,
                  16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _stepBody(context),
                  ),
                ),
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final titles = [
      context.tr('regPersonal'),
      context.tr('regContact'),
      context.tr('regOccupation'),
    ];
    final header = GradientHeader(
      bottomPadding: _step == 0 ? 26 : 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepBar(total: 3, current: _step),
          const SizedBox(height: 16),
          Text(
            context.tr('stepOf3').replaceAll('{n}', '${_step + 1}'),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.mintText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titles[_step],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (_step != 0) return header;

    // Step 1: avatar sits half over the header's bottom edge.
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(children: [header, const SizedBox(height: 38)]),
        Positioned(bottom: 0, child: _avatar(context)),
      ],
    );
  }

  Widget _avatar(BuildContext context) {
    return GestureDetector(
      onTap: () => showAppSnack(context, context.tr('photoSoon'), error: false),
      child: SizedBox(
        width: 84,
        height: 80,
        child: Stack(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.headerStart,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ListenableBuilder(
                listenable: _nameCtrl,
                builder: (context, _) {
                  final t = _nameCtrl.text.trim();
                  return Text(
                    t.isEmpty ? '?' : t.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: 2,
              bottom: 4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final last = _step == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.mintBorder.withValues(alpha: 0.8)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Row(
            children: [
              if (_step > 0) ...[
                SizedBox(
                  width: 54,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _onBack,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(
                        color: AppColors.mintBorder,
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PrimaryButton(
                  label:
                  '${context.tr(last ? 'completeSetup' : 'next')} →',
                  loading: _saving,
                  onPressed: _onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return _stepPersonal(context);
      case 1:
        return _stepContact(context);
      default:
        return _stepOccupation(context);
    }
  }

  // ----- step 1 -----

  Widget _stepPersonal(BuildContext context) {
    final monthName = context.tr('month$_month');
    return Column(
      children: [
        Form(
          key: _formKeys[0],
          child: SectionCard(
            child: AppTextField(
              label: context.tr('fullNameReq'),
              hint: context.tr('fullNameHint'),
              controller: _nameCtrl,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.name],
              validator: (v) => (v?.trim().length ?? 0) < 2
                  ? context.tr('nameRequired')
                  : null,
            ),
          ),
        ),
        SectionCard(
          title: context.tr('dob'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardMint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_day $monthName $_year',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          child: _DobPicker(
            day: _day,
            month: _month,
            year: _year,
            minYear: _minYear,
            maxYear: _maxYear,
            dayLabel: context.tr('day'),
            monthLabel: context.tr('month'),
            yearLabel: context.tr('year'),
            monthName: (m) => context.tr('month$m'),
            onChanged: (d, m, y) => setState(() {
              _day = d;
              _month = m;
              _year = y;
            }),
          ),
        ),
        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FieldLabel(context.tr('gender')),
                    const SizedBox(height: 8),
                    ChoiceTile(
                      label: context.tr('male'),
                      icon: Icons.person_outline_rounded,
                      expand: true,
                      selected: _gender == 'male',
                      onTap: () => setState(() {
                        _gender = 'male';
                        _genderError = false;
                      }),
                    ),
                    const SizedBox(height: 8),
                    ChoiceTile(
                      label: context.tr('female'),
                      icon: Icons.person_outline_rounded,
                      expand: true,
                      selected: _gender == 'female',
                      onTap: () => setState(() {
                        _gender = 'female';
                        _genderError = false;
                      }),
                    ),
                    if (_genderError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          context.tr('genderRequired'),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.mintBorder,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FieldLabel(context.tr('religion')),
                    const SizedBox(height: 8),
                    for (final r in _religions) ...[
                      ChoiceTile(
                        label: context.tr('rel_$r'),
                        expand: true,
                        selected: _religion == r,
                        // Tap again to clear (religion is optional).
                        onTap: () => setState(
                              () => _religion = _religion == r ? null : r,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----- step 2 -----

  Widget _stepContact(BuildContext context) {
    return Column(
      children: [
        Form(
          key: _formKeys[1],
          child: SectionCard(
            child: Column(
              children: [
                AppTextField(
                  label: context.tr('emailLabel'),
                  hint: '',
                  controller: TextEditingController(text: _email),
                  readOnly: true,
                  suffix: const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                PhoneField(
                  label: context.tr('phoneNumberLabel'),
                  controller: _phoneCtrl,
                  country: _phoneCountry,
                  onCountryChanged: (c) => setState(() => _phoneCountry = c),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
              ],
            ),
          ),
        ),
        SectionCard(
          title: context.tr('bloodGroup'),
          trailing: Text(
            context.tr('optional'),
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in _bloods)
                ChoiceTile(
                  label: b,
                  center: true,
                  width: 54,
                  selected: _blood == b,
                  onTap: () => setState(() => _blood = _blood == b ? null : b),
                ),
            ],
          ),
        ),
        SectionCard(
          title: context.tr('verificationDoc'),
          child: _docPicker(),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 13, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('docPrivate'),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----- step 3 -----

  Widget _stepOccupation(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: context.tr('iAmA'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final o in _occupations)
                        ChoiceTile(
                          label: context.tr('occ_$o'),
                          icon: _occupationIcons[o],
                          width: w,
                          selected: _occupation == o,
                          onTap: () => setState(() {
                            _occupation = o;
                            _occError = false;
                          }),
                        ),
                    ],
                  );
                },
              ),
              if (_occError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    context.tr('occRequired'),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Form(
          key: _formKeys[2],
          child: SectionCard(
            title: context.tr('emergency'),
            trailing: Text(
              context.tr('optional'),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: AppTextField(
                        label: context.tr('name'),
                        hint: context.tr('emNameHint'),
                        controller: _emNameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                        _emergencyStarted && (v?.trim().isEmpty ?? true)
                            ? context.tr('fieldRequired')
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FieldLabel(context.tr('relation')),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _relation,
                            isExpanded: true,
                            hint: Text(
                              context.tr('select'),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                              ),
                            ),
                            items: [
                              for (final r in _relations)
                                DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    context.tr('relf_$r'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => _relation = v),
                            validator: (v) => _emergencyStarted && v == null
                                ? context.tr('fieldRequired')
                                : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.mintBorder,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.accent,
                                  width: 1.8,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PhoneField(
                  label: context.tr('phoneNumberLabel'),
                  controller: _emPhoneCtrl,
                  country: _emCountry,
                  onCountryChanged: (c) => setState(() => _emCountry = c),
                  isRequired: () => _emergencyStarted,
                  requiredKey: 'fieldRequired',
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        ),
        // Plan section 4.6: consent to Terms & Privacy is mandatory.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: _agree,
                activeColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (v) => setState(() {
                  _agree = v ?? false;
                  _termsError = false;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  context.tr('termsAgree'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.dark,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_termsError)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                context.tr('termsRequired'),
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ======================= Date of birth wheels =======================

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

class _DobPicker extends StatefulWidget {
  const _DobPicker({
    required this.day,
    required this.month,
    required this.year,
    required this.minYear,
    required this.maxYear,
    required this.dayLabel,
    required this.monthLabel,
    required this.yearLabel,
    required this.monthName,
    required this.onChanged,
  });

  final int day;
  final int month;
  final int year;
  final int minYear;
  final int maxYear;
  final String dayLabel;
  final String monthLabel;
  final String yearLabel;
  final String Function(int month) monthName;
  final void Function(int day, int month, int year) onChanged;

  @override
  State<_DobPicker> createState() => _DobPickerState();
}

class _DobPickerState extends State<_DobPicker> {
  late final FixedExtentScrollController _d = FixedExtentScrollController(
    initialItem: widget.day - 1,
  );
  late final FixedExtentScrollController _m = FixedExtentScrollController(
    initialItem: widget.month - 1,
  );
  // Years run downward: index 0 = maxYear.
  late final FixedExtentScrollController _y = FixedExtentScrollController(
    initialItem: widget.maxYear - widget.year,
  );

  @override
  void didUpdateWidget(covariant _DobPicker old) {
    super.didUpdateWidget(old);
    // Month/year changed and the day no longer exists (e.g. 31 -> Feb):
    // the parent clamped the day, so move the day wheel to match.
    if (_d.hasClients && _d.selectedItem != widget.day - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_d.hasClients) _d.jumpToItem(widget.day - 1);
      });
    }
  }

  @override
  void dispose() {
    _d.dispose();
    _m.dispose();
    _y.dispose();
    super.dispose();
  }

  void _emit({int? day, int? month, int? year}) {
    final m = month ?? widget.month;
    final y = year ?? widget.year;
    var d = day ?? widget.day;
    final max = _daysInMonth(y, m);
    if (d > max) d = max;
    widget.onChanged(d, m, y);
  }

  Widget _col(String label, Widget wheel, int flex) => Expanded(
    flex: flex,
    child: Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        wheel,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(widget.year, widget.month);
    final yearCount = widget.maxYear - widget.minYear + 1;
    return Row(
      children: [
        _col(
          widget.dayLabel,
          _Wheel(
            controller: _d,
            count: days,
            selected: widget.day - 1,
            label: (i) => '${i + 1}',
            onChanged: (i) => _emit(day: i + 1),
          ),
          2,
        ),
        const SizedBox(width: 6),
        _col(
          widget.monthLabel,
          _Wheel(
            controller: _m,
            count: 12,
            selected: widget.month - 1,
            label: (i) => widget.monthName(i + 1),
            onChanged: (i) => _emit(month: i + 1),
          ),
          3,
        ),
        const SizedBox(width: 6),
        _col(
          widget.yearLabel,
          _Wheel(
            controller: _y,
            count: yearCount,
            selected: widget.maxYear - widget.year,
            label: (i) => '${widget.maxYear - i}',
            onChanged: (i) => _emit(year: widget.maxYear - i),
          ),
          2,
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.cardMint,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 34,
            diameterRatio: 2.4,
            overAndUnderCenterOpacity: 0.55,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (context, i) {
                final active = i == selected;
                return Center(
                  child: Text(
                    label(i),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: active ? 15 : 13,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? AppColors.dark : AppColors.muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}