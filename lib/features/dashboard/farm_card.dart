import 'package:flutter/material.dart';

class FarmSummary {
  const FarmSummary({
    required this.name,
    required this.location,
    required this.sizeAcres,
    this.lastRecommendationDate,
  });

  final String name;
  final String location;
  final double sizeAcres;
  final DateTime? lastRecommendationDate;
}

class FarmCard extends StatelessWidget {
  const FarmCard({super.key, required this.farm});

  final FarmSummary farm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(farm.name),
        subtitle: Text(
          '${farm.location} · ${farm.sizeAcres} acres'
          '${farm.lastRecommendationDate != null ? ' · last recommendation ${farm.lastRecommendationDate}' : ''}',
        ),
      ),
    );
  }
}
