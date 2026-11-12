import 'package:equatable/equatable.dart';

/// The four overall results the backend can return.
enum AnalysisStatus {
  halalIndicated('HALAL_INDICATED'),
  haramIndicator('HARAM_INDICATOR'),
  needsVerification('NEEDS_VERIFICATION'),
  insufficientInformation('INSUFFICIENT_INFORMATION');

  const AnalysisStatus(this.apiValue);

  final String apiValue;

  static AnalysisStatus fromApi(String? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => AnalysisStatus.insufficientInformation,
  );
}

/// How a single ingredient was assessed.
enum FindingStatus {
  permissible('permissible'),
  prohibited('prohibited'),
  needsVerification('needs_verification'),
  unknown('unknown');

  const FindingStatus(this.apiValue);

  final String apiValue;

  static FindingStatus fromApi(String? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => FindingStatus.unknown,
  );
}

enum CertificationStatus {
  verified('VERIFIED'),
  notFound('NOT_FOUND'),
  unknown('UNKNOWN'),
  expired('EXPIRED');

  const CertificationStatus(this.apiValue);

  final String apiValue;

  static CertificationStatus fromApi(String? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => CertificationStatus.unknown,
  );
}

class IngredientFinding extends Equatable {
  const IngredientFinding({
    required this.text,
    required this.status,
    required this.explanation,
    this.matchedName,
    this.eNumber,
    this.code,
    this.verificationAdvice,
  });

  factory IngredientFinding.fromJson(Map<String, dynamic> json) =>
      IngredientFinding(
        text: json['text'] as String? ?? '',
        status: FindingStatus.fromApi(json['status'] as String?),
        explanation: json['explanation'] as String? ?? '',
        matchedName: json['matched_name'] as String?,
        eNumber: json['e_number'] as String?,
        code: json['code'] as String?,
        verificationAdvice: json['verification_advice'] as String?,
      );

  final String text;
  final FindingStatus status;
  final String explanation;
  final String? matchedName;
  final String? eNumber;

  /// Key of the knowledge-database entry, when the ingredient was recognised.
  final String? code;
  final String? verificationAdvice;

  @override
  List<Object?> get props => [
    text,
    status,
    explanation,
    matchedName,
    eNumber,
    code,
    verificationAdvice,
  ];
}

/// Certification is reported separately from the ingredient assessment.
class CertificationInfo extends Equatable {
  const CertificationInfo({
    required this.status,
    required this.message,
    required this.notice,
  });

  factory CertificationInfo.fromJson(Map<String, dynamic> json) =>
      CertificationInfo(
        status: CertificationStatus.fromApi(json['status'] as String?),
        message: json['message'] as String? ?? '',
        notice: json['notice'] as String? ?? '',
      );

  final CertificationStatus status;
  final String message;
  final String notice;

  @override
  List<Object?> get props => [status, message, notice];
}

/// A product check exactly as the backend produced it.
class AnalysisResult extends Equatable {
  const AnalysisResult({
    required this.productName,
    required this.source,
    required this.ingredientsText,
    required this.status,
    required this.summary,
    required this.recommendation,
    required this.ingredients,
    required this.certification,
    required this.disclaimer,
    this.id,
    this.barcode,
    this.brand,
    this.imageUrl,
    this.checkedAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    id: json['id'] as int?,
    productName: json['product_name'] as String? ?? 'Unnamed product',
    barcode: json['barcode'] as String?,
    brand: json['brand'] as String?,
    imageUrl: json['image_url'] as String?,
    source: json['source'] as String? ?? 'manual',
    ingredientsText: json['ingredients_text'] as String? ?? '',
    status: AnalysisStatus.fromApi(json['overall_status'] as String?),
    summary: json['summary'] as String? ?? '',
    recommendation: json['recommendation'] as String? ?? '',
    ingredients: (json['ingredients'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(IngredientFinding.fromJson)
        .toList(),
    certification: CertificationInfo.fromJson(
      json['certification'] as Map<String, dynamic>? ?? const {},
    ),
    disclaimer: json['disclaimer'] as String? ?? '',
    checkedAt: DateTime.tryParse(json['checked_at'] as String? ?? '')
        ?.toLocal(),
  );

  final int? id;
  final String productName;
  final String? barcode;
  final String? brand;
  final String? imageUrl;

  /// "manual" or "barcode".
  final String source;
  final String ingredientsText;
  final AnalysisStatus status;
  final String summary;
  final String recommendation;
  final List<IngredientFinding> ingredients;
  final CertificationInfo certification;
  final String disclaimer;
  final DateTime? checkedAt;

  @override
  List<Object?> get props => [
    id,
    productName,
    barcode,
    brand,
    imageUrl,
    source,
    ingredientsText,
    status,
    summary,
    recommendation,
    ingredients,
    certification,
    disclaimer,
    checkedAt,
  ];
}
