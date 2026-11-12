import 'package:equatable/equatable.dart';

import 'analysis_result.dart';

/// One entry of the backend's ingredient knowledge database.
class IngredientInfo extends Equatable {
  const IngredientInfo({
    required this.code,
    required this.name,
    required this.classification,
    required this.description,
    required this.possibleOrigin,
    required this.halalAssessment,
    required this.reason,
    required this.verificationAdvice,
    this.eNumber,
    this.aliases = const [],
    this.source,
  });

  factory IngredientInfo.fromJson(Map<String, dynamic> json) => IngredientInfo(
    code: json['code'] as String,
    name: json['name'] as String? ?? '',
    eNumber: json['e_number'] as String?,
    aliases: (json['aliases'] as List? ?? []).cast<String>(),
    classification: FindingStatus.fromApi(json['classification'] as String?),
    description: json['description'] as String? ?? '',
    possibleOrigin: json['possible_origin'] as String? ?? '',
    halalAssessment: json['halal_assessment'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    verificationAdvice: json['verification_advice'] as String? ?? '',
    source: json['source'] as String?,
  );

  final String code;
  final String name;
  final String? eNumber;
  final List<String> aliases;
  final FindingStatus classification;
  final String description;
  final String possibleOrigin;
  final String halalAssessment;
  final String reason;
  final String verificationAdvice;
  final String? source;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        (eNumber?.toLowerCase().contains(q) ?? false) ||
        aliases.any((alias) => alias.contains(q));
  }

  @override
  List<Object?> get props => [
    code,
    name,
    eNumber,
    aliases,
    classification,
    description,
    possibleOrigin,
    halalAssessment,
    reason,
    verificationAdvice,
    source,
  ];
}
