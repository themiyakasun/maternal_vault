import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/cards/section_card.dart';
import '../../../../core/widgets/cards/stat_tile.dart';
import '../../../../core/widgets/cards/sub_card.dart';
import '../../../../core/widgets/inputs/app_date_field.dart';
import '../../../../core/widgets/inputs/app_dropdown_field.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/page_intro.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/basic_profile.dart';
import '../../domain/education_level.dart';
import '../../domain/key_vitals.dart';

/// The mother's first tab: the four figures her record already holds, then the
/// registration and household details the clinic collects at the first visit.
///
/// The vitals above the form are read-only. They come from measurements taken at
/// a clinic rather than from anything typed here, so the screen displays them and
/// never invents them — an unmeasured value shows as an em-dash.
///
/// Nothing is stored yet: [onSubmit] is the seam the record layer drops into.
/// Validation is real regardless, so the form is finished even though its
/// destination is not.
class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({
    super.key,
    this.vitals = const KeyVitals.empty(),
    this.onSubmit,
  });

  /// What the summary tiles render. Defaults to a record with nothing measured.
  final KeyVitals vitals;

  /// Handed a validated [BasicProfile] when Save is tapped. Null shows a notice
  /// saying storage is not connected rather than pretending to have saved.
  final ValueChanged<BasicProfile>? onSubmit;

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  /// Youngest and oldest age the form will accept. Wide on purpose — a form that
  /// argues with a real answer is worse than one that takes an odd one.
  static const int _minAge = 12;
  static const int _maxAge = 70;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _registrationNumber = TextEditingController();
  final TextEditingController _motherName = TextEditingController();
  final TextEditingController _nationalId = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _motherAge = TextEditingController();
  final TextEditingController _motherOccupation = TextEditingController();
  final TextEditingController _fatherAge = TextEditingController();
  final TextEditingController _fatherOccupation = TextEditingController();

  DateTime? _registrationDate;
  EducationLevel? _motherEducation;
  EducationLevel? _fatherEducation;

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _registrationNumber,
      _motherName,
      _nationalId,
      _address,
      _phone,
      _motherAge,
      _motherOccupation,
      _fatherAge,
      _fatherOccupation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.stackSm,
          AppSpacing.screenPadding,
          AppSpacing.sectionGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageIntro(
              title: l10n.profileTitle,
              body: l10n.profileBody,
              align: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(l10n.vitalsEyebrow, style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.stackMd),
            _vitalsGrid(l10n),
            const SizedBox(height: AppSpacing.sectionGap),
            _demographics(l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _personalInformation(l10n),
            const SizedBox(height: AppSpacing.sectionGap),
            Align(
              alignment: Alignment.centerRight,
              child: AppPrimaryButton(
                label: l10n.actionSaveProfile,
                onPressed: _save,
                icon: Icons.check_rounded,
                expand: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The four tiles, two by two.
  ///
  /// A pair of columns rather than a [GridView]: four fixed tiles do not need a
  /// scrollable, and nesting one inside the page's own would mean shrink-wrapping
  /// it to stop the two fighting over the gesture.
  Widget _vitalsGrid(AppLocalizations l10n) {
    final List<Widget> tiles = <Widget>[
      StatTile(
        icon: Icons.water_drop_outlined,
        label: l10n.vitalBloodGroup,
        value: widget.vitals.bloodGroup,
        accent: AppColors.primary,
      ),
      StatTile(
        icon: Icons.monitor_weight_outlined,
        label: l10n.vitalBmi,
        value: widget.vitals.bmi,
        accent: AppColors.secondary,
      ),
      StatTile(
        icon: Icons.straighten_rounded,
        label: l10n.vitalHeight,
        value: widget.vitals.heightCm,
        unit: l10n.unitCentimetres,
        accent: AppColors.tertiary,
      ),
      StatTile(
        icon: Icons.healing_outlined,
        label: l10n.vitalAllergies,
        value: widget.vitals.allergies,
        accent: AppColors.error,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          // Stretch, or each tile shrinks to the width of its own longest line
          // and the two columns end up ragged instead of a grid.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              tiles[0],
              const SizedBox(height: AppSpacing.componentGap),
              tiles[2],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.componentGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              tiles[1],
              const SizedBox(height: AppSpacing.componentGap),
              tiles[3],
            ],
          ),
        ),
      ],
    );
  }

  Widget _demographics(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.badge_outlined,
      title: l10n.sectionDemographics,
      accent: AppColors.primary,
      children: <Widget>[
        AppTextField(
          label: l10n.fieldMotherName,
          hint: l10n.fieldMotherNameHint,
          controller: _motherName,
          textCapitalization: TextCapitalization.words,
          validator: (String? value) => _required(l10n, value),
        ),
        AppTextField(
          label: l10n.fieldAddress,
          hint: l10n.fieldAddressHint,
          controller: _address,
          textCapitalization: TextCapitalization.words,
        ),
        AppTextField(
          label: l10n.fieldRegistrationNumber,
          hint: l10n.fieldRegistrationNumberHint,
          controller: _registrationNumber,
          textCapitalization: TextCapitalization.characters,
        ),
        AppDateField(
          label: l10n.fieldRegistrationDate,
          hint: l10n.fieldRegistrationDateHint,
          value: _registrationDate,
          onChanged: (DateTime? next) =>
              setState(() => _registrationDate = next),
        ),

        AppTextField(
          label: l10n.fieldNationalId,
          hint: l10n.fieldNationalIdHint,
          controller: _nationalId,
          textCapitalization: TextCapitalization.characters,
        ),

        AppTextField(
          label: l10n.fieldPhone,
          hint: l10n.fieldPhoneHint,
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _personalInformation(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.people_outline_rounded,
      title: l10n.sectionPersonalInfo,
      accent: AppColors.secondary,
      children: <Widget>[
        SubCard(
          title: l10n.parentMother,
          accent: AppColors.primary,
          children: _parentFields(
            l10n,
            age: _motherAge,
            occupation: _motherOccupation,
            education: _motherEducation,
            onEducationChanged: (EducationLevel? next) =>
                setState(() => _motherEducation = next),
          ),
        ),
        SubCard(
          title: l10n.parentFather,
          accent: AppColors.tertiary,
          children: _parentFields(
            l10n,
            age: _fatherAge,
            occupation: _fatherOccupation,
            education: _fatherEducation,
            onEducationChanged: (EducationLevel? next) =>
                setState(() => _fatherEducation = next),
          ),
        ),
      ],
    );
  }

  /// The same three questions for either parent, so the two blocks cannot drift.
  List<Widget> _parentFields(
    AppLocalizations l10n, {
    required TextEditingController age,
    required TextEditingController occupation,
    required EducationLevel? education,
    required ValueChanged<EducationLevel?> onEducationChanged,
  }) {
    return <Widget>[
      AppTextField(
        label: l10n.fieldAge,
        hint: l10n.fieldAgeHint,
        controller: age,
        keyboardType: TextInputType.number,
        // Two digits is every accepted answer, and refusing the rest at the
        // keyboard beats explaining it in an error.
        maxLength: 2,
        validator: (String? value) => _age(l10n, value),
      ),
      AppDropdownField<EducationLevel>(
        label: l10n.fieldEducation,
        hint: l10n.fieldEducationHint,
        value: education,
        onChanged: onEducationChanged,
        items: <AppDropdownItem<EducationLevel>>[
          for (final EducationLevel level in EducationLevel.values)
            AppDropdownItem<EducationLevel>(
              value: level,
              label: _educationLabel(l10n, level),
            ),
        ],
      ),
      AppTextField(
        label: l10n.fieldOccupation,
        hint: l10n.fieldOccupationHint,
        controller: occupation,
        textCapitalization: TextCapitalization.words,
      ),
    ];
  }

  String? _required(AppLocalizations l10n, String? value) {
    return (value?.trim().isEmpty ?? true) ? l10n.validationRequired : null;
  }

  /// Ages are optional, but an age that is present has to be a plausible number.
  String? _age(AppLocalizations l10n, String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final int? age = int.tryParse(text);
    if (age == null || age < _minAge || age > _maxAge) {
      return l10n.validationAgeRange(_minAge, _maxAge);
    }
    return null;
  }

  void _save() {
    // Dismissing the keyboard first stops the error text appearing behind it on
    // a field near the bottom of the form.
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final BasicProfile profile = BasicProfile(
      motherName: _motherName.text.trim(),
      registrationNumber: _trimmedOrNull(_registrationNumber),
      registrationDate: _registrationDate,
      nationalId: _trimmedOrNull(_nationalId),
      address: _trimmedOrNull(_address),
      phoneNumber: _trimmedOrNull(_phone),
      mother: ParentDetails(
        age: int.tryParse(_motherAge.text.trim()),
        education: _motherEducation,
        occupation: _trimmedOrNull(_motherOccupation),
      ),
      father: ParentDetails(
        age: int.tryParse(_fatherAge.text.trim()),
        education: _fatherEducation,
        occupation: _trimmedOrNull(_fatherOccupation),
      ),
    );

    final ValueChanged<BasicProfile>? onSubmit = widget.onSubmit;
    if (onSubmit != null) {
      onSubmit(profile);
      return;
    }

    // TODO: remove once a caller supplies onSubmit and owns the confirmation.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).profileSaveNotConnected),
      ),
    );
  }

  /// Empty text means "not answered", which the record stores as null rather
  /// than as a blank string.
  String? _trimmedOrNull(TextEditingController controller) {
    final String text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String _educationLabel(AppLocalizations l10n, EducationLevel level) {
    switch (level) {
      case EducationLevel.none:
        return l10n.educationNone;
      case EducationLevel.primary:
        return l10n.educationPrimary;
      case EducationLevel.secondary:
        return l10n.educationSecondary;
      case EducationLevel.oLevel:
        return l10n.educationOLevel;
      case EducationLevel.aLevel:
        return l10n.educationALevel;
      case EducationLevel.tertiary:
        return l10n.educationTertiary;
    }
  }
}
