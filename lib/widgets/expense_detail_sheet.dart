import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../desings/colors.dart';
import '../features/expenses/domain/entities/expense_entity.dart';
import 'expense_tile.dart';

/// Muestra el detalle de un gasto (foto, datos, ubicación) en un bottom sheet.
Future<void> showExpenseDetailSheet(
  BuildContext context, {
  required ExpenseEntity expense,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExpenseDetailSheet(expense: expense, onDelete: onDelete),
  );
}

class _ExpenseDetailSheet extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback? onDelete;

  const _ExpenseDetailSheet({required this.expense, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ExpenseStatusChip(status: expense.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              expense.description.isEmpty
                  ? 'Sin descripción'
                  : expense.description,
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registrado el ${_fmtDateTime(expense.createdAt)}',
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.6),
                fontSize: 12.5,
              ),
            ),
            if (expense.reviewComment != null &&
                expense.reviewComment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CommentBox(comment: expense.reviewComment!),
            ],
            const SizedBox(height: 20),
            if (expense.photoUrl != null) ...[
              const _SectionLabel('Recibo'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  expense.photoUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.accentColor),
                              ),
                            ),
                  errorBuilder: (context, error, stack) => const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text('No se pudo cargar la imagen',
                          style: TextStyle(color: AppColors.textColor)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (expense.hasLocation) ...[
              const _SectionLabel('Ubicación'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          LatLng(expense.latitude!, expense.longitude!),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.trakio',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                                expense.latitude!, expense.longitude!),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on,
                                color: AppColors.errorColor, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lat ${expense.latitude!.toStringAsFixed(5)}, '
                'Lng ${expense.longitude!.toStringAsFixed(5)}',
                style: TextStyle(
                  color: AppColors.textColor.withValues(alpha: 0.8),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (onDelete != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete!();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Eliminar gasto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                  side: BorderSide(
                      color: AppColors.errorColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CommentBox extends StatelessWidget {
  final String comment;
  const _CommentBox({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.comment_outlined,
              size: 18, color: AppColors.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              comment,
              style: const TextStyle(
                  color: AppColors.textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDateTime(DateTime d) {
  final date =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final time =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '$date a las $time';
}
