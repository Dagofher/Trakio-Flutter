/// Cómo se vincula el usuario a una empresa durante el registro.
sealed class CompanyRegistration {
  const CompanyRegistration();
}

/// Crea una empresa nueva; el usuario será su Admin.
class CreateCompany extends CompanyRegistration {
  final String name;
  const CreateCompany(this.name);
}

/// Se une a una empresa existente mediante su código de invitación.
class JoinByCode extends CompanyRegistration {
  final String inviteCode;
  const JoinByCode(this.inviteCode);
}
