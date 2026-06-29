/// Estado genérico para acciones CRUD (crear/editar/eliminar) reutilizable
/// por las distintas features.
sealed class CrudActionState {
  const CrudActionState();
}

class CrudIdle extends CrudActionState {
  const CrudIdle();
}

class CrudLoading extends CrudActionState {
  const CrudLoading();
}

class CrudSuccess extends CrudActionState {
  final String message;
  const CrudSuccess(this.message);
}

class CrudError extends CrudActionState {
  final String message;
  const CrudError(this.message);
}
