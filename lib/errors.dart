class AppError extends Error {
  final String message;

  AppError(this.message);
}

class AuthError extends AppError {
  AuthError(super.message);
}
