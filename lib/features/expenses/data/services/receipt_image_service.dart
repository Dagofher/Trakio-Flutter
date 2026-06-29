import 'package:image_picker/image_picker.dart';

/// Captura la foto del recibo desde cámara o galería.
class ReceiptImageService {
  final ImagePicker _picker;
  ReceiptImageService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  /// Devuelve la ruta local de la imagen, o null si el usuario cancela.
  Future<String?> pickFromCamera() => _pick(ImageSource.camera);

  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 70, // comprime para subir más liviano a Storage
      maxWidth: 1600,
    );
    return file?.path;
  }
}
