import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'farm_provider.dart';
import 'sampling.dart';

Future<void> showSoilPointModal(
  BuildContext context, {
  required String pointLabel,
  SoilPoint? existingPoint,
}) {
  // showModalBottomSheet inserts into the Navigator's Overlay, which sits outside the
  // FarmDetailProvider scope (that provider only wraps FarmScreen's own subtree) — so the
  // instance must be captured here and re-provided inside the modal's builder.
  final farmDetailProvider = context.read<FarmDetailProvider>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: farmDetailProvider,
      child: SoilPointModal(pointLabel: pointLabel, existingPoint: existingPoint),
    ),
  );
}

class SoilPointModal extends StatefulWidget {
  const SoilPointModal({super.key, required this.pointLabel, this.existingPoint});

  final String pointLabel;
  final SoilPoint? existingPoint;

  @override
  State<SoilPointModal> createState() => _SoilPointModalState();
}

class _SoilPointModalState extends State<SoilPointModal> {
  final _formKey = GlobalKey<FormState>();
  late final _nController = TextEditingController(text: widget.existingPoint?.n.toString() ?? '');
  late final _pController = TextEditingController(text: widget.existingPoint?.p.toString() ?? '');
  late final _kController = TextEditingController(text: widget.existingPoint?.k.toString() ?? '');
  late final _phController = TextEditingController(text: widget.existingPoint?.ph.toString() ?? '');

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _phController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await context.read<FarmDetailProvider>().savePoint(
          pointLabel: widget.pointLabel,
          n: double.parse(_nController.text),
          p: double.parse(_pController.text),
          k: double.parse(_kController.text),
          ph: double.parse(_phController.text),
        );

    if (!mounted) return;

    if (error != null) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error == 'savePointError' ? l10n.savePointError : error;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  String? _nonNegativeValidator(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.requiredValidation;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) return l10n.positiveNumberValidation;
    return null;
  }

  String? _phValidator(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.requiredValidation;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > 14) return l10n.positiveNumberValidation;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                          '${widget.existingPoint != null ? l10n.editPointTitle : l10n.addPointTitle}'
                          ' · ${pointDisplayLabel(l10n, widget.pointLabel)}',
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
                  TextFormField(
                    controller: _nController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.nitrogenLabel),
                    validator: (value) => _nonNegativeValidator(l10n, value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.phosphorusLabel),
                    validator: (value) => _nonNegativeValidator(l10n, value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _kController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.potassiumLabel),
                    validator: (value) => _nonNegativeValidator(l10n, value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.phLabel),
                    validator: (value) => _phValidator(l10n, value),
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
                        : Text(l10n.savePointButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
