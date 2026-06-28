sealed class CategoryActionState {
  const CategoryActionState();
}

class CategoryActionIdle extends CategoryActionState {
  const CategoryActionIdle();
}

class CategoryActionLoading extends CategoryActionState {
  const CategoryActionLoading();
}

class CategoryActionSuccess extends CategoryActionState {
  final String message;
  const CategoryActionSuccess(this.message);
}

class CategoryActionError extends CategoryActionState {
  final String message;
  const CategoryActionError(this.message);
}
