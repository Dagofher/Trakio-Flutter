import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/entities/user_entity.dart';

/// Acceso a Firestore para perfiles de usuario (users/) y empresas (companies/).
class UserProfileDatasource {
  final FirebaseFirestore _db;
  const UserProfileDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _companies =>
      _db.collection('companies');

  /// Busca una empresa por su código de invitación. Null si no existe.
  Future<CompanyEntity?> findCompanyByCode(String code) async {
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return null;
    final query = await _companies
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return _companyFromDoc(doc.id, doc.data());
  }

  /// Lee una empresa por su id. Null si no existe.
  Future<CompanyEntity?> getCompany(String companyId) async {
    final doc = await _companies.doc(companyId).get();
    if (!doc.exists) return null;
    return _companyFromDoc(doc.id, doc.data()!);
  }

  /// Crea una empresa con un código de invitación único y la devuelve.
  Future<CompanyEntity> createCompany({
    required String name,
    required String ownerId,
  }) async {
    final code = await _generateUniqueCode(name);
    final ref = _companies.doc();
    await ref.set({
      'name': name.trim(),
      'ownerId': ownerId,
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return CompanyEntity(
      id: ref.id,
      name: name.trim(),
      ownerId: ownerId,
      inviteCode: code,
    );
  }

  /// Persiste el perfil del usuario en users/{uid}.
  Future<void> createUserProfile(UserEntity user) async {
    await _users.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': user.role.name,
      'companyId': user.companyId,
      'departmentId': user.departmentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Lee el perfil del usuario. Null si aún no existe.
  Future<UserEntity?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return _userFromDoc(uid, doc.data()!);
  }

  // ── Helpers ───────────────────────────────────────────────

  String _normalizeCode(String code) => code.trim().toUpperCase();

  /// Genera un código tipo "ACME-7F3K" y verifica que no exista ya.
  Future<String> _generateUniqueCode(String name) async {
    for (var i = 0; i < 5; i++) {
      final code = _buildCode(name);
      final existing = await findCompanyByCode(code);
      if (existing == null) return code;
    }
    // Fallback extremadamente improbable: sufijo más largo.
    return _buildCode(name, suffixLength: 6);
  }

  String _buildCode(String name, {int suffixLength = 4}) {
    final letters = name.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix = letters.isEmpty
        ? 'TRK'
        : letters.substring(0, min(4, letters.length));
    // Alfabeto sin caracteres ambiguos (0/O, 1/I).
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final suffix = List.generate(
      suffixLength,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
    return '$prefix-$suffix';
  }

  CompanyEntity _companyFromDoc(String id, Map<String, dynamic> data) {
    return CompanyEntity(
      id: id,
      name: data['name'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
    );
  }

  UserEntity _userFromDoc(String uid, Map<String, dynamic> data) {
    return UserEntity(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      companyId: data['companyId'] as String?,
      departmentId: data['departmentId'] as String?,
    );
  }
}
