import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado del escaneo OCR de un recibo.
class OcrResult {
  /// Texto completo reconocido.
  final String rawText;

  /// Monto detectado (mejor estimación), o null si no se encontró.
  final double? amount;

  /// Primera línea no vacía (posible nombre del comercio).
  final String? merchant;

  const OcrResult({required this.rawText, this.amount, this.merchant});
}

/// Escanea un recibo/factura con reconocimiento de texto on-device (ML Kit)
/// e intenta extraer el monto total.
class ReceiptOcrService {
  final TextRecognizer _recognizer;

  ReceiptOcrService([TextRecognizer? recognizer])
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> scan(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    final text = recognized.text;
    return OcrResult(
      rawText: text,
      amount: _extractAmount(text),
      merchant: _extractMerchant(text),
    );
  }

  void dispose() => _recognizer.close();

  // ── Heurística de extracción de monto ─────────────────────

  // Captura números tipo 1.234,56 / 1,234.56 / 1234.56 / 1234,56
  static final RegExp _moneyRegex = RegExp(
    r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})|\d+[.,]\d{2})',
  );

  static final RegExp _totalLine = RegExp(
    r'(total|importe|monto|amount|a\s*pagar)',
    caseSensitive: false,
  );

  double? _extractAmount(String text) {
    if (text.trim().isEmpty) return null;
    final lines = text.split('\n');

    // 1) Preferir líneas que mencionen "total"/"importe"/etc.
    double? best;
    for (final line in lines) {
      if (_totalLine.hasMatch(line)) {
        final value = _largestInLine(line);
        if (value != null && (best == null || value > best)) best = value;
      }
    }
    if (best != null) return best;

    // 2) Fallback: el mayor valor monetario de todo el texto.
    double? max;
    for (final match in _moneyRegex.allMatches(text)) {
      final value = _parse(match.group(0)!);
      if (value != null && (max == null || value > max)) max = value;
    }
    return max;
  }

  double? _largestInLine(String line) {
    double? max;
    for (final match in _moneyRegex.allMatches(line)) {
      final value = _parse(match.group(0)!);
      if (value != null && (max == null || value > max)) max = value;
    }
    return max;
  }

  /// Normaliza un texto numérico con separadores variados a double.
  double? _parse(String raw) {
    var s = raw.trim();
    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');

    if (lastDot != -1 && lastComma != -1) {
      // El separador decimal es el que aparece más a la derecha.
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (lastComma != -1) {
      // Solo comas: tratar la última como decimal.
      s = s.replaceAll(',', '.');
      final parts = s.split('.');
      if (parts.length > 2) {
        final dec = parts.removeLast();
        s = '${parts.join('')}.$dec';
      }
    }
    return double.tryParse(s);
  }

  String? _extractMerchant(String text) {
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.length >= 3 && !RegExp(r'^\d+$').hasMatch(trimmed)) {
        return trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
      }
    }
    return null;
  }
}
