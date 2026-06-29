import '../entities/approval_rule.dart';

class RuleResolution {
  /// Si true, el gasto se aprueba automáticamente.
  final bool autoApprove;

  /// La regla que se aplicó (null si ninguna coincidió).
  final ApprovalRule? appliedRule;

  const RuleResolution({required this.autoApprove, this.appliedRule});
}

/// Evalúa las reglas de aprobación de una empresa contra un gasto.
class ApprovalRuleEngine {
  const ApprovalRuleEngine();

  /// Resuelve qué hacer con un gasto según las reglas vigentes.
  /// Si no hay regla que coincida, el gasto va a revisión manual.
  RuleResolution resolve({
    required List<ApprovalRule> rules,
    required double amount,
    required String categoryId,
  }) {
    final matching =
        rules.where((r) => r.matches(amount, categoryId)).toList();
    if (matching.isEmpty) {
      return const RuleResolution(autoApprove: false);
    }

    // Preferir reglas específicas de categoría, luego las de mayor minAmount.
    matching.sort((a, b) {
      final aSpecific = a.categoryId != null ? 1 : 0;
      final bSpecific = b.categoryId != null ? 1 : 0;
      if (aSpecific != bSpecific) return bSpecific - aSpecific;
      return b.minAmount.compareTo(a.minAmount);
    });

    final rule = matching.first;
    return RuleResolution(
      autoApprove: rule.outcome.isAuto,
      appliedRule: rule,
    );
  }
}
