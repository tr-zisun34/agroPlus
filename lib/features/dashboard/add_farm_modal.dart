import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'farm_provider.dart';

const _soilTypes = ['Clay', 'Loamy', 'Sandy', 'Silty'];
const _waterAvailabilityOptions = ['Irrigated', 'Rain-fed', 'Limited'];
const _targetSeasons = ['Rabi', 'Aus', 'Aman'];

Future<void> showAddFarmModal(BuildContext context, {Farm? existingFarm}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => AddFarmModal(existingFarm: existingFarm),
  );
}

class AddFarmModal extends StatefulWidget {
  const AddFarmModal({super.key, this.existingFarm});

  final Farm? existingFarm;

  @override
  State<AddFarmModal> createState() => _AddFarmModalState();
}

class _AddFarmModalState extends State<AddFarmModal> {
  final _formKey = GlobalKey<FormState>();
  late final _farmNameController = TextEditingController(text: widget.existingFarm?.farmName ?? '');
  late final _locationController = TextEditingController(text: widget.existingFarm?.location ?? '');
  late final _areaController = TextEditingController(text: widget.existingFarm?.sizeAcres.toString() ?? '');
  late final _budgetController = TextEditingController(text: widget.existingFarm?.budget.toString() ?? '');

  District? _selectedDistrict;
  String? _selectedSoilType;
  String? _selectedWaterAvailability;
  String? _selectedTargetSeason;

  bool _isLoadingDistricts = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditMode => widget.existingFarm != null;

  @override
  void initState() {
    super.initState();
    _selectedSoilType = widget.existingFarm?.soilType;
    _selectedWaterAvailability = widget.existingFarm?.waterAvailability;
    _selectedTargetSeason = widget.existingFarm?.targetSeason;
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    await context.read<FarmProvider>().loadDistricts();
    if (!mounted) return;
    setState(() {
      _isLoadingDistricts = false;
      final existingFarm = widget.existingFarm;
      if (existingFarm != null) {
        final districts = context.read<FarmProvider>().districts;
        _selectedDistrict = districts.firstWhere(
          (d) => d.id == existingFarm.district.id,
          orElse: () => existingFarm.district,
        );
      }
    });
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final farmProvider = context.read<FarmProvider>();
    final error = _isEditMode
        ? await farmProvider.updateFarm(
            farmId: widget.existingFarm!.id,
            farmName: _farmNameController.text.trim(),
            location: _locationController.text.trim(),
            districtId: _selectedDistrict!.id,
            sizeAcres: double.parse(_areaController.text),
            soilType: _selectedSoilType!,
            waterAvailability: _selectedWaterAvailability!,
            budget: double.parse(_budgetController.text),
            targetSeason: _selectedTargetSeason!,
          )
        : await farmProvider.addFarm(
            farmName: _farmNameController.text.trim(),
            location: _locationController.text.trim(),
            districtId: _selectedDistrict!.id,
            sizeAcres: double.parse(_areaController.text),
            soilType: _selectedSoilType!,
            waterAvailability: _selectedWaterAvailability!,
            budget: double.parse(_budgetController.text),
            targetSeason: _selectedTargetSeason!,
          );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  String? _requiredValidator(AppLocalizations l10n, String? value) =>
      (value == null || value.trim().isEmpty) ? l10n.requiredValidation : null;

  String? _positiveNumberValidator(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.requiredValidation;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return l10n.positiveNumberValidation;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final districts = context.watch<FarmProvider>().districts;
    final l10n = AppLocalizations.of(context)!;
    final title = _isEditMode ? l10n.editFarm : l10n.addFarm;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: l10n.closeTooltip,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingDistricts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    TextFormField(
                      controller: _farmNameController,
                      decoration: InputDecoration(labelText: l10n.farmNameLabel),
                      validator: (value) => _requiredValidator(l10n, value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: l10n.locationLabel,
                        hintText: l10n.locationHint,
                      ),
                      validator: (value) => _requiredValidator(l10n, value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<District>(
                      initialValue: _selectedDistrict,
                      decoration: InputDecoration(labelText: l10n.districtLabel),
                      items: districts
                          .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedDistrict = value),
                      validator: (value) => value == null ? l10n.requiredValidation : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.areaLabel, hintText: l10n.areaHint),
                      validator: (value) => _positiveNumberValidator(l10n, value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSoilType,
                      decoration: InputDecoration(labelText: l10n.soilTypeLabel),
                      items: _soilTypes
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSoilType = value),
                      validator: (value) => value == null ? l10n.requiredValidation : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWaterAvailability,
                      decoration: InputDecoration(labelText: l10n.waterAvailabilityLabel),
                      items: _waterAvailabilityOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedWaterAvailability = value),
                      validator: (value) => value == null ? l10n.requiredValidation : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.budgetLabel, hintText: l10n.budgetHint),
                      validator: (value) => _positiveNumberValidator(l10n, value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTargetSeason,
                      decoration: InputDecoration(labelText: l10n.targetSeasonLabel),
                      items: _targetSeasons
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedTargetSeason = value),
                      validator: (value) => value == null ? l10n.requiredValidation : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(title),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
