class NotEnoughTokensException implements Exception {
  final String message;

  NotEnoughTokensException(this.message);
}
