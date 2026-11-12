import 'package:material_ui/material_ui.dart';

import '../../features/ingredient_checker/models/analysis_result.dart';

/// How each backend status is shown: wording, colour and icon. Colour is
/// never the only signal; every status also has its own icon and label.
extension AnalysisStatusStyle on AnalysisStatus {
  String get label => switch (this) {
    AnalysisStatus.halalIndicated => 'Halal indicated',
    AnalysisStatus.haramIndicator => 'Haram indicator',
    AnalysisStatus.needsVerification => 'Needs verification',
    AnalysisStatus.insufficientInformation => 'Insufficient information',
  };

  String get meaning => switch (this) {
    AnalysisStatus.halalIndicated =>
      'No known problematic ingredients were found. A preliminary '
          'assessment, not a certificate.',
    AnalysisStatus.haramIndicator =>
      'A clearly identified prohibited ingredient or origin was found.',
    AnalysisStatus.needsVerification =>
      'Mashbooh: some ingredients have an uncertain origin and need checking.',
    AnalysisStatus.insufficientInformation =>
      'Ingredients are missing, incomplete or could not be identified.',
  };

  Color get color => switch (this) {
    AnalysisStatus.halalIndicated => const Color(0xFF2E7D32),
    AnalysisStatus.haramIndicator => const Color(0xFFC62828),
    AnalysisStatus.needsVerification => const Color(0xFFB45309),
    AnalysisStatus.insufficientInformation => const Color(0xFF546E7A),
  };

  IconData get icon => switch (this) {
    AnalysisStatus.halalIndicated => Icons.check_circle_rounded,
    AnalysisStatus.haramIndicator => Icons.cancel_rounded,
    AnalysisStatus.needsVerification => Icons.help_rounded,
    AnalysisStatus.insufficientInformation => Icons.info_rounded,
  };
}

extension FindingStatusStyle on FindingStatus {
  String get label => switch (this) {
    FindingStatus.permissible => 'No known concern',
    FindingStatus.prohibited => 'Prohibited',
    FindingStatus.needsVerification => 'Needs verification',
    FindingStatus.unknown => 'Not in database',
  };

  Color get color => switch (this) {
    FindingStatus.permissible => const Color(0xFF2E7D32),
    FindingStatus.prohibited => const Color(0xFFC62828),
    FindingStatus.needsVerification => const Color(0xFFB45309),
    FindingStatus.unknown => const Color(0xFF546E7A),
  };

  IconData get icon => switch (this) {
    FindingStatus.permissible => Icons.check_circle_rounded,
    FindingStatus.prohibited => Icons.cancel_rounded,
    FindingStatus.needsVerification => Icons.help_rounded,
    FindingStatus.unknown => Icons.info_rounded,
  };
}

extension CertificationStatusStyle on CertificationStatus {
  String get label => switch (this) {
    CertificationStatus.verified => 'Verified',
    CertificationStatus.notFound => 'Not found',
    CertificationStatus.unknown => 'Unknown',
    CertificationStatus.expired => 'Expired',
  };

  Color get color => switch (this) {
    CertificationStatus.verified => const Color(0xFF2E7D32),
    CertificationStatus.expired => const Color(0xFFB45309),
    CertificationStatus.notFound ||
    CertificationStatus.unknown => const Color(0xFF546E7A),
  };

  IconData get icon => switch (this) {
    CertificationStatus.verified => Icons.verified_rounded,
    CertificationStatus.expired => Icons.event_busy_rounded,
    CertificationStatus.notFound => Icons.search_off_rounded,
    CertificationStatus.unknown => Icons.help_outline_rounded,
  };
}
