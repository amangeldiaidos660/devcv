class AppFailure implements Exception {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;
}

String failureMessage(Object error) => error is AppFailure
    ? error.message
    : 'Не удалось выполнить действие. Попробуйте ещё раз.';
