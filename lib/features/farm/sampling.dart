import '../../l10n/app_localizations.dart';

/// Mirrors backend `app/services/sampling_service.py::required_points_for_area` exactly —
/// keep both in sync if the tiers ever change.
List<String> requiredPointsForArea(double sizeAcres) {
  if (sizeAcres < 0.5) return const ['center'];
  if (sizeAcres <= 2) return const ['corner_1', 'corner_2', 'center'];
  if (sizeAcres <= 5) return const ['corner_1', 'corner_2', 'corner_3', 'corner_4', 'center'];
  return const ['quadrant_1', 'quadrant_2', 'quadrant_3', 'quadrant_4', 'center'];
}

String pointDisplayLabel(AppLocalizations l10n, String pointLabel) {
  if (pointLabel == 'center') return l10n.centerPointLabel;

  final parts = pointLabel.split('_');
  final number = int.tryParse(parts.last) ?? 0;

  if (pointLabel.startsWith('corner_')) return l10n.cornerPointLabel(number);
  if (pointLabel.startsWith('quadrant_')) return l10n.quadrantPointLabel(number);
  return pointLabel;
}
