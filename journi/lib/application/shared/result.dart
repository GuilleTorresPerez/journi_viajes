/// Resultado genérico con éxito (`Ok<T>`) o error (`Err<T>`),
/// para no depender de exceptions en el flujo normal.
///
/// Incluye un tipo `Unit` para operaciones sin valor (p. ej., delete),
/// así evitamos el problemático `Result<void>`.

// ===== Errores tipados =====
abstract class AppError {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  const AppError(this.message, {this.cause, this.stackTrace});
  @override
  String toString() => message;
}

class ValidationError extends AppError {
  const ValidationError(String message) : super(message);
}

class RepoError extends AppError {
  const RepoError(String message, {Object? cause, StackTrace? stackTrace})
    : super(message, cause: cause, stackTrace: stackTrace);
}

class UnexpectedError extends AppError {
  const UnexpectedError(String message, {Object? cause, StackTrace? stackTrace})
    : super(message, cause: cause, stackTrace: stackTrace);
}

// ===== Result<T> =====
abstract class Result<T> {
  const Result();
  bool get isOk;
  bool get isErr => !isOk;

  Ok<T> asOk() => this as Ok<T>;
  Err<T> asErr() => this as Err<T>;

  T? get valueOrNull => isOk ? asOk().value : null;
  List<AppError> get errorsOrEmpty => isOk ? const [] : asErr().errors;

  R fold<R>({
    required R Function(T value) onOk,
    required R Function(List<AppError> errors) onErr,
  });

  Result<U> map<U>(U Function(T value) transform) =>
      isOk ? Ok<U>(transform(asOk().value)) : Err<U>(asErr().errors);

  Result<U> flatMap<U>(Result<U> Function(T value) bind) =>
      isOk ? bind(asOk().value) : Err<U>(asErr().errors);

  T unwrapOr(T fallback) => isOk ? asOk().value : fallback;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
  @override
  bool get isOk => true;
  @override
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(List<AppError> errors) onErr,
  }) => onOk(value);
  @override
  String toString() => 'Ok($value)';
}

class Err<T> extends Result<T> {
  final List<AppError> errors;
  const Err(this.errors);
  @override
  bool get isOk => false;
  @override
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(List<AppError> errors) onErr,
  }) => onErr(errors);
  @override
  String toString() => 'Err(${errors.join(', ')})';
}

// ===== Unit para operaciones sin valor =====
class Unit {
  const Unit();
}

const unit = Unit();
