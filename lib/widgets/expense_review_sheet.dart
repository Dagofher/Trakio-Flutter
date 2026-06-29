import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../desings/colors.dart';
import '../features/expenses/domain/entities/expense_entity.dart';

/// Hoja para revisar un gasto: muestra el detalle y permite aprobar/rechazar
/// con un comentario opcional.
Future<void> showExpenseReviewSheet(
  BuildContext context, {
  required ExpenseEntity expense,
  required void Function(String? comment) onApprove,
  required void Function(String? comment) onReject,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReviewSheet(
      expense: expense,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

class _ReviewSheet extends StatefulWidget {
  final ExpenseEntity expense;
  final void Function(String? comment) onApprove;
  final void Function(String? comment) onReject;

  const _ReviewSheet({
    required this.expense,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String? get _comment =>
      _commentController.text.trim().isEmpty ? null : _commentController.text.trim();

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Text(
                      '\$${e.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.description.isEmpty ? 'Sin descripción' : e.description,
                      style: TextStyle(
                        color: AppColors.textColor.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (e.photoUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          e.photoUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (e.hasLocation) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 150,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(e.latitude!, e.longitude!),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.trakio',
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(e.latitude!, e.longitude!),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(Icons.location_on,
                                      color: AppColors.errorColor, size: 36),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text('Comentario (opcional)',
                        style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Motivo de la decisión...',
                        hintStyle: TextStyle(
                            color: AppColors.textColor.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: AppColors.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.accentColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Actions(
                onApprove: () {
                  Navigator.pop(context);
                  widget.onApprove(_comment);
                },
                onReject: () {
                  Navigator.pop(context);
                  widget.onReject(_comment);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _Actions({required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Rechazar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                  side: BorderSide(
                      color: AppColors.errorColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white),
                label: const Text('Aprobar',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
